import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import {
  EMPLOYEE_SELECT,
  dateForStorage,
  digitsOnly,
  emptyToNull,
  mapEmployeeRow,
  phoneForStorage,
} from "@/features/employees/utils/employee.utils";
import type { Employee, EmployeeDraft } from "@/features/employees/types/employee.types";
import type { EmployeesRow } from "@/types/database.types";

function taxDigits(value: string): string | null {
  const digits = digitsOnly(value);
  return digits ? digits : null;
}

/**
 * Updates an employee card. Does not touch photo, rates, or `can_be_responsible`.
 */
export async function updateEmployee(
  employee: Employee,
  draft: EmployeeDraft
): Promise<Employee> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client
    .from("employees")
    .update({
      last_name: draft.lastName.trim(),
      first_name: draft.firstName.trim(),
      middle_name: emptyToNull(draft.middleName),
      birth_date: dateForStorage(draft.birthDate),
      birth_place: emptyToNull(draft.birthPlace),
      citizenship: emptyToNull(draft.citizenship),
      phone: phoneForStorage(draft.phone),
      clothing_size: emptyToNull(draft.clothingSize),
      shoe_size: emptyToNull(draft.shoeSize),
      height: emptyToNull(draft.height),
      employment_date: dateForStorage(draft.employmentDate),
      employment_type: draft.employmentType,
      position: emptyToNull(draft.position),
      status: draft.status,
      include_in_timesheet: draft.includeInTimesheet,
      object_ids: draft.objectIds,
      passport_series: emptyToNull(draft.passportSeries),
      passport_number: emptyToNull(draft.passportNumber),
      passport_issued_by: emptyToNull(draft.passportIssuedBy),
      passport_issue_date: dateForStorage(draft.passportIssueDate),
      passport_department_code: emptyToNull(draft.passportDepartmentCode),
      registration_address: emptyToNull(draft.registrationAddress),
      inn: taxDigits(draft.inn),
      snils: taxDigits(draft.snils),
      kig: emptyToNull(draft.kig),
      patent_number: emptyToNull(draft.patentNumber),
      updated_at: new Date().toISOString(),
    })
    .eq("id", employee.id)
    .eq("company_id", companyId)
    .select(EMPLOYEE_SELECT)
    .maybeSingle();

  if (error) {
    throw new Error(error.message);
  }

  if (!data) {
    throw new Error("Сотрудник не найден для обновления");
  }

  return mapEmployeeRow(
    data as unknown as EmployeesRow,
    employee.currentHourlyRate
  );
}
