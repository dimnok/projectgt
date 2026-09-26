import type {
  PurchaseRequestCounts,
  PurchaseRequestFilterStatus,
  PurchaseRequestListFilter,
  PurchaseRequestReceiverMode,
  PurchaseRequestStatus,
} from "@/features/purchase-requests/types/purchase-request.types";
import {
  PURCHASE_REQUEST_FILTER_STATUSES,
  PURCHASE_REQUEST_STATUSES,
} from "@/features/purchase-requests/types/purchase-request.types";

const STATUS_LABELS: Record<PurchaseRequestStatus, string> = {
  draft: "Черновик",
  approval: "На согласовании",
  revision: "На доработке",
  invoice_preparation: "Формирование счета",
  invoice_approval: "Согласование счета",
  accounting: "Передано бухгалтеру",
  payment_queue: "Заведено на оплату",
  paid: "Оплачено",
  received: "Получено",
  unknown: "Неизвестный статус",
};

/** Значение фильтра «Все»: серверу статус не передаётся. */
export const ALL_FILTER_VALUE = "all";
/** Название пункта «Все» в фильтре реестра. */
const ALL_FILTER_LABEL = "Все";

/** Варианты фильтра реестра: «Все» и каждый реальный статус. */
export const PURCHASE_REQUEST_FILTER_OPTIONS: {
  value: PurchaseRequestListFilter;
  label: string;
}[] = [
  { value: ALL_FILTER_VALUE, label: ALL_FILTER_LABEL },
  ...PURCHASE_REQUEST_FILTER_STATUSES.map((status) => ({
    value: status,
    label: STATUS_LABELS[status],
  })),
];

/** Сколько заявок отдаёт сервер за один запрос. */
export const LIST_LIMIT = 50;

/** Статусы, в которых заявка ждёт действия первого согласующего (на Главной). */
export const PURCHASE_REQUEST_APPROVAL_STAGES: readonly PurchaseRequestFilterStatus[] =
  ["approval"];

/** Статусы, в которых заявка требует оплаты (на Главной — «Заведено на оплату»). */
export const PURCHASE_REQUEST_PAYMENT_STAGES: readonly PurchaseRequestFilterStatus[] =
  ["payment_queue"];

/** Сумма счётчиков по набору статусов. */
export function purchaseRequestStageCount(
  counts: PurchaseRequestCounts | undefined,
  stages: readonly PurchaseRequestFilterStatus[]
): number {
  if (!counts) {
    return 0;
  }
  return stages.reduce((sum, status) => sum + (counts[status] ?? 0), 0);
}

/** Статус из базы. Неизвестное значение — `unknown`, а не падение экрана. */
export function parsePurchaseRequestStatus(value: unknown): PurchaseRequestStatus {
  if (typeof value === "string" && PURCHASE_REQUEST_STATUSES.includes(value as PurchaseRequestStatus)) {
    return value as PurchaseRequestStatus;
  }
  return "unknown";
}

/** Статус из истории: `null` остаётся `null` (первая запись журнала). */
export function parsePurchaseRequestStatusOrNull(
  value: unknown
): PurchaseRequestStatus | null {
  if (value == null) {
    return null;
  }
  return parsePurchaseRequestStatus(value);
}

/** Название статуса для интерфейса. */
export function purchaseRequestStatusLabel(status: PurchaseRequestStatus) {
  return STATUS_LABELS[status];
}

/** Значение фильтра из адреса: «Все» или реальный статус. */
export function isPurchaseRequestListFilter(
  value: string
): value is PurchaseRequestListFilter {
  return (
    value === ALL_FILTER_VALUE ||
    (PURCHASE_REQUEST_FILTER_STATUSES as readonly string[]).includes(value)
  );
}

/** Режим получателя: кто подтверждает получение — автор заявки или назначенные. */
export function parseReceiverMode(value: unknown): PurchaseRequestReceiverMode {
  return value === "fixed_user" ? "fixed_user" : "initiator";
}

/** Статусы, в которых заявка уже имеет счета и их нужно показывать. */
export function invoiceStatusesVisible(status: PurchaseRequestStatus) {
  return (
    status === "invoice_preparation" ||
    status === "invoice_approval" ||
    status === "accounting" ||
    status === "payment_queue" ||
    status === "paid" ||
    status === "received"
  );
}
