import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import { fetchAllPages } from "@/lib/supabase/fetch-all-pages";
import type {
  PayrollPeriod,
  PayrollTransactionItem,
  PayrollTransactionKind,
} from "@/features/payrolls/types/payroll.types";
import {
  embeddedEmployeeName,
  embeddedProfileName,
  getPeriodBounds,
  payrollDateOnly,
  toPayrollNumber,
} from "@/features/payrolls/utils/payroll.utils";

const TRANSACTION_SELECT = `
  id,
  date,
  amount,
  reason,
  employee_id,
  object_id,
  updated_at,
  employee:employees(last_name, first_name, middle_name),
  object:objects(name),
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

type TransactionRow = {
  id: string;
  date: unknown;
  amount: unknown;
  reason: unknown;
  employee_id: string;
  object_id: string | null;
  updated_at: unknown;
  employee: EmbeddedEmployee | null;
  object: { name?: unknown } | null;
  created_by_profile: EmbeddedProfile | null;
  updated_by_profile: EmbeddedProfile | null;
};

type GetPayrollTransactionsParams = {
  kind: PayrollTransactionKind;
  period: PayrollPeriod;
  selectedObjectIds?: string[];
  /** Только операции одного сотрудника — для истории по строке ФОТ. */
  employeeId?: string;
};

/**
 * Премии или удержания за период. У премий и удержаний одинаковые поля,
 * отличается только таблица — поэтому один запрос на оба вида операций.
 */
export async function getPayrollTransactions({
  kind,
  period,
  selectedObjectIds,
  employeeId,
}: GetPayrollTransactionsParams): Promise<PayrollTransactionItem[]> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  const { start, end } = getPeriodBounds(period);
  const table = kind === "bonus" ? "payroll_bonus" : "payroll_penalty";

  const rows = await fetchAllPages<TransactionRow>((from, to) => {
    let query = client
      .from(table)
      .select(TRANSACTION_SELECT)
      .eq("company_id", companyId);

    if (start) {
      query = query.gte("date", start);
    }
    if (end) {
      query = query.lte("date", end);
    }
    if (selectedObjectIds && selectedObjectIds.length > 0) {
      query = query.in("object_id", selectedObjectIds);
    }
    if (employeeId) {
      query = query.eq("employee_id", employeeId);
    }

    return query.order("id", { ascending: true }).range(from, to);
  });

  return rows.map((row) => ({
    id: String(row.id),
    date: payrollDateOnly(row.date),
    employeeId: String(row.employee_id),
    objectId: typeof row.object_id === "string" ? row.object_id : null,
    employeeName: embeddedEmployeeName(row.employee),
    amount: toPayrollNumber(row.amount),
    objectName:
      typeof row.object?.name === "string" ? row.object.name : "",
    note: typeof row.reason === "string" ? row.reason : "",
    createdByName: embeddedProfileName(row.created_by_profile),
    updatedByName: embeddedProfileName(row.updated_by_profile),
    updatedAt: payrollDateOnly(row.updated_at),
  }));
}
