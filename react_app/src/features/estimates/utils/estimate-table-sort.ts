import type {
  EstimateCompletion,
  EstimateItem,
  EstimateTableSort,
} from "@/features/estimates/types/estimate.types";
import { getEstimateExecution } from "@/features/estimates/utils/estimate-execution";
import {
  compareEstimateItems,
  compareEstimateNumbers,
} from "@/features/estimates/utils/estimate-sort";
import type { EstimateColumnId } from "@/features/estimates/utils/estimate-table-columns";

/** Значение колонки для сортировки: текст сравниваем как текст, суммы — как числа. */
function sortValueFor(
  item: EstimateItem,
  columnId: EstimateColumnId,
  completionById: Map<string, EstimateCompletion>
): string | number {
  switch (columnId) {
    case "system":
      return item.system;
    case "subsystem":
      return item.subsystem;
    case "number":
      return item.number;
    case "name":
      return item.name;
    case "article":
      return item.article;
    case "manufacturer":
      return item.manufacturer;
    case "unit":
      return item.unit;
    case "quantity":
      return item.quantity;
    case "price":
      return item.price;
    case "total":
      return item.total;
    case "completedQuantity":
      return getEstimateExecution(item, completionById.get(item.id))
        .completedQuantity;
    case "completedTotal":
      return getEstimateExecution(item, completionById.get(item.id))
        .completedTotal;
    case "remainingQuantity":
      return getEstimateExecution(item, completionById.get(item.id))
        .remainingQuantity;
    case "remainingTotal":
      return getEstimateExecution(item, completionById.get(item.id))
        .remainingTotal;
  }
}

/** Сравнение значений колонки без учёта направления сортировки. */
function compareColumnValues(
  left: EstimateItem,
  right: EstimateItem,
  columnId: EstimateColumnId,
  completionById: Map<string, EstimateCompletion>
): number {
  if (columnId === "number") {
    return compareEstimateNumbers(left.number, right.number);
  }

  const a = sortValueFor(left, columnId, completionById);
  const b = sortValueFor(right, columnId, completionById);

  if (typeof a === "number" && typeof b === "number") {
    return a - b;
  }

  return String(a).localeCompare(String(b), "ru", {
    numeric: true,
    sensitivity: "base",
  });
}

/**
 * Сортировка строк таблицы смет по выбранной колонке.
 *
 * Без сортировки (`sort === null`) порядок не меняется — остаётся исходный:
 * система → подсистема → №. Равные значения тоже идут в исходном порядке.
 * Колонки выполнения считаются по цене сметы и загруженному факту работ.
 */
export function sortEstimateItemsByColumn(
  items: EstimateItem[],
  sort: EstimateTableSort,
  completionById: Map<string, EstimateCompletion>
): EstimateItem[] {
  if (!sort) {
    return items;
  }

  const factor = sort.direction === "asc" ? 1 : -1;

  return [...items].sort((left, right) => {
    const compared = compareColumnValues(
      left,
      right,
      sort.key,
      completionById
    );

    return compared !== 0 ? compared * factor : compareEstimateItems(left, right);
  });
}
