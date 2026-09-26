import { assertPermission } from "@/features/roles/api/assert-permission";
import { getActiveCompanyId } from "@/lib/supabase/company";
import {
  cashFlowDraftToPayload,
  cashFlowWriteError,
} from "@/features/cash-flow/utils/cash-flow.utils";
import type { CashFlowDraft } from "@/features/cash-flow/types/cash-flow.types";

/** Сохраняет правки операции ДДС. */
export async function updateCashFlowTransaction(
  id: string,
  draft: CashFlowDraft
): Promise<void> {
  const { client } = await assertPermission("cash_flow", "update");
  const companyId = await getActiveCompanyId();

  const { error } = await client
    .from("cash_flow")
    .update(cashFlowDraftToPayload(draft))
    .eq("id", id)
    .eq("company_id", companyId);

  if (error) {
    throw cashFlowWriteError(error);
  }
}
