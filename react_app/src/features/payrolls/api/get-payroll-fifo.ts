import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import { fetchAllPages } from "@/lib/supabase/fetch-all-pages";
import type {
  PayrollFifoData,
  PayrollPayoutRow,
} from "@/features/payrolls/types/payroll.types";
import { buildFifoForYear } from "@/features/payrolls/utils/payroll-fifo";
import { toPayrollNumber } from "@/features/payrolls/utils/payroll.utils";

type RpcBalanceBeforeDateRow = {
  employee_id?: unknown;
  accruals_sum?: unknown;
};

type RpcNetSalaryRow = {
  employee_id?: unknown;
  net_salary?: unknown;
};

type PayoutRow = {
  id: string;
  employee_id: string;
  amount: number | string | null;
  payout_date: string;
};

async function fetchAllPayouts(
  client: ReturnType<typeof getRequiredClient>,
  companyId: string
): Promise<PayrollPayoutRow[]> {
  const rows = await fetchAllPages<PayoutRow>((from, to) =>
    client
      .from("payroll_payout")
      .select("id, employee_id, amount, payout_date")
      .eq("company_id", companyId)
      .order("payout_date", { ascending: true })
      .order("id", { ascending: true })
      .range(from, to)
  );

  return rows.map((row) => ({
    id: String(row.id),
    employeeId: String(row.employee_id),
    amount: toPayrollNumber(row.amount),
    payoutDate: String(row.payout_date),
  }));
}

/**
 * FIFO-распределение выплат по месяцам года.
 *
 * Начисления за 12 месяцев берутся без фильтра объектов — колонки «Выплаты»
 * и «Баланс» всегда сквозные по компании, как в приложении.
 */
export async function getPayrollFifo(
  year: number
): Promise<Map<string, PayrollFifoData>> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data: historyRows, error: historyError } = await client.rpc(
    "calculate_employee_balances_before_date",
    { p_before_date: `${year}-01-01T00:00:00.000Z`, p_company_id: companyId }
  );

  if (historyError) {
    throw new Error(historyError.message);
  }

  const accrualsBeforeYear = new Map<string, number>();
  for (const row of (historyRows ?? []) as unknown as RpcBalanceBeforeDateRow[]) {
    const employeeId = row.employee_id;
    if (typeof employeeId !== "string" || !employeeId) {
      continue;
    }
    accrualsBeforeYear.set(employeeId, toPayrollNumber(row.accruals_sum));
  }

  const allPayouts = await fetchAllPayouts(client, companyId);

  const monthResults = await Promise.all(
    Array.from({ length: 12 }, (_, index) => {
      const month = index + 1;
      return client
        .rpc("calculate_payroll_for_month", {
          p_year: year,
          p_month: month,
          p_company_id: companyId,
        })
        .then(({ data, error }) => {
          if (error) {
            throw new Error(error.message);
          }
          return {
            month,
            rows: (data ?? []) as unknown as RpcNetSalaryRow[],
          };
        });
    })
  );

  const netByEmployeeMonth = new Map<string, Map<number, number>>();
  for (const { month, rows } of monthResults) {
    for (const row of rows) {
      const employeeId = row.employee_id;
      if (typeof employeeId !== "string" || !employeeId) {
        continue;
      }
      let months = netByEmployeeMonth.get(employeeId);
      if (!months) {
        months = new Map<number, number>();
        netByEmployeeMonth.set(employeeId, months);
      }
      months.set(month, toPayrollNumber(row.net_salary));
    }
  }

  return buildFifoForYear(
    year,
    accrualsBeforeYear,
    allPayouts,
    netByEmployeeMonth
  );
}
