import type { Employee } from "@/features/employees/types/employee.types";
import { employeeFullName } from "@/features/employees/utils/employee.utils";
import type {
  TimesheetEmployeeListScope,
  TimesheetEntry,
  TimesheetOpenShiftFilterScope,
  TodayOpenShiftInfo,
} from "@/features/timesheet/types/timesheet.types";

export const NO_POSITION_FILTER_KEY = "__no_position__";
export const NO_POSITION_FILTER_LABEL = "Без должности";

export class TimesheetHoursIndex {
  readonly employeeIdsWithEntries: Set<string>;
  readonly hoursSumByEmployeeId: Map<string, number>;
  readonly employeeIdsWithPositiveHours: Set<string>;

  constructor(entries: TimesheetEntry[]) {
    const withEntries = new Set<string>();
    const sumMap = new Map<string, number>();

    for (const entry of entries) {
      withEntries.add(entry.employeeId);
      const prev = sumMap.get(entry.employeeId) ?? 0;
      sumMap.set(entry.employeeId, prev + entry.hours);
    }

    this.employeeIdsWithEntries = withEntries;
    this.hoursSumByEmployeeId = sumMap;

    const positiveSet = new Set<string>();
    for (const [id, sum] of sumMap.entries()) {
      if (sum > 0) {
        positiveSet.add(id);
      }
    }
    this.employeeIdsWithPositiveHours = positiveSet;
  }

  getHoursSum(employeeId: string): number {
    return this.hoursSumByEmployeeId.get(employeeId) ?? 0;
  }
}

export function isTimesheetGridEmployeeVisible({
  isFired,
  includeInTimesheet,
  employeeId,
  hoursIndex,
  hasObjectFilter,
}: {
  isFired: boolean;
  includeInTimesheet: boolean;
  employeeId: string;
  hoursIndex: TimesheetHoursIndex;
  hasObjectFilter: boolean;
}): boolean {
  if (hasObjectFilter) {
    return hoursIndex.employeeIdsWithEntries.has(employeeId);
  }
  if (!includeInTimesheet) {
    return hoursIndex.employeeIdsWithEntries.has(employeeId);
  }
  if (!isFired) {
    return true;
  }
  return hoursIndex.employeeIdsWithEntries.has(employeeId);
}

export function filterEmployeesByTimesheetListScope(
  employees: Employee[],
  hoursIndex: TimesheetHoursIndex,
  listScope: TimesheetEmployeeListScope
): Employee[] {
  switch (listScope) {
    case "withHours":
      return employees.filter((e) => hoursIndex.employeeIdsWithPositiveHours.has(e.id));
    case "withoutHours":
      return employees.filter((e) => hoursIndex.getHoursSum(e.id) <= 0);
    case "all":
    default:
      return employees;
  }
}

export function getEmployeePositionKey(employee: Employee): string {
  const raw = employee.position?.trim();
  if (!raw) return NO_POSITION_FILTER_KEY;
  return raw.toLowerCase();
}

export function buildPositionFilterOptions(
  employees: Employee[]
): { key: string; label: string }[] {
  const map = new Map<string, string>();

  for (const emp of employees) {
    const key = getEmployeePositionKey(emp);
    if (map.has(key)) continue;
    if (key === NO_POSITION_FILTER_KEY) {
      map.set(key, NO_POSITION_FILTER_LABEL);
    } else {
      map.set(key, emp.position.trim());
    }
  }

  const options = Array.from(map.entries()).map(([key, label]) => ({
    key,
    label,
  }));

  options.sort((a, b) => a.label.localeCompare(b.label, "ru"));
  return options;
}

export function filterEmployeesByPositionKeys(
  employees: Employee[],
  selectedKeys: string[]
): Employee[] {
  if (selectedKeys.length === 0) return employees;
  const keySet = new Set(selectedKeys);
  return employees.filter((e) => keySet.has(getEmployeePositionKey(e)));
}

export function filterEmployeesByOpenShiftScope(
  employees: Employee[],
  todayOpenShift: TodayOpenShiftInfo,
  scope: TimesheetOpenShiftFilterScope,
  periodContainsToday: boolean
): Employee[] {
  if (!periodContainsToday || scope === "all") {
    return employees;
  }

  if (scope === "inOpenShift") {
    return employees.filter((e) => todayOpenShift.employeeIds.has(e.id));
  }

  if (scope === "notInOpenShift") {
    return employees.filter((e) => !todayOpenShift.employeeIds.has(e.id));
  }

  return employees;
}

export function employeesInTodayOpenShift({
  allEmployees,
  todayOpenShift,
  positionKeys,
  selectedObjectIds,
}: {
  allEmployees: Employee[];
  todayOpenShift: TodayOpenShiftInfo;
  positionKeys: string[];
  selectedObjectIds: string[];
}): Employee[] {
  let list = allEmployees.filter((e) => todayOpenShift.employeeIds.has(e.id));

  list = filterEmployeesByPositionKeys(list, positionKeys);

  if (selectedObjectIds.length > 0) {
    const objSet = new Set(selectedObjectIds);
    list = list.filter((e) => {
      const shiftObjs = todayOpenShift.objectIdsByEmployeeId.get(e.id);
      if (!shiftObjs) return false;
      for (const id of shiftObjs) {
        if (objSet.has(id)) return true;
      }
      return false;
    });
  }

  return list;
}

export function mergeTodayOpenShiftEmployees({
  currentList,
  allEmployees,
  todayOpenShift,
  positionKeys,
  selectedObjectIds,
  hoursIndex,
  listScope,
  periodContainsToday,
}: {
  currentList: Employee[];
  allEmployees: Employee[];
  todayOpenShift: TodayOpenShiftInfo;
  positionKeys: string[];
  selectedObjectIds: string[];
  hoursIndex: TimesheetHoursIndex;
  listScope: TimesheetEmployeeListScope;
  periodContainsToday: boolean;
}): Employee[] {
  if (!periodContainsToday || todayOpenShift.employeeIds.size === 0) {
    return currentList;
  }

  const existingIds = new Set(currentList.map((e) => e.id));
  let extras = allEmployees.filter(
    (e) => todayOpenShift.employeeIds.has(e.id) && !existingIds.has(e.id)
  );

  extras = filterEmployeesByPositionKeys(extras, positionKeys);

  if (selectedObjectIds.length > 0) {
    const objSet = new Set(selectedObjectIds);
    extras = extras.filter((e) => {
      const shiftObjs = todayOpenShift.objectIdsByEmployeeId.get(e.id);
      if (!shiftObjs) return false;
      for (const id of shiftObjs) {
        if (objSet.has(id)) return true;
      }
      return false;
    });
  }

  extras = filterEmployeesByTimesheetListScope(extras, hoursIndex, listScope);

  if (extras.length === 0) return currentList;

  const merged = [...currentList, ...extras];
  merged.sort((a, b) =>
    employeeFullName(a).localeCompare(employeeFullName(b), "ru")
  );
  return merged;
}

export function filterEmployeesByNameSearch(
  employees: Employee[],
  searchQuery: string
): Employee[] {
  const query = searchQuery.trim().toLowerCase();
  if (!query) return employees;

  return employees.filter((e) => {
    const full = employeeFullName(e).toLowerCase();
    return full.includes(query);
  });
}
