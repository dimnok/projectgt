import type {
  PurchaseRequest,
  PurchaseRequestCompanyUser,
  PurchaseRequestCounts,
  PurchaseRequestFile,
  PurchaseRequestHistoryEntry,
  PurchaseRequestInvoice,
  PurchaseRequestItem,
  PurchaseRequestItemDraft,
  PurchaseRequestInvoiceItem,
  PurchaseRequestListItem,
  PurchaseRequestListFilter,
  PurchaseRequestPaidByObject,
  PurchaseRequestSettings,
} from "@/features/purchase-requests/types/purchase-request.types";
import { PURCHASE_REQUEST_FILTER_STATUSES } from "@/features/purchase-requests/types/purchase-request.types";
import {
  asOptionalString,
  pickUserDisplayName,
} from "@/features/purchase-requests/utils/names";
import {
  parsePurchaseRequestStatus,
  parsePurchaseRequestStatusOrNull,
  parseReceiverMode,
} from "@/features/purchase-requests/utils/status";

function asRecord(value: unknown): Record<string, unknown> | null {
  if (value && typeof value === "object" && !Array.isArray(value)) {
    return value as Record<string, unknown>;
  }
  return null;
}

function asNumber(value: unknown, fallback = 0) {
  return typeof value === "number" ? value : fallback;
}

/** Число или null: пустые значения в базе приходят как null. */
function asOptionalNumber(value: unknown): number | null {
  return typeof value === "number" ? value : null;
}

export function mapListItem(row: Record<string, unknown>): PurchaseRequestListItem {
  return {
    id: String(row.id),
    number: String(row.number),
    objectId: String(row.object_id),
    objectName: asOptionalString(row.object_name) ?? "",
    status: parsePurchaseRequestStatus(row.status),
    createdBy: String(row.created_by),
    createdByName: asOptionalString(row.created_by_name),
    totalAmount: asNumber(row.total_amount),
    createdAt: String(row.created_at),
  };
}

/**
 * Шапка заявки. Имя инициатора приходит отдельным запросом и кладётся
 * вызывающим кодом в `created_by_name`.
 */
export function mapPurchaseRequest(row: Record<string, unknown>): PurchaseRequest {
  const objects = asRecord(row.objects);

  return {
    id: String(row.id),
    companyId: String(row.company_id),
    number: String(row.number),
    objectId: String(row.object_id),
    objectName: asOptionalString(objects?.name) ?? asOptionalString(row.object_name),
    createdBy: String(row.created_by),
    createdByName: asOptionalString(row.created_by_name)?.trim() || null,
    status: parsePurchaseRequestStatus(row.status),
    comment: asOptionalString(row.comment),
    totalAmount: asNumber(row.total_amount),
    createdAt: asOptionalString(row.created_at),
  };
}

export function mapItem(row: Record<string, unknown>): PurchaseRequestItem {
  return {
    id: String(row.id),
    requestId: String(row.request_id),
    name: String(row.name),
    quantity: asNumber(row.quantity),
    unit: asOptionalString(row.unit) ?? "шт",
    article: asOptionalString(row.article),
    createdAt: asOptionalString(row.created_at),
  };
}

/** Позиция заявки в виде, пригодном для сохранения через RPC. */
export function mapItemToDraft(item: PurchaseRequestItem): PurchaseRequestItemDraft {
  return {
    id: item.id,
    name: item.name,
    quantity: item.quantity,
    unit: item.unit,
    article: item.article,
  };
}

export function mapFile(row: Record<string, unknown>): PurchaseRequestFile {
  return {
    id: String(row.id),
    requestId: String(row.request_id),
    invoiceId: asOptionalString(row.invoice_id),
    storagePath: String(row.storage_path),
    fileName: String(row.file_name),
    mimeType: asOptionalString(row.mime_type),
  };
}

export function mapInvoice(row: Record<string, unknown>): PurchaseRequestInvoice {
  const contractor = asRecord(row.contractors);
  const supplierName = contractor
    ? pickUserDisplayName({
        shortName: asOptionalString(contractor.short_name),
        fullName: asOptionalString(contractor.full_name),
      })
    : null;

  return {
    id: String(row.id),
    requestId: String(row.request_id),
    companyId: String(row.company_id),
    supplierId: String(row.supplier_id),
    supplierName,
    amount: asNumber(row.amount),
    invoiceNumber: asOptionalString(row.invoice_number),
    invoiceDate: asOptionalString(row.invoice_date),
    comment: asOptionalString(row.comment),
    createdAt: asOptionalString(row.created_at),
    invoiceFile: null,
    items: [],
  };
}

/** Строка счёта: как товар назван в самом счёте. */
export function mapInvoiceItem(
  row: Record<string, unknown>
): PurchaseRequestInvoiceItem {
  return {
    id: String(row.id),
    invoiceId: String(row.invoice_id),
    requestItemId: asOptionalString(row.request_item_id),
    article: asOptionalString(row.article),
    name: String(row.name),
    unit: asOptionalString(row.unit),
    quantity: asOptionalNumber(row.quantity),
    price: asOptionalNumber(row.price),
    amount: asOptionalNumber(row.amount),
  };
}

export function mapHistory(row: Record<string, unknown>): PurchaseRequestHistoryEntry {
  return {
    id: String(row.id),
    requestId: String(row.request_id),
    userId: String(row.user_id),
    userName: asOptionalString(row.user_name),
    action: String(row.action),
    fromStatus: parsePurchaseRequestStatusOrNull(row.from_status),
    toStatus: parsePurchaseRequestStatusOrNull(row.to_status),
    comment: asOptionalString(row.comment),
    createdAt: String(row.created_at),
  };
}

export function mapCompanyUser(row: Record<string, unknown>): PurchaseRequestCompanyUser {
  return {
    id: String(row.id),
    email: asOptionalString(row.email) ?? "",
    fullName: asOptionalString(row.full_name),
    shortName: asOptionalString(row.short_name),
  };
}

/**
 * Настройки маршрута. Порядок участников задаёт запрос
 * (`sort_order`, `user_id`), поэтому повторная сортировка не нужна.
 */
export function mapSettings(
  settingsRow: Record<string, unknown>,
  memberRows: Record<string, unknown>[]
): PurchaseRequestSettings {
  function idsFor(role: string) {
    return memberRows
      .filter((row) => row.role === role)
      .map((row) => String(row.user_id));
  }

  return {
    companyId: String(settingsRow.company_id),
    firstApproverIds: idsFor("first_approver"),
    invoicePreparerIds: idsFor("invoice_preparer"),
    invoiceApproverIds: idsFor("invoice_approver"),
    accountantIds: idsFor("accountant"),
    receiverMode: parseReceiverMode(settingsRow.receiver_mode),
    fixedReceiverIds: idsFor("receiver"),
  };
}

/** Счётчики заявок по статусам из RPC `purchase_request_status_counts`. */
export function mapStatusCounts(
  rows: Record<string, unknown>[]
): PurchaseRequestCounts {
  const counts = { all: 0 } as PurchaseRequestCounts;
  for (const status of PURCHASE_REQUEST_FILTER_STATUSES) {
    counts[status] = 0;
  }
  for (const row of rows) {
    const code = asOptionalString(row.status_code);
    if (code && code in counts) {
      counts[code as PurchaseRequestListFilter] = asNumber(row.request_count);
    }
  }
  return counts;
}

/** Строка KPI «Оплачено по объектам» из RPC `purchase_request_paid_by_object`. */
export function mapPaidByObject(
  row: Record<string, unknown>
): PurchaseRequestPaidByObject {
  return {
    objectId: String(row.object_id),
    objectName: asOptionalString(row.object_name) ?? "",
    paidAmount: asNumber(row.paid_amount),
    requestsCount: asNumber(row.requests_count),
  };
}

export function asRowList(data: unknown): Record<string, unknown>[] {
  if (!Array.isArray(data)) {
    return [];
  }
  return data.flatMap((item) => {
    const row = asRecord(item);
    return row ? [row] : [];
  });
}

export function asRow(data: unknown): Record<string, unknown> | null {
  if (Array.isArray(data)) {
    return asRecord(data[0]);
  }
  return asRecord(data);
}
