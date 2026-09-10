import type {
  EstimateCompletion,
  EstimateExecution,
  EstimateItem,
} from "@/features/estimates/types/estimate.types";
import { toNumber } from "@/features/estimates/utils/estimate.utils";
import type { EstimateCompletionRow } from "@/types/database.types";

function textId(value: string | null | undefined): string {
  return value?.trim() ?? "";
}

export function mapEstimateCompletionRow(
  row: EstimateCompletionRow
): EstimateCompletion {
  return {
    estimateId: textId(row.estimate_id),
    completedQuantity: toNumber(row.completed_quantity),
    remainingQuantity: toNumber(row.remaining_quantity),
  };
}

export function parseEstimateCompletionPayload(
  data: unknown
): EstimateCompletionRow[] {
  if (data == null) {
    return [];
  }

  if (typeof data === "string") {
    try {
      return parseEstimateCompletionPayload(JSON.parse(data));
    } catch {
      return [];
    }
  }

  if (!Array.isArray(data)) {
    return [];
  }

  return data.filter(
    (row): row is EstimateCompletionRow =>
      Boolean(row) && typeof row === "object"
  );
}

export function mapEstimateCompletionById(
  rows: EstimateCompletion[]
): Map<string, EstimateCompletion> {
  const byId = new Map<string, EstimateCompletion>();

  for (const row of rows) {
    if (!row.estimateId) {
      continue;
    }
    byId.set(row.estimateId, row);
  }

  return byId;
}

/**
 * Execution money uses the estimate unit price, same as the Excel export:
 * completed/remaining amount = price × quantity.
 */
export function getEstimateExecution(
  item: EstimateItem,
  completion: EstimateCompletion | undefined
): EstimateExecution {
  const completedQuantity = completion?.completedQuantity ?? 0;
  const remainingQuantity =
    completion?.remainingQuantity ?? item.quantity - completedQuantity;

  return {
    completedQuantity,
    completedTotal: item.price * completedQuantity,
    remainingQuantity,
    remainingTotal: item.price * remainingQuantity,
  };
}

export function sumCompletedTotal(
  items: EstimateItem[],
  completionById: Map<string, EstimateCompletion>
): number {
  return items.reduce((sum, item) => {
    const execution = getEstimateExecution(item, completionById.get(item.id));
    return sum + execution.completedTotal;
  }, 0);
}

export function sumRemainingTotal(
  items: EstimateItem[],
  completionById: Map<string, EstimateCompletion>
): number {
  return items.reduce((sum, item) => {
    const execution = getEstimateExecution(item, completionById.get(item.id));
    return sum + execution.remainingTotal;
  }, 0);
}

/**
 * Checks if the completed quantity exceeds the estimated quantity.
 */
export function isEstimateOverrun(
  item: EstimateItem,
  completion?: EstimateCompletion
): boolean {
  if (!completion) {
    return false;
  }
  return completion.completedQuantity > item.quantity + 0.0001;
}

/**
 * Filters estimate items to include only those where completion exceeds estimate quantity.
 */
export function filterEstimateItemsByOverrun(
  items: EstimateItem[],
  completionById: Map<string, EstimateCompletion>
): EstimateItem[] {
  return items.filter((item) =>
    isEstimateOverrun(item, completionById.get(item.id))
  );
}
