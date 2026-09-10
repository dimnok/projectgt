import { getRequiredClient } from "@/lib/supabase/client";
import { getActiveCompanyId } from "@/lib/supabase/company";

export type TimesheetDayObjectSlice = {
  objectId: string;
  hours: number;
};

export type TimesheetDaySummary = {
  date: string; // YYYY-MM-DD
  totalHours: number;
  shiftHours: number;
  manualHours: number;
  objectSlices: TimesheetDayObjectSlice[];
  objectIds: string[];
  comments: { objectId: string; text: string }[];
};

export type EmployeeTimesheetMonth = {
  totalHours: number;
  totalDays: number;
  days: TimesheetDaySummary[];
  objectTotals: { objectId: string; hours: number }[];
};

export async function getEmployeeTimesheetMonth({
  employeeId,
  year,
  month, // 1-12
}: {
  employeeId: string;
  year: number;
  month: number;
}): Promise<EmployeeTimesheetMonth> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const startDateStr = `${year}-${String(month).padStart(2, "0")}-01`;
  const lastDay = new Date(year, month, 0).getDate();
  const endDateStr = `${year}-${String(month).padStart(2, "0")}-${String(lastDay).padStart(2, "0")}`;

  // 1. Fetch manual attendance
  const { data: attendanceData, error: attendanceError } = await client
    .from("employee_attendance")
    .select("id, date, hours, object_id, comment")
    .eq("company_id", companyId)
    .eq("employee_id", employeeId)
    .gte("date", startDateStr)
    .lte("date", endDateStr);

  if (attendanceError) {
    throw new Error(`Ошибка загрузки посещаемости: ${attendanceError.message}`);
  }

  // 2. Fetch shift hours (work_hours joined with closed works)
  const { data: workHoursData, error: workHoursError } = await client
    .from("work_hours")
    .select("id, hours, comment, works!inner(id, date, object_id, status)")
    .eq("company_id", companyId)
    .eq("employee_id", employeeId)
    .eq("works.status", "closed")
    .gte("works.date", startDateStr)
    .lte("works.date", endDateStr);

  if (workHoursError) {
    throw new Error(`Ошибка загрузки смен: ${workHoursError.message}`);
  }

  // Aggregate by day
  const daysMap = new Map<string, TimesheetDaySummary>();
  const objectTotalsMap = new Map<string, number>();

  function getDay(dateStr: string) {
    let day = daysMap.get(dateStr);
    if (!day) {
      day = {
        date: dateStr,
        totalHours: 0,
        shiftHours: 0,
        manualHours: 0,
        objectSlices: [],
        objectIds: [],
        comments: [],
      };
      daysMap.set(dateStr, day);
    }
    return day;
  }

  function addHoursToObject(objId: string | null | undefined, hours: number) {
    if (!objId || hours <= 0) return;
    objectTotalsMap.set(objId, (objectTotalsMap.get(objId) ?? 0) + hours);
  }

  function addSliceToDay(day: TimesheetDaySummary, objId: string | null | undefined, hours: number) {
    if (!objId || hours <= 0) return;
    let slice = day.objectSlices.find((s) => s.objectId === objId);
    if (!slice) {
      slice = { objectId: objId, hours: 0 };
      day.objectSlices.push(slice);
    }
    slice.hours += hours;
  }

  // Process shifts
  for (const row of workHoursData || []) {
    const rawWork = row.works as unknown as { date: string; object_id: string };
    const date = rawWork?.date;
    const objId = rawWork?.object_id;
    const hours = Number(row.hours) || 0;
    if (!date || hours <= 0) continue;

    const day = getDay(date);
    day.shiftHours += hours;
    day.totalHours += hours;
    if (objId && !day.objectIds.includes(objId)) {
      day.objectIds.push(objId);
    }
    addSliceToDay(day, objId, hours);
    addHoursToObject(objId, hours);
    if (row.comment?.trim()) {
      day.comments.push({ objectId: objId || "", text: row.comment.trim() });
    }
  }

  // Process manual attendance
  for (const row of attendanceData || []) {
    const date = row.date;
    const objId = row.object_id;
    const hours = Number(row.hours) || 0;
    if (!date || hours <= 0) continue;

    const day = getDay(date);
    day.manualHours += hours;
    day.totalHours += hours;
    if (objId && !day.objectIds.includes(objId)) {
      day.objectIds.push(objId);
    }
    addSliceToDay(day, objId, hours);
    addHoursToObject(objId, hours);
    if (row.comment?.trim()) {
      day.comments.push({ objectId: objId || "", text: row.comment.trim() });
    }
  }

  const days = Array.from(daysMap.values()).sort((a, b) =>
    a.date.localeCompare(b.date)
  );

  let totalHours = 0;
  for (const d of days) {
    totalHours += d.totalHours;
  }

  const objectTotals = Array.from(objectTotalsMap.entries())
    .map(([objectId, hours]) => ({ objectId, hours }))
    .sort((a, b) => b.hours - a.hours);

  return {
    totalHours,
    totalDays: days.length,
    days,
    objectTotals,
  };
}
