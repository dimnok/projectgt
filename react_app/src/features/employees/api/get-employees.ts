import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import {
  EMPLOYEE_SELECT,
  mapEmployeeRow,
  mapRatesByEmployeeId,
} from "@/features/employees/utils/employee.utils";
import type { Employee } from "@/features/employees/types/employee.types";
import type { EmployeeRatesRow, EmployeesRow } from "@/types/database.types";

/**
 * Loads employees of the active company and attaches the current hourly rate.
 * Rate comes from `employee_rates` where `valid_to` is empty — same as the app.
 */
export async function getEmployees(): Promise<Employee[]> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const employeesResult = await client
    .from("employees")
    .select(EMPLOYEE_SELECT)
    .eq("company_id", companyId)
    .order("last_name");

  if (employeesResult.error) {
    throw new Error(employeesResult.error.message);
  }

  const rows = (employeesResult.data ?? []) as unknown as EmployeesRow[];
  const ratesResult = await client
    .from("employee_rates")
    .select("employee_id, hourly_rate")
    .eq("company_id", companyId)
    .is("valid_to", null);

  const ratesById = ratesResult.error
    ? new Map<string, number>()
    : mapRatesByEmployeeId(
        (ratesResult.data ?? []) as unknown as EmployeeRatesRow[]
      );

  return rows.map((row) => mapEmployeeRow(row, ratesById.get(row.id) ?? null));
}
