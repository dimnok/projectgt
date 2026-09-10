import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";

/**
 * Object ids that already have shifts. Same RPC as the Flutter export screen.
 */
export async function getObjectIdsWithWorks(): Promise<string[]> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client.rpc("get_distinct_work_object_ids", {
    p_company_id: companyId,
  });

  if (error) {
    throw new Error(error.message);
  }

  const rows: unknown[] = Array.isArray(data) ? data : [];

  return rows.flatMap((row) => {
    if (typeof row === "string") {
      return [row];
    }
    if (row && typeof row === "object" && "object_id" in row) {
      const id = (row as { object_id: unknown }).object_id;
      return typeof id === "string" ? [id] : [];
    }
    return [];
  });
}
