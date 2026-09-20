import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import type { PayrollEmployeeTotals } from "@/features/payrolls/types/payroll.types";
import { toPayrollNumber } from "@/features/payrolls/utils/payroll.utils";

type RpcTotalsRow = {
  base_total?: unknown;
  trip_total?: unknown;
  bonus_total?: unknown;
  penalty_total?: unknown;
  payout_total?: unknown;
  earned_total?: unknown;
  balance?: unknown;
};

/**
 * Итоги по сотруднику за всё время: RPC `get_employee_payroll_totals`.
 * Логика ставки и суточных совпадает с расчётом баланса.
 */
export async function getEmployeePayrollTotals(
  employeeId: string
): Promise<PayrollEmployeeTotals> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client.rpc("get_employee_payroll_totals", {
    p_employee_id: employeeId,
    p_company_id: companyId,
  });

  if (error) {
    throw new Error(error.message);
  }

  const row = ((data ?? []) as unknown as RpcTotalsRow[])[0] ?? {};
  return {
    baseTotal: toPayrollNumber(row.base_total),
    tripTotal: toPayrollNumber(row.trip_total),
    bonusTotal: toPayrollNumber(row.bonus_total),
    penaltyTotal: toPayrollNumber(row.penalty_total),
    payoutTotal: toPayrollNumber(row.payout_total),
    earnedTotal: toPayrollNumber(row.earned_total),
    balance: toPayrollNumber(row.balance),
  };
}
