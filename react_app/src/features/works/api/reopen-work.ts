import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import { assertIsSuperAdmin } from "@/features/works/api/get-work-membership";
import { mapWorkRow, WORK_SELECT } from "@/features/works/api/get-month-works";
import type { Work, WorksRow } from "@/features/works/types/work.types";

/**
 * Reopens a closed shift. Super-admin only.
 */
export async function reopenWork(workId: string): Promise<Work> {
  await assertIsSuperAdmin();

  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  const { data: row, error: fetchError } = await client
    .from("works")
    .select("status")
    .eq("id", workId)
    .eq("company_id", companyId)
    .maybeSingle();

  if (fetchError) {
    throw new Error(fetchError.message);
  }
  if (!row) {
    throw new Error("Смена не найдена");
  }
  if (String(row.status).toLowerCase() !== "closed") {
    throw new Error("Открыть можно только закрытую смену");
  }

  const { data, error } = await client
    .from("works")
    .update({
      status: "open",
      updated_at: new Date().toISOString(),
    })
    .eq("id", workId)
    .eq("company_id", companyId)
    .select(WORK_SELECT)
    .single();

  if (error) {
    throw new Error(error.message);
  }

  return mapWorkRow(data as unknown as WorksRow);
}
