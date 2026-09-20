import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import type { SettlementFile } from "@/features/settlements/types/settlement.types";
import type { SettlementFilesRow } from "@/types/database.types";

/** Имя bucket в Supabase Storage для файлов счетов. */
export const SETTLEMENT_FILES_BUCKET = "settlement_files";

/** Допустимые расширения вложений к счёту. */
export const SETTLEMENT_FILE_ACCEPT =
  ".pdf,.doc,.docx,.xls,.xlsx,.jpg,.jpeg,.png";

/** Разрешённые расширения (без точки). */
const ALLOWED_EXTENSIONS = [
  "pdf",
  "doc",
  "docx",
  "xls",
  "xlsx",
  "jpg",
  "jpeg",
  "png",
];

/** Максимальный размер вложения — 20 МБ. */
export const SETTLEMENT_FILE_MAX_BYTES = 20 * 1024 * 1024;

/** Расширение имени файла в нижнем регистре, без точки. */
function fileExtension(fileName: string): string {
  return fileName.split(".").pop()?.toLowerCase() ?? "";
}

/** Проверяет размер и расширение файла перед загрузкой. */
function assertSettlementFileAllowed(file: File): void {
  if (file.size <= 0) {
    throw new Error("Файл пустой");
  }
  if (file.size > SETTLEMENT_FILE_MAX_BYTES) {
    throw new Error("Файл больше 20 МБ. Прикрепите файл меньшего размера");
  }
  if (!ALLOWED_EXTENSIONS.includes(fileExtension(file.name))) {
    throw new Error(
      "Недопустимый формат файла. Можно прикрепить PDF, Word, Excel или изображение"
    );
  }
}

/** Колонки вложения, которые читает и возвращает веб. */
const FILES_SELECT =
  "id, company_id, settlement_operation_id, name, file_path, size, type, description, created_at, created_by";

/** Строка таблицы файлов → вложение для интерфейса. */
function mapFileRow(row: SettlementFilesRow): SettlementFile {
  return {
    id: row.id,
    companyId: row.company_id,
    settlementOperationId: row.settlement_operation_id,
    name: row.name,
    filePath: row.file_path,
    size: Number(row.size ?? 0),
    type: row.type,
    description: row.description,
    createdAt: row.created_at,
    createdBy: row.created_by,
  };
}

/** MIME-тип по расширению файла (для Storage и предпросмотра). */
export function settlementFileContentType(fileName: string): string {
  switch (fileExtension(fileName)) {
    case "pdf":
      return "application/pdf";
    case "doc":
      return "application/msword";
    case "docx":
      return "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
    case "xls":
      return "application/vnd.ms-excel";
    case "xlsx":
      return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
    case "jpg":
    case "jpeg":
      return "image/jpeg";
    case "png":
      return "image/png";
    default:
      return "application/octet-stream";
  }
}

/** Объекта уже нет в хранилище: для уборки это успех, а не сбой. */
function isMissingObjectError(error: {
  message: string;
  status?: number;
}): boolean {
  return error.status === 404 || /not found|no such key/i.test(error.message);
}

/**
 * Убирает объекты из Storage.
 *
 * Отсутствие объекта ошибкой не считаем: уборка может идти повторно после
 * частичного сбоя, и второй проход не должен падать.
 */
async function removeStoredObjects(paths: string[]): Promise<void> {
  if (paths.length === 0) {
    return;
  }

  const client = getRequiredClient();
  const { error } = await client.storage
    .from(SETTLEMENT_FILES_BUCKET)
    .remove(paths);

  if (error && !isMissingObjectError(error)) {
    throw new Error(error.message);
  }
}

/** Имя объекта в Storage без пробелов и символов, ломающих путь. */
function buildSafeStorageFileName(fileName: string): string {
  return fileName
    .replace(/\s+/g, "_")
    .replace(/[^a-zA-Z0-9_.-]/g, "");
}

/** Список файлов по счёту. */
export async function getSettlementFiles(
  settlementOperationId: string
): Promise<SettlementFile[]> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client
    .from("settlement_files")
    .select(FILES_SELECT)
    .eq("company_id", companyId)
    .eq("settlement_operation_id", settlementOperationId)
    .order("created_at", { ascending: false });

  if (error) {
    throw new Error(error.message);
  }

  return ((data ?? []) as unknown as SettlementFilesRow[]).map(mapFileRow);
}

export type UploadSettlementFileInput = {
  settlementOperationId: string;
  file: File;
  name: string;
  description?: string | null;
};

/** Загружает файл в Storage и сохраняет метаданные. */
export async function uploadSettlementFile(
  input: UploadSettlementFileInput
): Promise<SettlementFile> {
  assertSettlementFileAllowed(input.file);

  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const timestamp = Date.now();
  const safeName = buildSafeStorageFileName(input.name);
  const storagePath = `${companyId}/${input.settlementOperationId}/${timestamp}_${safeName}`;
  const contentType =
    input.file.type || settlementFileContentType(input.name);

  const { error: uploadError } = await client.storage
    .from(SETTLEMENT_FILES_BUCKET)
    .upload(storagePath, input.file, { contentType, upsert: false });

  if (uploadError) {
    throw new Error(uploadError.message);
  }

  // Автора записи проставляет база (auth.uid()) — отдельный запрос не нужен.
  const { data, error } = await client
    .from("settlement_files")
    .insert({
      company_id: companyId,
      settlement_operation_id: input.settlementOperationId,
      name: input.name,
      file_path: storagePath,
      size: input.file.size,
      type: contentType,
      description: input.description?.trim() || null,
    })
    .select(FILES_SELECT)
    .maybeSingle();

  if (error || !data) {
    // Запись не создалась — убираем загруженный объект, иначе он останется
    // в хранилище без ссылки и будет занимать место навсегда.
    // Уборка идёт «лучшим усилием» и не подменяет исходную причину сбоя.
    try {
      await removeStoredObjects([storagePath]);
    } catch {
      // Важнее показать пользователю ошибку записи, а не уборки.
    }
    throw error
      ? new Error(error.message)
      : new Error("Не удалось сохранить файл");
  }

  return mapFileRow(data as unknown as SettlementFilesRow);
}

/**
 * Удаляет вложение: сначала объект в Storage, потом запись.
 *
 * Порядок важен. Если убрать запись первой, а хранилище ответит ошибкой,
 * объект останется «осиротевшим» — о нём уже некому будет вспомнить.
 * При обратном порядке неудачу видно, и повторное удаление дочистит запись.
 */
export async function deleteSettlementFile(
  fileId: string,
  filePath: string
): Promise<void> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  await removeStoredObjects([filePath]);

  const { error } = await client
    .from("settlement_files")
    .delete()
    .eq("id", fileId)
    .eq("company_id", companyId);

  if (error) {
    throw new Error(error.message);
  }
}

/**
 * Удаляет все файлы счёта: сначала объекты в Storage, потом записи.
 *
 * Порядок тот же, что у одиночного удаления: без записи объект уже не найти.
 */
export async function deleteAllSettlementFilesForOperation(
  settlementOperationId: string
): Promise<void> {
  const files = await getSettlementFiles(settlementOperationId);
  if (files.length === 0) {
    return;
  }

  await removeStoredObjects(files.map((file) => file.filePath));

  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { error } = await client
    .from("settlement_files")
    .delete()
    .eq("company_id", companyId)
    .eq("settlement_operation_id", settlementOperationId);

  if (error) {
    throw new Error(error.message);
  }
}

/** Скачивает байты файла. */
export async function downloadSettlementFile(
  filePath: string
): Promise<Blob> {
  const client = getRequiredClient();
  const { data, error } = await client.storage
    .from(SETTLEMENT_FILES_BUCKET)
    .download(filePath);

  if (error) {
    throw new Error(error.message);
  }
  return data;
}
