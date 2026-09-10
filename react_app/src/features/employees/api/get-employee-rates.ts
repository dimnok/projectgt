import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import type { EmployeeRate } from "@/features/employees/types/employee.types";
import { mapEmployeeRateRow } from "@/features/employees/utils/employee-pay.utils";
import type { EmployeeRatesRow } from "@/types/database.types";

const RATE_SELECT = "id, employee_id, hourly_rate, valid_from, valid_to";

/**
 * Loads all hourly rates of an employee, newest start date first.
 * Same query as the app: company + employee, order by valid_from desc.
 */
export async function getEmployeeRates(
  employeeId: string
): Promise<EmployeeRate[]> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client
    .from("employee_rates")
    .select(RATE_SELECT)
    .eq("employee_id", employeeId)
    .eq("company_id", companyId)
    .order("valid_from", { ascending: false });

  if (error) {
    throw new Error(error.message);
  }

  return ((data ?? []) as unknown as EmployeeRatesRow[]).map(mapEmployeeRateRow);
}

/**
 * Rates whose period intersects [validFrom, +∞).
 * Same filter as the app: valid_to is empty or valid_to >= validFrom.
 */
export async function findOverlappingEmployeeRates(
  employeeId: string,
  validFrom: string
): Promise<EmployeeRate[]> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client
    .from("employee_rates")
    .select(RATE_SELECT)
    .eq("employee_id", employeeId)
    .eq("company_id", companyId)
    .or(`valid_to.is.null,valid_to.gte.${validFrom}`)
    .order("valid_from", { ascending: true });

  if (error) {
    throw new Error(error.message);
  }

  return ((data ?? []) as unknown as EmployeeRatesRow[]).map(mapEmployeeRateRow);
}
