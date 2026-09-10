import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import { assertCanWriteWorkItems } from "@/features/works/api/get-work-membership";
import type { WorkHourBulkUpdate } from "@/features/works/utils/work-hours-mass-edit";

/**
 * Updates hours for many rows in one round, same idea as Flutter `updateWorkHoursBulk`.
 */
export async function updateWorkHoursBulk(
  workId: string,
  updates: WorkHourBulkUpdate[]
): Promise<void> {
  if (!workId) {
    throw new Error("Не указана смена");
  }
  if (updates.length === 0) {
    return;
  }
  if (updates.some((item) => item.hours < 0)) {
    throw new Error("Часы не могут быть отрицательными");
  }

  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  await assertCanWriteWorkItems(workId);
  const now = new Date().toISOString();

  const results = await Promise.all(
    updates.map((item) =>
      client
        .from("work_hours")
        .update({
          hours: item.hours,
          updated_at: now,
        })
        .eq("id", item.hourId)
        .eq("work_id", workId)
        .eq("company_id", companyId)
    )
  );

  const failed = results.find((result) => result.error);
  if (failed?.error) {
    throw new Error(failed.error.message);
  }
}
