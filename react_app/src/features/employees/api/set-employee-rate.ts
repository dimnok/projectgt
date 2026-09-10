import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import type { EmployeeRateDraft } from "@/features/employees/types/employee.types";
import { findOverlappingEmployeeRates } from "@/features/employees/api/get-employee-rates";
import {
  overlapActionForRate,
  shiftIsoDate,
} from "@/features/employees/utils/employee-pay.utils";

/**
 * Sets a new hourly rate the same way as the app:
 * overlapping records are replaced, closed a day earlier, or deleted,
 * then a new open rate is inserted.
 */
export async function setEmployeeRate(
  employeeId: string,
  draft: EmployeeRateDraft
): Promise<void> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  const validFrom = draft.validFrom;
  const dayBefore = shiftIsoDate(validFrom, -1);
  const overlapping = await findOverlappingEmployeeRates(employeeId, validFrom);

  for (const rate of overlapping) {
    const action = overlapActionForRate(rate.validFrom, validFrom);
    if (action === "close") {
      const { error } = await client
        .from("employee_rates")
        .update({ valid_to: dayBefore })
        .eq("id", rate.id)
        .eq("company_id", companyId);
      if (error) {
        throw new Error(error.message);
      }
      continue;
    }

    const { error } = await client
      .from("employee_rates")
      .delete()
      .eq("id", rate.id)
      .eq("company_id", companyId);
    if (error) {
      throw new Error(error.message);
    }
  }

  const { error } = await client.from("employee_rates").insert({
    employee_id: employeeId,
    company_id: companyId,
    hourly_rate: draft.hourlyRate,
    valid_from: validFrom,
  });

  if (error) {
    throw new Error(error.message);
  }
}
