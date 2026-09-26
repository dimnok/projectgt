import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import { assertCanWriteWorkItems } from "@/features/works/api/get-work-membership";
import { mapWorkRow, WORK_SELECT } from "@/features/works/api/get-month-works";
import {
  uploadWorkShiftPhoto,
  type WorkPhotoKind,
} from "@/features/works/api/upload-work-photo";
import type { Work, WorksRow } from "@/features/works/types/work.types";
import { composeWorkPhotoCollage } from "@/features/works/utils/compose-work-photo-collage";
import {
  MAX_WORK_PHOTOS_PER_KIND,
  workPhotoLegacyMode,
  workPhotoStoragePath,
} from "@/features/works/utils/work.utils";

const PHOTO_COLUMNS: Record<
  WorkPhotoKind,
  { list: "photo_urls" | "evening_photo_urls"; single: "photo_url" | "evening_photo_url" }
> = {
  morning: { list: "photo_urls", single: "photo_url" },
  evening: { list: "evening_photo_urls", single: "evening_photo_url" },
};

/** Суффикс имени служебного файла: коллаж для мобильного приложения. */
const COLLAGE_SUFFIX = "-collage";

/**
 * Собирает коллаж из 2–4 фото и кладёт его в bucket `works`.
 * Нужен для одиночного поля, которое читает мобильное приложение.
 */
export async function uploadWorkPhotoCollage(
  objectId: string,
  files: File[],
  kind: WorkPhotoKind,
  workDate?: string
): Promise<string> {
  const collage = await composeWorkPhotoCollage(files);
  return uploadWorkShiftPhoto(objectId, collage, kind, workDate, COLLAGE_SUFFIX);
}

function workPhotoList(work: Work, kind: WorkPhotoKind): string[] {
  return kind === "morning" ? work.photoUrls : work.eveningPhotoUrls;
}

function workPhotoSingle(work: Work, kind: WorkPhotoKind): string | null {
  return kind === "morning" ? work.photoUrl : work.eveningPhotoUrl;
}

/**
 * Удаляет файлы из bucket `works`. Как и при удалении смены,
 * ошибка очистки не отменяет основное действие.
 */
async function removeWorkPhotoFiles(urls: (string | null | undefined)[]): Promise<void> {
  const paths = Array.from(
    new Set(
      urls
        .map((url) => workPhotoStoragePath(url))
        .filter((path): path is string => Boolean(path))
    )
  );
  if (paths.length === 0) {
    return;
  }
  try {
    await getRequiredClient().storage.from("works").remove(paths);
  } catch {
    // Файл мог быть уже удалён — это не повод показывать ошибку пользователю.
  }
}

async function fileFromUrl(url: string): Promise<File> {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error("Не удалось прочитать фото");
  }
  const blob = await response.blob();
  return new File([blob], "photo.jpg", {
    type: blob.type || "image/jpeg",
  });
}

/**
 * Значение одиночного поля для мобильного приложения и Telegram:
 * одно фото — как есть, несколько — коллаж, ни одного — пусто.
 * Если коллаж не собрался, отдаём первое фото: смена не должна остаться без фото.
 */
async function buildSinglePhotoValue(
  work: Work,
  kind: WorkPhotoKind,
  urls: string[]
): Promise<string | null> {
  const mode = workPhotoLegacyMode(urls);
  if (mode === "none") {
    return null;
  }
  if (mode === "single") {
    return urls[0];
  }

  try {
    const files = await Promise.all(urls.map(fileFromUrl));
    return await uploadWorkPhotoCollage(work.objectId, files, kind, work.date);
  } catch {
    return urls[0];
  }
}

async function updateWorkPhotos(
  work: Work,
  kind: WorkPhotoKind,
  urls: string[],
  singleUrl: string | null
): Promise<Work> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  const columns = PHOTO_COLUMNS[kind];
  const { data, error } = await client
    .from("works")
    .update({
      [columns.list]: urls,
      [columns.single]: singleUrl,
      updated_at: new Date().toISOString(),
    })
    .eq("id", work.id)
    .eq("company_id", companyId)
    .select(WORK_SELECT)
    .single();

  if (error) {
    throw new Error(error.message);
  }

  return mapWorkRow(data as unknown as WorksRow);
}

/**
 * Общий сценарий правки списка фото: собрать новый список, записать его в базу
 * и только потом убрать из хранилища файлы, на которые больше никто не ссылается.
 */
async function applyWorkPhotoChange(
  work: Work,
  kind: WorkPhotoKind,
  nextUrls: string[],
  replacedUrls: string[],
  uploadedUrls: string[] = []
): Promise<Work> {
  const previousSingle = workPhotoSingle(work, kind);
  const nextSingle = await buildSinglePhotoValue(work, kind, nextUrls);
  const freshCollage =
    nextSingle && nextSingle !== previousSingle && !nextUrls.includes(nextSingle)
      ? nextSingle
      : null;

  let updated: Work;
  try {
    updated = await updateWorkPhotos(work, kind, nextUrls, nextSingle);
  } catch (error) {
    // Запись не прошла — только что загруженные файлы больше не нужны.
    await removeWorkPhotoFiles([...uploadedUrls, freshCollage]);
    throw error;
  }

  const stale: (string | null)[] = [...replacedUrls];
  if (freshCollage) {
    // Прежний коллаж или одиночное фото больше не используется.
    stale.push(previousSingle);
  }
  await removeWorkPhotoFiles(stale);

  return updated;
}

/**
 * Добавляет фото смены (утро или вечер), не больше 4 с каждой стороны.
 * Параметры загрузки совпадают с Flutter: bucket `works`, папка смены.
 */
export async function addWorkShiftPhotos(
  work: Work,
  files: File[],
  kind: WorkPhotoKind
): Promise<Work> {
  if (files.length === 0) {
    return work;
  }
  await assertCanWriteWorkItems(work.id);

  const current = workPhotoList(work, kind);
  if (current.length + files.length > MAX_WORK_PHOTOS_PER_KIND) {
    throw new Error(
      `Можно приложить не больше ${MAX_WORK_PHOTOS_PER_KIND} фото с каждой стороны`
    );
  }

  const uploaded: string[] = [];
  try {
    for (const file of files) {
      uploaded.push(
        await uploadWorkShiftPhoto(work.objectId, file, kind, work.date)
      );
    }
  } catch (error) {
    // Часть фото уже в хранилище, а в базу они не попадут — убираем их.
    await removeWorkPhotoFiles(uploaded);
    throw error;
  }

  return applyWorkPhotoChange(work, kind, [...current, ...uploaded], [], uploaded);
}

/** Заменяет одно фото смены по порядковому номеру. */
export async function replaceWorkShiftPhotoAt(
  work: Work,
  file: File,
  kind: WorkPhotoKind,
  index: number
): Promise<Work> {
  await assertCanWriteWorkItems(work.id);

  const current = workPhotoList(work, kind);
  if (index < 0 || index >= current.length) {
    throw new Error("Фото не найдено");
  }

  const photoUrl = await uploadWorkShiftPhoto(work.objectId, file, kind, work.date);
  const nextUrls = current.map((url, position) =>
    position === index ? photoUrl : url
  );

  return applyWorkPhotoChange(work, kind, nextUrls, [current[index]], [photoUrl]);
}

/** Удаляет одно фото смены по порядковому номеру. */
export async function deleteWorkShiftPhotoAt(
  work: Work,
  kind: WorkPhotoKind,
  index: number
): Promise<Work> {
  await assertCanWriteWorkItems(work.id);

  const current = workPhotoList(work, kind);
  if (index < 0 || index >= current.length) {
    throw new Error("Фото не найдено");
  }

  const nextUrls = current.filter((_, position) => position !== index);

  return applyWorkPhotoChange(work, kind, nextUrls, [current[index]]);
}
