import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import { fetchAllPages } from "@/lib/supabase/fetch-all-pages";
import type {
  PayrollPeriod,
  PayrollPayoutItem,
} from "@/features/payrolls/types/payroll.types";
import {
  embeddedEmployeeName,
  embeddedProfileName,
  getPeriodBounds,
  payrollDateOnly,
  toPayrollNumber,
} from "@/features/payrolls/utils/payroll.utils";

const PAYOUT_SELECT = `
  id,
  payout_date,
  amount,
  method,
  type,
  comment,
  employee_id,
  updated_at,
  employee:employees(last_name, first_name, middle_name),
  created_by_profile:profiles!created_by(short_name, full_name),
  updated_by_profile:profiles!updated_by(short_name, full_name)
`;

type EmbeddedEmployee = {
  last_name?: unknown;
  first_name?: unknown;
  middle_name?: unknown;
};

type EmbeddedProfile = {
  short_name?: unknown;
  full_name?: unknown;
};

type PayoutRow = {
  id: string;
  payout_date: unknown;
  amount: unknown;
  method: unknown;
  type: unknown;
  comment: unknown;
  employee_id: string;
  updated_at: unknown;
  employee: EmbeddedEmployee | null;
  created_by_profile: EmbeddedProfile | null;
  updated_by_profile: EmbeddedProfile | null;
};

type GetPayrollPayoutsParams = {
  period: PayrollPeriod;
  /** Только выплаты одного сотрудника — для истории по строке ФОТ. */
  employeeId?: string;
};

/**
 * Выплаты за период. Фильтра по объекту нет: у выплат не бывает объекта,
 * они относятся к сотруднику целиком.
 */
export async function getPayrollPayouts({
  period,
  employeeId,
}: GetPayrollPayoutsParams): Promise<PayrollPayoutItem[]> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  const { start, end } = getPeriodBounds(period);

  const rows = await fetchAllPages<PayoutRow>((from, to) => {
    let query = client
      .from("payroll_payout")
      .select(PAYOUT_SELECT)
      .eq("company_id", companyId);

    if (start) {
      query = query.gte("payout_date", start);
    }
    if (end) {
      query = query.lte("payout_date", end);
    }
    if (employeeId) {
      query = query.eq("employee_id", employeeId);
    }

    return query.order("id", { ascending: true }).range(from, to);
  });

  return rows.map((row) => ({
    id: String(row.id),
    date: payrollDateOnly(row.payout_date),
    employeeId: String(row.employee_id),
    employeeName: embeddedEmployeeName(row.employee),
    amount: toPayrollNumber(row.amount),
    method: typeof row.method === "string" ? row.method : "",
    type: typeof row.type === "string" ? row.type : "",
    comment: typeof row.comment === "string" ? row.comment : "",
    createdByName: embeddedProfileName(row.created_by_profile),
    updatedByName: embeddedProfileName(row.updated_by_profile),
    updatedAt: payrollDateOnly(row.updated_at),
  }));
}
