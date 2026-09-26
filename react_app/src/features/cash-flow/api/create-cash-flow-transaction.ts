import { assertPermission } from "@/features/roles/api/assert-permission";
import { getActiveCompanyId } from "@/lib/supabase/company";
import { createId } from "@/lib/utils";
import {
  cashFlowDraftToPayload,
  cashFlowWriteError,
} from "@/features/cash-flow/utils/cash-flow.utils";
import type { CashFlowDraft } from "@/features/cash-flow/types/cash-flow.types";

/**
 * Создаёт операцию ДДС в активной компании.
 *
 * Автора записи проставляет веб: у таблицы нет значения по умолчанию для
 * `created_by`. Права проверяются тем же способом, что в базе
 * (`check_permission`) — политики таблицы проверяют только компанию.
 */
export async function createCashFlowTransaction(
  draft: CashFlowDraft
): Promise<void> {
  const { client, userId } = await assertPermission("cash_flow", "create");
  const companyId = await getActiveCompanyId();

  const { error } = await client.from("cash_flow").insert({
    id: createId(),
    company_id: companyId,
    created_by: userId,
    ...cashFlowDraftToPayload(draft),
  });

  if (error) {
    throw cashFlowWriteError(error);
  }
}
