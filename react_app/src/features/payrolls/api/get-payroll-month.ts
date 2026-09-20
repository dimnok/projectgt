import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import type { PayrollMonthRow } from "@/features/payrolls/types/payroll.types";
import { toPayrollNumber } from "@/features/payrolls/utils/payroll.utils";

type RpcPayrollMonthRow = {
  employee_id?: unknown;
  full_name?: unknown;
  total_hours?: unknown;
  base_salary?: unknown;
  business_trip_total?: unknown;
  bonuses_total?: unknown;
  penalties_total?: unknown;
  net_salary?: unknown;
  current_hourly_rate?: unknown;
};

type GetPayrollMonthParams = {
  year: number;
  month: number;
  selectedObjectIds?: string[];
};

/**
 * Ведомость за месяц: RPC `calculate_payroll_for_month`.
 * Без выбранных объектов `p_object_ids` не передаётся — считаются все объекты.
 */
export async function getPayrollMonth({
  year,
  month,
  selectedObjectIds,
}: GetPayrollMonthParams): Promise<PayrollMonthRow[]> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client.rpc("calculate_payroll_for_month", {
    p_year: year,
    p_month: month,
    p_object_ids:
      selectedObjectIds && selectedObjectIds.length > 0
        ? selectedObjectIds
        : null,
    p_company_id: companyId,
  });

  if (error) {
    throw new Error(error.message);
  }

  return ((data ?? []) as unknown as RpcPayrollMonthRow[]).map((row) => ({
    employeeId: String(row.employee_id ?? ""),
    fullName: String(row.full_name ?? ""),
    totalHours: toPayrollNumber(row.total_hours),
    baseSalary: toPayrollNumber(row.base_salary),
    businessTripTotal: toPayrollNumber(row.business_trip_total),
    bonusesTotal: toPayrollNumber(row.bonuses_total),
    penaltiesTotal: toPayrollNumber(row.penalties_total),
    netSalary: toPayrollNumber(row.net_salary),
    currentHourlyRate: toPayrollNumber(row.current_hourly_rate),
  }));
}
