import type { SortDirection } from "@/lib/table-sort";

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
  /**
   * Колонка-источник, за видимостью которой следует эта колонка.
   *
   * Нужна колонкам выполнения: если пользователь скрыл «Сумму», колонки
   * «Сумма вып.» и «Ост. сумма» тоже не показываются.
   */
  dependsOn?: EstimatePlanColumnId;
  /**
   * Первое направление сортировки по клику на заголовок.
   *
   * Текст удобнее читать по алфавиту, а количества и суммы — по убыванию,
   * поэтому у числовых колонок задано «desc», у остальных по умолчанию «asc».
   */
  sortFirst?: SortDirection;
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
    sortFirst: "desc",
  },
  {
    id: "price",
    label: "Цена",
    minWidth: 85,
    align: "right",
    hideable: true,
    sortFirst: "desc",
  },
  {
    id: "total",
    label: "Сумма",
    minWidth: 95,
    align: "right",
    hideable: true,
    sortFirst: "desc",
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
    sortFirst: "desc",
  },
  {
    id: "completedTotal",
    label: "Сумма\nвып.",
    title: "Выполнено, сумма (цена сметы × количество)",
    minWidth: 95,
    align: "right",
    hideable: false,
    dependsOn: "total",
    sortFirst: "desc",
  },
  {
    id: "remainingQuantity",
    label: "Кол-во\nост.",
    title: "Остаток, количество",
    minWidth: 74,
    align: "right",
    hideable: false,
    sortFirst: "desc",
  },
  {
    id: "remainingTotal",
    label: "Ост.\nсумма",
    title: "Остаток, сумма (цена сметы × остаток)",
    minWidth: 95,
    align: "right",
    hideable: false,
    dependsOn: "total",
    sortFirst: "desc",
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

/**
 * Колонки таблицы сметы с учётом настроек вида.
 *
 * Обычные колонки скрываются по списку `hidden`, а колонки выполнения
 * добавляются только при `showExecution` и дополнительно следуют за своей
 * колонкой-источником (`dependsOn`): скрыли «Сумму» — пропали «Сумма вып.»
 * и «Ост. сумма».
 */
export function resolveEstimateColumns(
  hidden: ReadonlySet<EstimatePlanColumnId>,
  showExecution: boolean
): readonly EstimateColumn[] {
  const planColumns = ESTIMATE_COLUMNS.filter(
    (column) => !hidden.has(column.id)
  );
  if (!showExecution) {
    return planColumns;
  }
  const executionColumns = ESTIMATE_EXECUTION_COLUMNS.filter(
    (column) => !column.dependsOn || !hidden.has(column.dependsOn)
  );
  return [...planColumns, ...executionColumns];
}
