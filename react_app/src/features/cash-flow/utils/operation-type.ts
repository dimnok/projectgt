import type { CashFlowType } from "@/features/cash-flow/types/cash-flow.types";

/** Все типы операций ДДС в порядке показа: сначала приход. */
export const CASH_FLOW_TYPES: readonly CashFlowType[] = ["income", "expense"];

/** Подписи типов операций на русском. */
const TYPE_LABELS: Record<CashFlowType, string> = {
  income: "Приход",
  expense: "Расход",
};

/** Варианты для выпадающего списка и переключателя типа операции. */
export const CASH_FLOW_TYPE_OPTIONS = CASH_FLOW_TYPES.map((value) => ({
  value,
  label: TYPE_LABELS[value],
}));

/** Подпись типа операции. */
export function cashFlowTypeLabel(type: CashFlowType): string {
  return TYPE_LABELS[type];
}

/** Проверяет, что значение из базы — известный тип операции. */
export function isCashFlowType(value: string): value is CashFlowType {
  return (CASH_FLOW_TYPES as readonly string[]).includes(value);
}
