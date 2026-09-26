import { assertPermission } from "@/features/roles/api/assert-permission";
import { getActiveCompanyId } from "@/lib/supabase/company";
import { cashFlowCategoryDeleteError } from "@/features/cash-flow/utils/cash-flow.utils";

/**
 * Удаляет статью ДДС.
 *
 * Статью, на которую ссылаются операции, база удалить не даёт
 * (`ON DELETE RESTRICT`) — ошибка переводится в понятный текст.
 */
export async function deleteCashFlowCategory(id: string): Promise<void> {
  const { client } = await assertPermission("cash_flow", "delete");
  const companyId = await getActiveCompanyId();

  const { error } = await client
    .from("cash_flow_categories")
    .delete()
    .eq("id", id)
    .eq("company_id", companyId);

  if (error) {
    throw cashFlowCategoryDeleteError(error);
  }
}
