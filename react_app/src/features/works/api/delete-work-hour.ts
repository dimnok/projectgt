import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import { assertCanWriteWorkItems } from "@/features/works/api/get-work-membership";

/**
 * Removes an employee from a shift. Same as Flutter `deleteWorkHour`.
 */
export async function deleteWorkHour(hourId: string): Promise<void> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error: fetchError } = await client
    .from("work_hours")
    .select("work_id")
    .eq("id", hourId)
    .eq("company_id", companyId)
    .maybeSingle();

  if (fetchError) {
    throw new Error(fetchError.message);
  }
  if (!data) {
    throw new Error("Запись не найдена");
  }

  await assertCanWriteWorkItems(data.work_id);

  const { error } = await client
    .from("work_hours")
    .delete()
    .eq("id", hourId)
    .eq("company_id", companyId);

  if (error) {
    throw new Error(error.message);
  }
}
