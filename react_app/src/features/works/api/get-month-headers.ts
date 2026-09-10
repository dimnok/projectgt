import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import type { MonthHeader } from "@/features/works/types/work.types";
import { toMonthKey, toNumber } from "@/features/works/utils/work.utils";

type MonthSummaryRow = {
  month: string;
  works_count: number | string;
  total_amount_sum: number | string | null;
  own_total_amount_sum: number | string | null;
};

/**
 * Loads month headers for the works list.
 * Same RPC as Flutter: `get_months_summary`.
 */
export async function getMonthHeaders(openedBy?: string): Promise<MonthHeader[]> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const params: { p_company_id: string; p_opened_by?: string } = {
    p_company_id: companyId,
  };
  if (openedBy) {
    params.p_opened_by = openedBy;
  }

  const { data, error } = await client.rpc("get_months_summary", params);

  if (error) {
    throw new Error(error.message);
  }

  return ((data ?? []) as MonthSummaryRow[]).map((row) => ({
    month: toMonthKey(String(row.month)),
    worksCount: toNumber(row.works_count),
    totalAmount: toNumber(row.total_amount_sum),
    ownTotalAmount: toNumber(row.own_total_amount_sum),
  }));
}
