import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import {
  mapEstimateCompletionRow,
  parseEstimateCompletionPayload,
} from "@/features/estimates/utils/estimate-execution";
import type { EstimateCompletion } from "@/features/estimates/types/estimate.types";

/**
 * Loads fact quantities for estimate positions.
 * Read-only: same RPC as Flutter (`get_estimate_completion_by_ids`).
 */
export async function getEstimateCompletionByIds(
  estimateIds: string[]
): Promise<EstimateCompletion[]> {
  if (estimateIds.length === 0) {
    return [];
  }

  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  const { data, error } = await client.rpc("get_estimate_completion_by_ids", {
    p_company_id: companyId,
    p_estimate_ids: estimateIds,
  });

  if (error) {
    throw new Error(error.message);
  }

  return parseEstimateCompletionPayload(data)
    .map(mapEstimateCompletionRow)
    .filter((row) => row.estimateId.length > 0);
}
