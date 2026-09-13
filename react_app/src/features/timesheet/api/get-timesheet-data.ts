import { getRequiredClient } from "@/lib/supabase/client";
import { getActiveCompanyId } from "@/lib/supabase/company";
import { EMPLOYEE_SELECT, mapEmployeeRow } from "@/features/employees/utils/employee.utils";
import type { Employee } from "@/features/employees/types/employee.types";
import { OBJECT_SELECT, mapObjectRow } from "@/features/objects/utils/object.utils";
import type { SiteObject } from "@/features/objects/types/object.types";
import type {
  TimesheetEntry,
  TimesheetObjectOption,
  TodayOpenShiftInfo,
} from "@/features/timesheet/types/timesheet.types";
import {
  getStartAndEndDates,
  getTodayDateString,
} from "@/features/timesheet/utils/timesheet-date";
import { getObjectColorHex } from "@/features/timesheet/utils/timesheet-palette";
import type { EmployeesRow, ObjectsRow } from "@/types/database.types";

const POSTGREST_PAGE_SIZE = 1000;

export type GetTimesheetDataParams = {
  year: number;
  month: number;
  selectedObjectIds?: string[];
  allowedObjectIds?: string[];
};

export type TimesheetDataResult = {
  entries: TimesheetEntry[];
  employees: Employee[];
  objects: SiteObject[];
  objectOptions: TimesheetObjectOption[];
  todayOpenShift: TodayOpenShiftInfo;
  periodContainsToday: boolean;
  startDate: string;
  endDate: string;
  daysCount: number;
};

async function fetchAllWorkHours(
  client: ReturnType<typeof getRequiredClient>,
  companyId: string,
  startDate: string,
  endDate: string,
  selectedObjectIds?: string[]
): Promise<TimesheetEntry[]> {
  const entries: TimesheetEntry[] = [];
  let offset = 0;
  let hasMore = true;

  while (hasMore) {
    let query = client
      .from("work_hours")
      .select(
        `
        id,
        work_id,
        employee_id,
        hours,
        comment,
        works!inner (
          date,
          object_id,
          status,
          company_id
        )
      `
      )
      .eq("company_id", companyId)
      .eq("works.status", "closed")
      .gte("works.date", startDate)
      .lte("works.date", endDate);

    if (selectedObjectIds && selectedObjectIds.length > 0) {
      query = query.in("works.object_id", selectedObjectIds);
    }

    const { data, error } = await query
      .order("id", { ascending: true })
      .range(offset, offset + POSTGREST_PAGE_SIZE - 1);

    if (error) {
      throw new Error(`Ошибка загрузки часов смен: ${error.message}`);
    }

    const batch = data ?? [];
    for (const row of batch) {
      const rawWork = row.works as unknown as {
        date?: string;
        object_id?: string;
      };
      const date = rawWork?.date;
      const objectId = rawWork?.object_id;
      const employeeId = row.employee_id;
      const hours = Number(row.hours) || 0;

      if (!date || !objectId || !employeeId) continue;

      entries.push({
        id: row.id,
        workId: row.work_id,
        employeeId,
        hours,
        comment: row.comment,
        date,
        objectId,
        isManualEntry: false,
      });
    }

    if (batch.length < POSTGREST_PAGE_SIZE) {
      hasMore = false;
    } else {
      offset += POSTGREST_PAGE_SIZE;
    }
  }

  return entries;
}

async function fetchAllAttendance(
  client: ReturnType<typeof getRequiredClient>,
  companyId: string,
  startDate: string,
  endDate: string,
  selectedObjectIds?: string[]
): Promise<TimesheetEntry[]> {
  const entries: TimesheetEntry[] = [];
  let offset = 0;
  let hasMore = true;

  while (hasMore) {
    let query = client
      .from("employee_attendance")
      .select("id, employee_id, object_id, date, hours, comment")
      .eq("company_id", companyId)
      .gte("date", startDate)
      .lte("date", endDate);

    if (selectedObjectIds && selectedObjectIds.length > 0) {
      query = query.in("object_id", selectedObjectIds);
    }

    const { data, error } = await query
      .order("id", { ascending: true })
      .range(offset, offset + POSTGREST_PAGE_SIZE - 1);

    if (error) {
      throw new Error(`Ошибка загрузки посещаемости: ${error.message}`);
    }

    const batch = data ?? [];
    for (const row of batch) {
      const date = row.date;
      const objectId = row.object_id;
      const employeeId = row.employee_id;
      const hours = Number(row.hours) || 0;

      if (!date || !objectId || !employeeId) continue;

      entries.push({
        id: row.id,
        workId: row.id,
        employeeId,
        hours,
        comment: row.comment,
        date,
        objectId,
        isManualEntry: true,
      });
    }

    if (batch.length < POSTGREST_PAGE_SIZE) {
      hasMore = false;
    } else {
      offset += POSTGREST_PAGE_SIZE;
    }
  }

  return entries;
}

export async function getTimesheetData({
  year,
  month,
  selectedObjectIds,
  allowedObjectIds,
}: GetTimesheetDataParams): Promise<TimesheetDataResult> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  if (!companyId) {
    throw new Error("Не выбрана активная компания");
  }

  const { startDate, endDate, daysCount } = getStartAndEndDates(year, month);
  const todayStr = getTodayDateString();
  const periodContainsToday = todayStr >= startDate && todayStr <= endDate;

  // If user is restricted to specific objects and has none assigned, return empty result
  if (allowedObjectIds && allowedObjectIds.length === 0) {
    return {
      entries: [],
      employees: [],
      objects: [],
      objectOptions: [],
      todayOpenShift: {
        employeeIds: new Set(),
        hintByEmployeeId: new Map(),
        objectIdsByEmployeeId: new Map(),
      },
      periodContainsToday,
      startDate,
      endDate,
      daysCount,
    };
  }

  // Determine effective object filter:
  // If user picked specific object(s) in filter:
  //   - if allowedObjectIds is set, restrict to intersection
  //   - otherwise use selectedObjectIds as-is
  // If no object filter is selected ("Все объекты"):
  //   - if allowedObjectIds is set, restrict query to allowedObjectIds!
  //   - otherwise undefined (all objects in company)
  let effectiveObjectIds: string[] | undefined;
  if (selectedObjectIds && selectedObjectIds.length > 0) {
    if (allowedObjectIds) {
      const allowedSet = new Set(allowedObjectIds);
      effectiveObjectIds = selectedObjectIds.filter((id) => allowedSet.has(id));
    } else {
      effectiveObjectIds = selectedObjectIds;
    }
  } else if (allowedObjectIds) {
    effectiveObjectIds = allowedObjectIds;
  }

  let objectsQuery = client
    .from("objects")
    .select(OBJECT_SELECT)
    .eq("company_id", companyId)
    .order("name");

  if (allowedObjectIds && allowedObjectIds.length > 0) {
    objectsQuery = objectsQuery.in("id", allowedObjectIds);
  }

  let todayWorksQuery = periodContainsToday
    ? client
        .from("works")
        .select("id, object_id, objects(name), work_hours(employee_id)")
        .eq("company_id", companyId)
        .eq("date", todayStr)
        .eq("status", "open")
    : null;

  if (todayWorksQuery && effectiveObjectIds && effectiveObjectIds.length > 0) {
    todayWorksQuery = todayWorksQuery.in("object_id", effectiveObjectIds);
  }

  // Execute all network requests in parallel
  const [
    employeesRes,
    objectsRes,
    todayOpenWorksRes,
    workHoursEntries,
    attendanceEntries,
  ] = await Promise.all([
    client
      .from("employees")
      .select(EMPLOYEE_SELECT)
      .eq("company_id", companyId)
      .order("last_name"),
    objectsQuery,
    todayWorksQuery
      ? todayWorksQuery
      : Promise.resolve({ data: [], error: null }),
    fetchAllWorkHours(client, companyId, startDate, endDate, effectiveObjectIds),
    fetchAllAttendance(client, companyId, startDate, endDate, effectiveObjectIds),
  ]);

  if (employeesRes.error) {
    throw new Error(`Ошибка загрузки сотрудников: ${employeesRes.error.message}`);
  }
  if (objectsRes.error) {
    throw new Error(`Ошибка загрузки объектов: ${objectsRes.error.message}`);
  }

  const allEntries = [...workHoursEntries, ...attendanceEntries];

  let employees: Employee[] = (
    (employeesRes.data ?? []) as unknown as EmployeesRow[]
  ).map((row) => mapEmployeeRow(row, null));

  if (allowedObjectIds && allowedObjectIds.length > 0) {
    const allowedSet = new Set(allowedObjectIds);
    const employeesWithHours = new Set(allEntries.map((e) => e.employeeId));
    employees = employees.filter(
      (emp) =>
        emp.objectIds.some((id) => allowedSet.has(id)) ||
        employeesWithHours.has(emp.id)
    );
  }

  const objects: SiteObject[] = (
    (objectsRes.data ?? []) as ObjectsRow[]
  ).map(mapObjectRow);

  const objectNameById = new Map<string, string>();
  for (const obj of objects) {
    objectNameById.set(obj.id, obj.name);
  }

  // Today's open shift index
  const todayEmployeeIds = new Set<string>();
  const todayHintByEmployee = new Map<string, string>();
  const todayObjectIdsByEmployee = new Map<string, Set<string>>();

  if (periodContainsToday && todayOpenWorksRes.data) {
    for (const work of todayOpenWorksRes.data as unknown as Array<{
      object_id: string;
      objects?: { name: string } | null;
      work_hours?: Array<{ employee_id: string }> | null;
    }>) {
      const objId = work.object_id;
      const objName =
        work.objects?.name ?? objectNameById.get(objId) ?? "Объект";
      const hours = work.work_hours ?? [];

      for (const h of hours) {
        if (!h.employee_id) continue;
        const empId = h.employee_id;
        todayEmployeeIds.add(empId);

        let set = todayObjectIdsByEmployee.get(empId);
        if (!set) {
          set = new Set<string>();
          todayObjectIdsByEmployee.set(empId, set);
        }
        set.add(objId);

        const currentHint = todayHintByEmployee.get(empId);
        if (!currentHint) {
          todayHintByEmployee.set(empId, `В открытой смене: ${objName}`);
        } else if (!currentHint.includes(objName)) {
          todayHintByEmployee.set(empId, `${currentHint}, ${objName}`);
        }
      }
    }
  }

  const todayOpenShift: TodayOpenShiftInfo = {
    employeeIds: todayEmployeeIds,
    hintByEmployeeId: todayHintByEmployee,
    objectIdsByEmployeeId: todayObjectIdsByEmployee,
  };

  // Object options with palette
  const objectOptions: TimesheetObjectOption[] = objects.map((obj, index) => ({
    id: obj.id,
    name: obj.name,
    colorHex: getObjectColorHex(index),
  }));

  return {
    entries: allEntries,
    employees,
    objects,
    objectOptions,
    todayOpenShift,
    periodContainsToday,
    startDate,
    endDate,
    daysCount,
  };
}
