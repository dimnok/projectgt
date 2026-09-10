import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import { createId } from "@/lib/utils";
import type {
  EmployeeTripRate,
  EmployeeTripRateDraft,
} from "@/features/employees/types/employee.types";
import {
  mapTripRateRow,
  sortTripRates,
} from "@/features/employees/utils/employee-pay.utils";
import type { BusinessTripRatesRow } from "@/types/database.types";

const TRIP_SELECT =
  "id, company_id, object_id, employee_id, rate, minimum_hours, valid_from, valid_to, created_at";

/**
 * Personal trip rates of the employee.
 * Same result as the app: only rows with this employee_id.
 */
export async function getEmployeeTripRates(
  employeeId: string
): Promise<EmployeeTripRate[]> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client
    .from("business_trip_rates")
    .select(TRIP_SELECT)
    .eq("company_id", companyId)
    .eq("employee_id", employeeId);

  if (error) {
    throw new Error(error.message);
  }

  return sortTripRates(
    ((data ?? []) as unknown as BusinessTripRatesRow[]).map(mapTripRateRow)
  );
}

async function hasOverlappingTripPeriods(params: {
  objectId: string;
  employeeId: string;
  validFrom: string;
  validTo: string | null;
  excludeId?: string;
}): Promise<boolean> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  let query = client
    .from("business_trip_rates")
    .select("id")
    .eq("object_id", params.objectId)
    .eq("company_id", companyId)
    .eq("employee_id", params.employeeId);

  if (params.excludeId) {
    query = query.neq("id", params.excludeId);
  }

  query = params.validTo
    ? query.or(
        `and(valid_from.lte.${params.validTo},or(valid_to.is.null,valid_to.gte.${params.validFrom}))`
      )
    : query.or(`valid_to.is.null,valid_to.gte.${params.validFrom}`);

  const { data, error } = await query.limit(1);
  if (error) {
    throw new Error(error.message);
  }
  return (data ?? []).length > 0;
}

/**
 * Creates a personal trip rate for the employee.
 * Client overlap check matches the app; the database also blocks overlaps.
 */
export async function createEmployeeTripRate(
  employeeId: string,
  draft: EmployeeTripRateDraft
): Promise<void> {
  const hasOverlap = await hasOverlappingTripPeriods({
    objectId: draft.objectId,
    employeeId,
    validFrom: draft.validFrom,
    validTo: draft.validTo,
  });
  if (hasOverlap) {
    throw new Error(
      "Период действия ставки пересекается с существующими ставками для данного объекта"
    );
  }

  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  const {
    data: { user },
  } = await client.auth.getUser();

  const { error } = await client.from("business_trip_rates").insert({
    id: createId(),
    company_id: companyId,
    object_id: draft.objectId,
    employee_id: employeeId,
    rate: draft.rate,
    minimum_hours: draft.minimumHours,
    valid_from: draft.validFrom,
    valid_to: draft.validTo,
    created_by: user?.id ?? null,
  });

  if (error) {
    throw new Error(error.message);
  }
}

/**
 * Updates an existing personal trip rate.
 */
export async function updateEmployeeTripRate(
  employeeId: string,
  rateId: string,
  draft: EmployeeTripRateDraft
): Promise<void> {
  const hasOverlap = await hasOverlappingTripPeriods({
    objectId: draft.objectId,
    employeeId,
    validFrom: draft.validFrom,
    validTo: draft.validTo,
    excludeId: rateId,
  });
  if (hasOverlap) {
    throw new Error(
      "Период действия ставки пересекается с существующими ставками для данного объекта"
    );
  }

  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { error } = await client
    .from("business_trip_rates")
    .update({
      object_id: draft.objectId,
      employee_id: employeeId,
      rate: draft.rate,
      minimum_hours: draft.minimumHours,
      valid_from: draft.validFrom,
      valid_to: draft.validTo,
    })
    .eq("id", rateId)
    .eq("company_id", companyId);

  if (error) {
    throw new Error(error.message);
  }
}
