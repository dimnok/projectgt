export const ESTIMATE_TABLE_STORAGE_KEY = "react-estimates-table-layout";

export type EstimatePlanColumnId =
  | "system"
  | "subsystem"
  | "number"
  | "name"
  | "article"
  | "manufacturer"
  | "unit"
  | "quantity"
  | "price"
  | "total";

export type EstimateExecutionColumnId =
  | "completedQuantity"
  | "completedTotal"
  | "remainingQuantity"
  | "remainingTotal";

export type EstimateColumnId = EstimatePlanColumnId | EstimateExecutionColumnId;

export type EstimateColumnAlign = "left" | "right";

export type EstimateColumn<TId extends EstimateColumnId = EstimateColumnId> = {
  id: TId;
  label: string;
  title?: string;
  minWidth: number;
  align: EstimateColumnAlign;
  hideable: boolean;
};

export const ESTIMATE_COLUMNS: readonly EstimateColumn<EstimatePlanColumnId>[] = [
  {
    id: "system",
    label: "Система",
    minWidth: 100,
    align: "left",
    hideable: true,
  },
  {
    id: "subsystem",
    label: "Подсистема",
    minWidth: 100,
    align: "left",
    hideable: true,
  },
  {
    id: "number",
    label: "№",
    minWidth: 44,
    align: "left",
    hideable: true,
  },
  {
    id: "name",
    label: "Наименование",
    minWidth: 260,
    align: "left",
    hideable: false,
  },
  {
    id: "article",
    label: "Артикул",
    minWidth: 80,
    align: "left",
    hideable: true,
  },
  {
    id: "manufacturer",
    label: "Произв.",
    minWidth: 80,
    align: "left",
    hideable: true,
  },
  {
    id: "unit",
    label: "Ед. изм.",
    minWidth: 56,
    align: "left",
    hideable: true,
  },
  {
    id: "quantity",
    label: "Кол-во",
    minWidth: 70,
    align: "right",
    hideable: true,
  },
  {
    id: "price",
    label: "Цена",
    minWidth: 85,
    align: "right",
    hideable: true,
  },
  {
    id: "total",
    label: "Сумма",
    minWidth: 95,
    align: "right",
    hideable: true,
  },
];

export const ESTIMATE_EXECUTION_COLUMNS: readonly EstimateColumn<EstimateExecutionColumnId>[] = [
  {
    id: "completedQuantity",
    label: "Кол-во\nвып.",
    title: "Выполнено, количество",
    minWidth: 74,
    align: "right",
    hideable: false,
  },
  {
    id: "completedTotal",
    label: "Сумма\nвып.",
    title: "Выполнено, сумма (цена сметы × количество)",
    minWidth: 95,
    align: "right",
    hideable: false,
  },
  {
    id: "remainingQuantity",
    label: "Ост.\nкол-во",
    title: "Остаток, количество",
    minWidth: 74,
    align: "right",
    hideable: false,
  },
  {
    id: "remainingTotal",
    label: "Ост.\nсумма",
    title: "Остаток, сумма (цена сметы × остаток)",
    minWidth: 95,
    align: "right",
    hideable: false,
  },
];

export function isEstimatePlanColumnId(
  value: string
): value is EstimatePlanColumnId {
  return ESTIMATE_COLUMNS.some((column) => column.id === value);
}

export function isEstimateColumnId(value: string): value is EstimateColumnId {
  return (
    isEstimatePlanColumnId(value) ||
    ESTIMATE_EXECUTION_COLUMNS.some((column) => column.id === value)
  );
}

export function isEstimateExecutionColumnId(
  value: string
): value is EstimateExecutionColumnId {
  return ESTIMATE_EXECUTION_COLUMNS.some((column) => column.id === value);
}
