import type { SettlementPaymentStatus } from "@/features/settlements/types/settlement.types";

/**
 * Допуск сравнения денежных сумм (копейки). Совпадает с SQL-триггером
 * `sync_settlement_payment_status`, который и считает статус оплаты.
 */
export const AMOUNT_EPSILON = 0.005;

/** Все статусы оплаты в порядке показа. */
export const SETTLEMENT_PAYMENT_STATUSES: readonly SettlementPaymentStatus[] = [
  "unpaid",
  "partial",
  "paid",
  "overpaid",
];

/** Подписи статусов оплаты на русском. */
const STATUS_LABELS: Record<SettlementPaymentStatus, string> = {
  unpaid: "Не оплачен",
  partial: "Частично",
  paid: "Оплачен",
  overpaid: "Переплата",
};

/** Подпись статуса оплаты. */
export function settlementPaymentStatusLabel(
  status: SettlementPaymentStatus
): string {
  return STATUS_LABELS[status];
}

/** Проверяет, что значение из базы — известный статус оплаты. */
export function isSettlementPaymentStatus(
  value: string
): value is SettlementPaymentStatus {
  return (SETTLEMENT_PAYMENT_STATUSES as readonly string[]).includes(value);
}

/** Варианты оформления бейджа статуса оплаты. */
export type SettlementStatusBadgeVariant =
  | "default"
  | "secondary"
  | "success"
  | "warning"
  | "outline";

/** Оформление бейджа: оплачен — зелёный, частично — жёлтый, переплата — синий. */
export function settlementPaymentStatusVariant(
  status: SettlementPaymentStatus
): SettlementStatusBadgeVariant {
  switch (status) {
    case "paid":
      return "success";
    case "partial":
      return "warning";
    case "overpaid":
      return "default";
    default:
      return "secondary";
  }
}
