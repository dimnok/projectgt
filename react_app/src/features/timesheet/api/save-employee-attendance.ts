import { getRequiredClient } from "@/lib/supabase/client";
import { getActiveCompanyId } from "@/lib/supabase/company";
import { getStartAndEndDates } from "@/features/timesheet/utils/timesheet-date";

export type AttendanceBatchRow = {
  date: string; // YYYY-MM-DD
  hours: number;
  comment?: string | null;
  attendanceType?: string;
};

export type EmployeeAttendanceDetails = {
  manualRecordsByObjectId: Map<string, Map<string, number>>; // objectId -> date -> hours
  shiftHoursByDate: Map<string, number>; // date -> hours
  initialObjectId: string | null;
};

export async function getEmployeeAttendanceData({
  employeeId,
  year,
  month,
}: {
  employeeId: string;
  year: number;
  month: number;
}): Promise<EmployeeAttendanceDetails> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  if (!companyId) {
    throw new Error("Не выбрана активная компания");
  }

  const { startDate, endDate } = getStartAndEndDates(year, month);

  // 1. Fetch manual attendance
  const { data: attendanceData, error: attendanceError } = await client
    .from("employee_attendance")
    .select("id, date, hours, object_id, comment")
    .eq("company_id", companyId)
    .eq("employee_id", employeeId)
    .gte("date", startDate)
    .lte("date", endDate);

  if (attendanceError) {
    throw new Error(`Ошибка загрузки посещаемости: ${attendanceError.message}`);
  }

  // 2. Fetch shift hours (work_hours from closed works)
  const { data: workHoursData, error: workHoursError } = await client
    .from("work_hours")
    .select("id, hours, works!inner(date, status)")
    .eq("company_id", companyId)
    .eq("employee_id", employeeId)
    .eq("works.status", "closed")
    .gte("works.date", startDate)
    .lte("works.date", endDate);

  if (workHoursError) {
    throw new Error(`Ошибка загрузки сменных часов: ${workHoursError.message}`);
  }

  const manualRecordsByObjectId = new Map<string, Map<string, number>>();
  let firstObjectId: string | null = null;

  for (const row of attendanceData ?? []) {
    const objId = row.object_id;
    const date = row.date;
    const hours = Number(row.hours) || 0;
    if (!objId || !date) continue;

    if (!firstObjectId) {
      firstObjectId = objId;
    }

    let map = manualRecordsByObjectId.get(objId);
    if (!map) {
      map = new Map<string, number>();
      manualRecordsByObjectId.set(objId, map);
    }
    map.set(date, hours);
  }

  const shiftHoursByDate = new Map<string, number>();
  for (const row of workHoursData ?? []) {
    const rawWork = row.works as unknown as { date: string };
    const date = rawWork?.date;
    const hours = Number(row.hours) || 0;
    if (!date) continue;
    const prev = shiftHoursByDate.get(date) ?? 0;
    shiftHoursByDate.set(date, prev + hours);
  }

  return {
    manualRecordsByObjectId,
    shiftHoursByDate,
    initialObjectId: firstObjectId,
  };
}

export async function saveEmployeeAttendanceBatch({
  employeeId,
  objectId,
  rows,
}: {
  employeeId: string;
  objectId: string;
  rows: AttendanceBatchRow[];
}): Promise<void> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  if (!companyId) {
    throw new Error("Не выбрана активная компания");
  }

  if (rows.length === 0) return;

  const payload = rows.map((r) => ({
    company_id: companyId,
    employee_id: employeeId,
    object_id: objectId,
    date: r.date,
    hours: r.hours,
    attendance_type: r.attendanceType?.trim() || "work",
    comment: r.comment ?? null,
  }));

  const { error } = await client.rpc("upsert_employee_attendance_batch", {
    p_rows: payload,
  });

  if (error) {
    throw new Error(`Ошибка сохранения табеля: ${error.message}`);
  }
}
