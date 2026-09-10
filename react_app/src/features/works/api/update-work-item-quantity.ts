import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import { assertCanWriteWorkItems } from "@/features/works/api/get-work-membership";
import { workItemLineTotal } from "@/features/works/utils/work.utils";

/**
 * Updates quantity and line total of a shift item.
 * Header totals are recalculated by DB trigger `update_work_aggregates`.
 */
export async function updateWorkItemQuantity(
  itemId: string,
  quantity: number
): Promise<void> {
  if (!(quantity > 0)) {
    throw new Error("Количество должно быть больше нуля");
  }

  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error: fetchError } = await client
    .from("work_items")
    .select("work_id, price, contract_act_id")
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
    throw new Error("Позиция уже в акте, менять её нельзя");
  }

  await assertCanWriteWorkItems(data.work_id);

  const price = Number(data.price ?? 0);
  const { error } = await client
    .from("work_items")
    .update({
      quantity,
      total: workItemLineTotal(price, quantity),
      updated_at: new Date().toISOString(),
    })
    .eq("id", itemId)
    .eq("company_id", companyId);

  if (error) {
    throw new Error(error.message);
  }
}
