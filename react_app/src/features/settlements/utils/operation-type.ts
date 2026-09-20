import type { SettlementOperationType } from "@/features/settlements/types/settlement.types";

/** Все типы операций в порядке показа. */
export const SETTLEMENT_OPERATION_TYPES: readonly SettlementOperationType[] = [
  "act",
  "advance",
  "other",
];

/** Подписи типов операций на русском. */
const TYPE_LABELS: Record<SettlementOperationType, string> = {
  act: "Акт",
  advance: "Аванс",
  other: "Прочее",
};

/** Варианты для выпадающего списка и переключателя типа операции. */
export const SETTLEMENT_OPERATION_TYPE_OPTIONS = SETTLEMENT_OPERATION_TYPES.map(
  (value) => ({ value, label: TYPE_LABELS[value] })
);

/** Подпись типа операции. */
export function settlementOperationTypeLabel(
  type: SettlementOperationType
): string {
  return TYPE_LABELS[type];
}

/** Проверяет, что значение из базы — известный тип операции. */
export function isSettlementOperationType(
  value: string
): value is SettlementOperationType {
  return (SETTLEMENT_OPERATION_TYPES as readonly string[]).includes(value);
}

/** Варианты оформления бейджа типа операции. */
export type SettlementTypeBadgeVariant = "default" | "secondary" | "outline";

/** Оформление бейджа: акт — основной, аванс — вторичный, прочее — контурный. */
export function settlementOperationTypeVariant(
  type: SettlementOperationType
): SettlementTypeBadgeVariant {
  switch (type) {
    case "act":
      return "default";
    case "advance":
      return "secondary";
    default:
      return "outline";
  }
}
