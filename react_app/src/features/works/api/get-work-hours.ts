import { getActiveCompanyId } from "@/lib/supabase/company";
import { getRequiredClient } from "@/lib/supabase/client";
import { fetchAllPages } from "@/lib/supabase/fetch-all-pages";
import type { WorkHour, WorkHoursRow } from "@/features/works/types/work.types";
import {
  formatPersonName,
  toNumber,
  unwrapRelation,
} from "@/features/works/utils/work.utils";

type WorkHoursTotalRow = {
  work_id: string;
  hours: number | string | null;
};

const WORK_HOUR_SELECT = [
  "id",
  "work_id",
  "employee_id",
  "hours",
  "comment",
  "employees!employee_id(last_name, first_name, middle_name, position, photo_url)",
].join(", ");

/**
 * Loads employee hours of a shift. Same table as Flutter `fetchWorkHours`.
 */
export async function getWorkHours(workId: string): Promise<WorkHour[]> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { data, error } = await client
    .from("work_hours")
    .select(WORK_HOUR_SELECT)
    .eq("work_id", workId)
    .eq("company_id", companyId)
    .order("created_at");

  if (error) {
    throw new Error(error.message);
  }

  const items = ((data ?? []) as unknown as WorkHoursRow[]).map((row) => {
    const employee = unwrapRelation(row.employees);
    const employeeName = formatPersonName({
      lastName: employee?.last_name,
      firstName: employee?.first_name,
      middleName: employee?.middle_name,
    });

    return {
      id: row.id,
      workId: row.work_id,
      employeeId: row.employee_id,
      employeeName: employeeName || "Сотрудник",
      employeePosition: employee?.position?.trim() ?? "",
      employeePhotoUrl: employee?.photo_url ?? null,
      hours: toNumber(row.hours),
      comment: row.comment,
    };
  });

  return items.sort(
    (a, b) =>
      a.employeeName.localeCompare(b.employeeName, "ru", { sensitivity: "base" }) ||
      a.id.localeCompare(b.id)
  );
}

/**
 * Sums hours per shift for a list of work ids. Used by the home chart plan line.
 */
export async function getWorkHoursTotalsByWorkIds(
  workIds: string[]
): Promise<Record<string, number>> {
  if (workIds.length === 0) {
    return {};
  }

  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  const totals: Record<string, number> = {};
  const chunkSize = 150;

  for (let index = 0; index < workIds.length; index += chunkSize) {
    const chunk = workIds.slice(index, index + chunkSize);
    // Страницы грузятся с `.range()`: иначе PostgREST обрежет ответ на 1000 строк
    // и у части смен часы (а значит и план) окажутся нулевыми.
    const rows = await fetchAllPages<WorkHoursTotalRow>((from, to) =>
      client
        .from("work_hours")
        .select("work_id, hours")
        .eq("company_id", companyId)
        .in("work_id", chunk)
        .order("id", { ascending: true })
        .range(from, to)
    );

    for (const row of rows) {
      totals[row.work_id] = (totals[row.work_id] ?? 0) + toNumber(row.hours);
    }
  }

  return totals;
}
