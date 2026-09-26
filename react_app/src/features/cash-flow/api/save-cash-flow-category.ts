import { assertPermission } from "@/features/roles/api/assert-permission";
import { getActiveCompanyId } from "@/lib/supabase/company";
import { createId } from "@/lib/utils";
import type { CashFlowType } from "@/features/cash-flow/types/cash-flow.types";

/** Данные статьи ДДС из формы. */
export type CashFlowCategoryDraft = {
  name: string;
  type: CashFlowType;
};

/**
 * Создаёт или переименовывает статью ДДС.
 *
 * Права проверяются тем же способом, что в базе (`check_permission`):
 * политики таблицы проверяют только принадлежность компании, поэтому право
 * «создание» / «изменение» подтверждает веб.
 */
export async function saveCashFlowCategory(
  draft: CashFlowCategoryDraft,
  categoryId?: string
): Promise<void> {
  const { client } = await assertPermission(
    "cash_flow",
    categoryId ? "update" : "create"
  );
  const companyId = await getActiveCompanyId();

  const payload = {
    name: draft.name.trim(),
    type: draft.type,
  };

  const { error } = categoryId
    ? await client
        .from("cash_flow_categories")
        .update(payload)
        .eq("id", categoryId)
        .eq("company_id", companyId)
    : await client
        .from("cash_flow_categories")
        .insert({ id: createId(), company_id: companyId, ...payload });

  if (error) {
    throw new Error(error.message);
  }
}
