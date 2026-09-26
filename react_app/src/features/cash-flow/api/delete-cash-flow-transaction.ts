import { assertPermission } from "@/features/roles/api/assert-permission";
import { getActiveCompanyId } from "@/lib/supabase/company";

/**
 * Удаляет операцию ДДС.
 *
 * База сама возвращает связанную строку банковской выписки в статус
 * «не обработана» и удаляет оплату по счёту взаиморасчётов, если операция
 * была создана из выписки (триггер и каскад).
 */
export async function deleteCashFlowTransaction(id: string): Promise<void> {
  const { client } = await assertPermission("cash_flow", "delete");
  const companyId = await getActiveCompanyId();

  const { error } = await client
    .from("cash_flow")
    .delete()
    .eq("id", id)
    .eq("company_id", companyId);

  if (error) {
    throw new Error(error.message);
  }
}
