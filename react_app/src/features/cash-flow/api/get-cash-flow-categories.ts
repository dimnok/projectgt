import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import {
  CASH_FLOW_CATEGORY_SELECT,
  mapCashFlowCategoryRow,
} from "@/features/cash-flow/utils/cash-flow.utils";
import type { CashFlowCategory } from "@/features/cash-flow/types/cash-flow.types";
import type { CashFlowCategoryRow } from "@/types/database.types";

/** Статьи ДДС активной компании, по алфавиту. */
export async function getCashFlowCategories(): Promise<CashFlowCategory[]> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client
    .from("cash_flow_categories")
    .select(CASH_FLOW_CATEGORY_SELECT)
    .eq("company_id", companyId)
    .order("name");

  if (error) {
    throw new Error(error.message);
  }

  return ((data ?? []) as unknown as CashFlowCategoryRow[]).map(
    mapCashFlowCategoryRow
  );
}
