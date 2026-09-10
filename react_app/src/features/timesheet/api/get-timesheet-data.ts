import { getRequiredClient } from "@/lib/supabase/client";
import { getActiveCompanyId } from "@/lib/supabase/company";
import {
  EMPLOYEE_SELECT,
  mapEmployeeRow,
  mapRatesByEmployeeId,
} from "@/features/employees/utils/employee.utils";
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
import { getObjectPaletteItem } from "@/features/timesheet/utils/timesheet-palette";
import type { EmployeeRatesRow, EmployeesRow, ObjectsRow } from "@/types/database.types";

const POSTGREST_PAGE_SIZE = 1000;

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

export async function getTimesheetData({
  year,
  month,
  selectedObjectIds,
}: {
  year: number;
  month: number;
  selectedObjectIds?: string[];
}): Promise<TimesheetDataResult> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();
  if (!companyId) {
    throw new Error("Не выбрана активная компания");
  }

  const { startDate, endDate, daysCount } = getStartAndEndDates(year, month);
  const todayStr = getTodayDateString();
  const periodContainsToday = todayStr >= startDate && todayStr <= endDate;

  // 1. Load employees, objects, and today's open shifts in parallel
  const [employeesRes, ratesRes, objectsRes, todayOpenWorksRes] =
    await Promise.all([
      client
        .from("employees")
        .select(EMPLOYEE_SELECT)
        .eq("company_id", companyId)
        .order("last_name"),
      client
        .from("employee_rates")
        .select("employee_id, hourly_rate")
        .eq("company_id", companyId)
        .is("valid_to", null),
      client
        .from("objects")
        .select(OBJECT_SELECT)
        .eq("company_id", companyId)
        .order("name"),
      periodContainsToday
        ? client
            .from("works")
            .select("id, object_id, objects(name), work_hours(employee_id)")
            .eq("company_id", companyId)
            .eq("date", todayStr)
            .eq("status", "open")
        : Promise.resolve({ data: [], error: null }),
    ]);

  if (employeesRes.error) {
    throw new Error(`Ошибка загрузки сотрудников: ${employeesRes.error.message}`);
  }
  if (objectsRes.error) {
    throw new Error(`Ошибка загрузки объектов: ${objectsRes.error.message}`);
  }

  const ratesMap = ratesRes.error
    ? new Map<string, number>()
    : mapRatesByEmployeeId(
        (ratesRes.data ?? []) as unknown as EmployeeRatesRow[]
      );

  const employees: Employee[] = ((employeesRes.data ?? []) as unknown as EmployeesRow[]).map(
    (row) => mapEmployeeRow(row, ratesMap.get(row.id) ?? null)
  );

  const objects: SiteObject[] = ((objectsRes.data ?? []) as ObjectsRow[]).map(
    mapObjectRow
  );

  const objectNameById = new Map<string, string>();
  for (const obj of objects) {
    objectNameById.set(obj.id, obj.name);
  }

  const employeeNameById = new Map<string, string>();
  const employeePositionById = new Map<string, string>();
  for (const emp of employees) {
    const fullName = [emp.lastName, emp.firstName, emp.middleName]
      .map((s) => s.trim())
      .filter(Boolean)
      .join(" ");
    employeeNameById.set(emp.id, fullName);
    if (emp.position.trim()) {
      employeePositionById.set(emp.id, emp.position.trim());
    }
  }

  // 2. Build today's open shift index
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
      const objName = work.objects?.name ?? objectNameById.get(objId) ?? "Объект";
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

  // 3. Fetch closed shift work_hours with pagination
  const workHoursEntries: TimesheetEntry[] = [];
  {
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
          created_at,
          updated_at,
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
        .order("created_at", { ascending: true })
        .order("id", { ascending: true })
        .range(offset, offset + POSTGREST_PAGE_SIZE - 1);

      if (error) {
        throw new Error(`Ошибка загрузки часов смен: ${error.message}`);
      }

      const batch = data ?? [];
      for (const row of batch) {
        const rawWork = row.works as unknown as {
          date: string;
          object_id: string;
        };
        const date = rawWork?.date;
        const objectId = rawWork?.object_id;
        const employeeId = row.employee_id;
        const hours = Number(row.hours) || 0;

        if (!date || !objectId || !employeeId) continue;

        workHoursEntries.push({
          id: row.id,
          workId: row.work_id,
          employeeId,
          hours,
          comment: row.comment,
          date,
          objectId,
          employeeName: employeeNameById.get(employeeId) ?? null,
          objectName: objectNameById.get(objectId) ?? null,
          employeePosition: employeePositionById.get(employeeId) ?? null,
          createdAt: row.created_at,
          updatedAt: row.updated_at,
          isManualEntry: false,
        });
      }

      if (batch.length < POSTGREST_PAGE_SIZE) {
        hasMore = false;
      } else {
        offset += POSTGREST_PAGE_SIZE;
      }
    }
  }

  // 4. Fetch manual attendance records with pagination
  const attendanceEntries: TimesheetEntry[] = [];
  {
    let offset = 0;
    let hasMore = true;

    while (hasMore) {
      let query = client
        .from("employee_attendance")
        .select(
          `
          id,
          employee_id,
          object_id,
          date,
          hours,
          comment,
          attendance_type,
          created_at,
          updated_at
        `
        )
        .eq("company_id", companyId)
        .gte("date", startDate)
        .lte("date", endDate);

      if (selectedObjectIds && selectedObjectIds.length > 0) {
        query = query.in("object_id", selectedObjectIds);
      }

      const { data, error } = await query
        .order("date", { ascending: true })
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

        attendanceEntries.push({
          id: row.id,
          workId: row.id,
          employeeId,
          hours,
          comment: row.comment,
          date,
          objectId,
          employeeName: employeeNameById.get(employeeId) ?? null,
          objectName: objectNameById.get(objectId) ?? null,
          employeePosition: employeePositionById.get(employeeId) ?? null,
          createdAt: row.created_at,
          updatedAt: row.updated_at,
          isManualEntry: true,
        });
      }

      if (batch.length < POSTGREST_PAGE_SIZE) {
        hasMore = false;
      } else {
        offset += POSTGREST_PAGE_SIZE;
      }
    }
  }

  const allEntries = [...workHoursEntries, ...attendanceEntries];

  // 5. Build object options with color palette
  const objectOptions: TimesheetObjectOption[] = objects.map((obj, index) => {
    const palette = getObjectPaletteItem(index);
    return {
      id: obj.id,
      name: obj.name,
      colorHex: palette.hex,
      colorClass: palette.cellClass,
      badgeClass: palette.badgeClass,
    };
  });

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
