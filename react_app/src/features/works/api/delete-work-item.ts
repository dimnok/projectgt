import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import { assertCanWriteWorkItems } from "@/features/works/api/get-work-membership";

/**
 * Deletes a shift work item. Header totals are recalculated by DB trigger.
 */
export async function deleteWorkItem(itemId: string): Promise<void> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error: fetchError } = await client
    .from("work_items")
    .select("work_id, contract_act_id")
    .eq("id", itemId)
    .eq("company_id", companyId)
    .maybeSingle();

  if (fetchError) {
    throw new Error(fetchError.message);
  }
  if (!data) {
    throw new Error("Позиция не найдена");
  }
  if (data.contract_act_id) {
    throw new Error("Позиция уже в акте, удалять её нельзя");
  }

  await assertCanWriteWorkItems(data.work_id);

  const { error } = await client
    .from("work_items")
    .delete()
    .eq("id", itemId)
    .eq("company_id", companyId);

  if (error) {
    throw new Error(error.message);
  }
}
