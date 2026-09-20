import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import type {
  PurchaseRequestInvoiceItem,
  PurchaseRequestInvoiceItemDraft,
} from "@/features/purchase-requests/types/purchase-request.types";
import {
  asRowList,
  mapFile,
  mapInvoice,
  mapInvoiceItem,
} from "@/features/purchase-requests/utils/mappers";
import {
  buildSafeStorageFileName,
  contentTypeForFileName,
} from "@/features/purchase-requests/utils/invoices";
import {
  PURCHASE_REQUESTS_BUCKET,
  throwIfError,
} from "@/features/purchase-requests/api/errors";

/** Удаляет файлы счёта из хранилища. Ошибку возвращает вызывающему коду. */
async function removeStoragePaths(paths: string[]) {
  if (paths.length === 0) {
    return;
  }
  const client = getRequiredClient();
  const { error } = await client.storage.from(PURCHASE_REQUESTS_BUCKET).remove(paths);
  throwIfError(error);
}

/**
 * Убирает следы неудачного создания счёта: файл в хранилище и запись в базе.
 * Уборка идёт «лучшим усилием» и не подменяет исходную причину сбоя.
 */
async function discardInvoiceArtifacts(
  companyId: string,
  invoiceId: string,
  storagePaths: string[]
) {
  try {
    await removeStoragePaths(storagePaths);
  } catch {
    // Файл мог не загрузиться — уборка лучшим усилием.
  }

  // Запись могла не создаться: исходная ошибка важнее результата уборки.
  await getRequiredClient()
    .from("purchase_request_invoices")
    .delete()
    .eq("company_id", companyId)
    .eq("id", invoiceId);
}

/**
 * Сохраняет строки счёта одной операцией: новые добавляются, изменённые
 * обновляются, отсутствующие удаляются. Доступно на этапе подготовки счетов.
 */
export async function replacePurchaseRequestInvoiceItems(
  invoiceId: string,
  items: PurchaseRequestInvoiceItemDraft[]
): Promise<PurchaseRequestInvoiceItem[]> {
  const client = getRequiredClient();
  const { data, error } = await client.rpc(
    "purchase_request_replace_invoice_items",
    {
      p_invoice_id: invoiceId,
      p_items: items,
    }
  );
  throwIfError(error);
  return asRowList(data).map(mapInvoiceItem);
}

export async function createPurchaseRequestInvoice(input: {
  requestId: string;
  supplierId: string;
  amount: number;
  invoiceNumber: string | null;
  invoiceDate: string | null;
  comment: string | null;
  file: File;
  /** Позиции «как в счёте»: необязательны. */
  items?: PurchaseRequestInvoiceItemDraft[];
}) {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  const {
    data: { user },
  } = await client.auth.getUser();

  const { data, error } = await client
    .from("purchase_request_invoices")
    .insert({
      company_id: companyId,
      request_id: input.requestId,
      supplier_id: input.supplierId,
      amount: input.amount,
      invoice_number: input.invoiceNumber,
      invoice_date: input.invoiceDate,
      comment: input.comment,
      ...(user?.id ? { created_by: user.id } : {}),
    })
    .select("*, contractors:supplier_id(short_name, full_name)")
    .single();
  throwIfError(error);

  const invoice = mapInvoice(data as Record<string, unknown>);
  const contentType = contentTypeForFileName(input.file.name);
  const safeName = buildSafeStorageFileName(input.file.name);
  const storagePath = `${companyId}/${input.requestId}/invoices/${invoice.id}/${Date.now()}_${safeName}`;
  let uploaded = false;

  try {
    const upload = await client.storage
      .from(PURCHASE_REQUESTS_BUCKET)
      .upload(storagePath, input.file, {
        cacheControl: "3600",
        upsert: false,
        contentType,
      });
    throwIfError(upload.error);
    uploaded = true;

    const fileInsert = await client
      .from("purchase_request_files")
      .insert({
        company_id: companyId,
        request_id: input.requestId,
        invoice_id: invoice.id,
        type: "invoice",
        storage_path: storagePath,
        file_name: input.file.name,
        mime_type: contentType,
        size: input.file.size,
        ...(user?.id ? { uploaded_by: user.id } : {}),
      })
      .select()
      .single();
    throwIfError(fileInsert.error);

    // Строки счёта сохраняем после файла: счёт уже существует и доступен.
    const items = input.items?.length
      ? await replacePurchaseRequestInvoiceItems(invoice.id, input.items)
      : [];

    return {
      ...invoice,
      invoiceFile: mapFile(fileInsert.data as Record<string, unknown>),
      items,
    };
  } catch (reason) {
    await discardInvoiceArtifacts(
      companyId,
      invoice.id,
      uploaded ? [storagePath] : []
    );
    throw reason;
  }
}

export async function deletePurchaseRequestInvoice(invoiceId: string) {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const files = await client
    .from("purchase_request_files")
    .select("storage_path")
    .eq("company_id", companyId)
    .eq("invoice_id", invoiceId);
  throwIfError(files.error);

  const paths = asRowList(files.data)
    .map((row) => (typeof row.storage_path === "string" ? row.storage_path : null))
    .filter((path): path is string => Boolean(path));

  // Сначала удаляем запись, затем чистим файлы: файл без счёта в базе не нужен.
  const { error } = await client
    .from("purchase_request_invoices")
    .delete()
    .eq("company_id", companyId)
    .eq("id", invoiceId);
  throwIfError(error);

  try {
    await removeStoragePaths(paths);
  } catch {
    // Запись уже удалена: сбой хранилища не отменяет успешное действие.
  }
}

export async function downloadPurchaseRequestInvoiceFile(storagePath: string) {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  if (!storagePath.startsWith(`${companyId}/`)) {
    throw new Error("Некорректный путь файла счёта");
  }
  const { data, error } = await client.storage
    .from(PURCHASE_REQUESTS_BUCKET)
    .download(storagePath);
  throwIfError(error);
  if (!data) {
    throw new Error("Файл счёта не найден");
  }
  return data;
}
