import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import type { PurchaseRequestDetails } from "@/features/purchase-requests/types/purchase-request.types";
import {
  pickProfileDisplayName,
} from "@/features/purchase-requests/utils/names";
import {
  asRowList,
  mapFile,
  mapHistory,
  mapInvoice,
  mapInvoiceItem,
  mapItem,
  mapPurchaseRequest,
} from "@/features/purchase-requests/utils/mappers";
import { REQUEST_SELECT, throwIfError } from "@/features/purchase-requests/api/errors";

/**
 * Имена пользователей одним пакетным запросом.
 *
 * Прямое соединение (join) с `profiles` невозможно: таблицы заявок ссылаются
 * на `auth.users`, а не на `profiles`, поэтому имена добираем отдельно и сразу
 * для всех нужных пользователей.
 */
async function fetchUserNames(userIds: string[]) {
  if (userIds.length === 0) {
    return new Map<string, string>();
  }
  const client = getRequiredClient();
  const { data, error } = await client
    .from("profiles")
    .select("id, short_name, full_name, email")
    .in("id", userIds);
  throwIfError(error);
  const names = new Map<string, string>();
  for (const row of asRowList(data)) {
    const id = typeof row.id === "string" ? row.id : null;
    const name = pickProfileDisplayName(row);
    if (id && name) {
      names.set(id, name);
    }
  }
  return names;
}

export async function getPurchaseRequestDetails(
  requestId: string
): Promise<PurchaseRequestDetails | null> {
  if (!requestId) {
    return null;
  }

  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const [requestResult, itemsResult, historyResult, invoicesResult, filesResult, invoiceItemsResult] =
    await Promise.all([
      client
        .from("purchase_requests")
        .select(REQUEST_SELECT)
        .eq("company_id", companyId)
        .eq("id", requestId)
        .maybeSingle(),
      client
        .from("purchase_request_items")
        .select()
        .eq("company_id", companyId)
        .eq("request_id", requestId)
        .order("sort_order")
        .order("created_at"),
      client
        .from("purchase_request_history")
        .select()
        .eq("company_id", companyId)
        .eq("request_id", requestId)
        .order("created_at"),
      client
        .from("purchase_request_invoices")
        .select("*, contractors:supplier_id(short_name, full_name)")
        .eq("company_id", companyId)
        .eq("request_id", requestId)
        .order("created_at"),
      client
        .from("purchase_request_files")
        .select()
        .eq("company_id", companyId)
        .eq("request_id", requestId)
        .eq("type", "invoice"),
      client
        .from("purchase_request_invoice_items")
        .select()
        .eq("company_id", companyId)
        .eq("request_id", requestId)
        .order("sort_order")
        .order("created_at"),
    ]);

  throwIfError(requestResult.error);
  throwIfError(itemsResult.error);
  throwIfError(historyResult.error);
  throwIfError(invoicesResult.error);
  throwIfError(filesResult.error);
  throwIfError(invoiceItemsResult.error);

  if (!requestResult.data) {
    return null;
  }

  const requestRow = requestResult.data as Record<string, unknown>;
  const createdBy = typeof requestRow.created_by === "string" ? requestRow.created_by : null;
  const historyRows = asRowList(historyResult.data);
  const userIds = new Set<string>();
  if (createdBy) {
    userIds.add(createdBy);
  }
  for (const row of historyRows) {
    if (typeof row.user_id === "string") {
      userIds.add(row.user_id);
    }
  }
  const names = await fetchUserNames([...userIds]);
  const createdByName = createdBy ? names.get(createdBy) ?? null : null;

  const filesByInvoice = new Map<string, ReturnType<typeof mapFile>>();
  for (const row of asRowList(filesResult.data)) {
    const file = mapFile(row);
    if (file.invoiceId && !filesByInvoice.has(file.invoiceId)) {
      filesByInvoice.set(file.invoiceId, file);
    }
  }

  // Позиции «как в счёте»: раскладываем по счетам, к которым они относятся.
  const invoiceItemsByInvoice = new Map<string, ReturnType<typeof mapInvoiceItem>[]>();
  for (const row of asRowList(invoiceItemsResult.data)) {
    const item = mapInvoiceItem(row);
    const bucket = invoiceItemsByInvoice.get(item.invoiceId);
    if (bucket) {
      bucket.push(item);
    } else {
      invoiceItemsByInvoice.set(item.invoiceId, [item]);
    }
  }

  return {
    request: mapPurchaseRequest({
      ...requestRow,
      created_by_name: createdByName,
    }),
    items: asRowList(itemsResult.data).map(mapItem),
    history: historyRows.map((row) => {
      const userId = typeof row.user_id === "string" ? row.user_id : "";
      return mapHistory({ ...row, user_name: names.get(userId) ?? null });
    }),
    invoices: asRowList(invoicesResult.data).map((row) => {
      const invoice = mapInvoice(row);
      return {
        ...invoice,
        invoiceFile: filesByInvoice.get(invoice.id) ?? null,
        items: invoiceItemsByInvoice.get(invoice.id) ?? [],
      };
    }),
  };
}
