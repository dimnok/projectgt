import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import { getObjects } from "@/features/objects/api/get-objects";
import { mapEstimateGroupRow } from "@/features/estimates/utils/estimate.utils";
import type { EstimateFile } from "@/features/estimates/types/estimate.types";
import type { EstimateGroupRow } from "@/types/database.types";

/**
 * Loads estimate file groups for the active company.
 * Read-only: same RPC as Flutter (`get_estimate_groups`).
 */
export async function getEstimateGroups(): Promise<EstimateFile[]> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  const [groupsResult, objectsResult] = await Promise.allSettled([
    client.rpc("get_estimate_groups", { p_company_id: companyId }),
    getObjects(),
  ]);

  if (groupsResult.status === "rejected") {
    throw groupsResult.reason instanceof Error
      ? groupsResult.reason
      : new Error("Не удалось загрузить сметы");
  }

  if (groupsResult.value.error) {
    throw new Error(groupsResult.value.error.message);
  }

  const objects =
    objectsResult.status === "fulfilled" ? objectsResult.value : [];
  const objectNameById = new Map(
    objects.map((object) => [object.id, object.name])
  );

  return ((groupsResult.value.data ?? []) as EstimateGroupRow[]).map((row) =>
    mapEstimateGroupRow(row, objectNameById)
  );
}
