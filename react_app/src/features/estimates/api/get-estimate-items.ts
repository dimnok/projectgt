import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import {
  ESTIMATE_ITEMS_PAGE_SIZE,
  ESTIMATE_ITEM_SELECT,
  mapEstimateItemRow,
  sortEstimateItems,
} from "@/features/estimates/utils/estimate.utils";
import type {
  EstimateFileQuery,
  EstimateItem,
} from "@/features/estimates/types/estimate.types";
import type { EstimateItemRow } from "@/types/database.types";

function dedupeById(items: EstimateItem[]): EstimateItem[] {
  const seen = new Set<string>();
  const unique: EstimateItem[] = [];

  for (const item of items) {
    if (!item.id || seen.has(item.id)) {
      continue;
    }
    seen.add(item.id);
    unique.push(item);
  }

  return unique;
}

/**
 * Loads positions of an estimate file or all estimate files within a contract.
 * Read-only: selects from `estimates_with_contracts`, same filters as Flutter.
 */
export async function getEstimateItems(
  query: EstimateFileQuery
): Promise<EstimateItem[]> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  const all: EstimateItem[] = [];
  let offset = 0;

  while (true) {
    let request = client
      .from("estimates_with_contracts")
      .select(ESTIMATE_ITEM_SELECT)
      .eq("company_id", companyId)
      .eq("visible_in_estimates_module", true);

    if (query.estimateTitle) {
      request = request.eq("estimate_title", query.estimateTitle);
    }
    if (query.objectId) {
      request = request.eq("object_id", query.objectId);
    }
    if (query.contractId) {
      request = request.eq("contract_id", query.contractId);
    }

    const { data, error } = await request
      .order("system")
      .order("subsystem")
      .order("number")
      .order("id")
      .range(offset, offset + ESTIMATE_ITEMS_PAGE_SIZE - 1);

    if (error) {
      throw new Error(error.message);
    }

    const chunk = ((data ?? []) as unknown as EstimateItemRow[]).map(
      mapEstimateItemRow
    );
    all.push(...chunk);

    if (chunk.length < ESTIMATE_ITEMS_PAGE_SIZE) {
      break;
    }

    offset += ESTIMATE_ITEMS_PAGE_SIZE;
  }

  return sortEstimateItems(dedupeById(all));
}
