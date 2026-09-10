import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import {
  EMPLOYEE_SELECT,
  emptyToNull,
  mapEmployeeRow,
  phoneForStorage,
  todayDateInput,
} from "@/features/employees/utils/employee.utils";
import type {
  Employee,
  EmployeeCreateDraft,
} from "@/features/employees/types/employee.types";
import type { EmployeesRow } from "@/types/database.types";
import { createId } from "@/lib/utils";

/**
 * Creates an employee. Defaults match the app: status «работает»,
 * employment type «неофициально», hire date today, counted in timesheet.
 */
export async function createEmployee(
  draft: EmployeeCreateDraft
): Promise<Employee> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  const now = new Date().toISOString();

  const { data, error } = await client
    .from("employees")
    .insert({
      id: createId(),
      company_id: companyId,
      last_name: draft.lastName.trim(),
      first_name: draft.firstName.trim(),
      middle_name: emptyToNull(draft.middleName),
      phone: phoneForStorage(draft.phone),
      object_ids: draft.objectIds,
      status: "working",
      employment_type: "unofficial",
      employment_date: todayDateInput(),
      include_in_timesheet: true,
      created_at: now,
      updated_at: now,
    })
    .select(EMPLOYEE_SELECT)
    .maybeSingle();

  if (error) {
    throw new Error(error.message);
  }

  if (!data) {
    throw new Error("Ошибка создания сотрудника");
  }

  return mapEmployeeRow(data as unknown as EmployeesRow);
}
