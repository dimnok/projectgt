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

export type EmployeeHoursStats = {
  totalHours: number;
  hasEntries: boolean;
};

export function buildEmployeeHoursMap(
  entries: TimesheetEntry[]
): Map<string, EmployeeHoursStats> {
  const map = new Map<string, EmployeeHoursStats>();
  for (const e of entries) {
    const existing = map.get(e.employeeId);
    if (existing) {
      existing.totalHours += e.hours;
      existing.hasEntries = true;
    } else {
      map.set(e.employeeId, {
        totalHours: e.hours,
        hasEntries: true,
      });
    }
  }
  return map;
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
    if (!map.has(key)) {
      map.set(
        key,
        key === NO_POSITION_FILTER_KEY
          ? NO_POSITION_FILTER_LABEL
          : emp.position.trim()
      );
    }
  }

  return Array.from(map.entries())
    .map(([key, label]) => ({ key, label }))
    .sort((a, b) => a.label.localeCompare(b.label, "ru"));
}

export function filterEmployeesByPositionKeys(
  employees: Employee[],
  selectedKeys: string[]
): Employee[] {
  if (selectedKeys.length === 0) return employees;
  const keySet = new Set(selectedKeys);
  return employees.filter((e) => keySet.has(getEmployeePositionKey(e)));
}

/**
 * Determines whether an employee should be visible in the timesheet grid.
 */
export function isEmployeeBaseVisible({
  isFired,
  includeInTimesheet,
  hasEntries,
  hasObjectFilter,
}: {
  isFired: boolean;
  includeInTimesheet: boolean;
  hasEntries: boolean;
  hasObjectFilter: boolean;
}): boolean {
  if (hasObjectFilter) return hasEntries;
  if (!includeInTimesheet) return hasEntries;
  if (isFired) return hasEntries;
  return true;
}

export type FilterTimesheetEmployeesParams = {
  employees: Employee[];
  hoursMap: Map<string, EmployeeHoursStats>;
  todayOpenShift: TodayOpenShiftInfo;
  periodContainsToday: boolean;
  selectedObjectIds: string[];
  selectedPositionKeys: string[];
  listScope: TimesheetEmployeeListScope;
  openShiftScope: TimesheetOpenShiftFilterScope;
  searchQuery: string;
};

/**
 * High-performance single-pass employee filtering for the timesheet grid.
 */
export function filterTimesheetEmployees({
  employees,
  hoursMap,
  todayOpenShift,
  periodContainsToday,
  selectedObjectIds,
  selectedPositionKeys,
  listScope,
  openShiftScope,
  searchQuery,
}: FilterTimesheetEmployeesParams): Employee[] {
  const hasObjectFilter = selectedObjectIds.length > 0;
  const objectSet = hasObjectFilter ? new Set(selectedObjectIds) : null;
  const hasPositionFilter = selectedPositionKeys.length > 0;
  const positionSet = hasPositionFilter ? new Set(selectedPositionKeys) : null;
  const query = searchQuery.trim().toLowerCase();

  const result: Employee[] = [];

  for (const emp of employees) {
    // 1. Search filter
    if (query) {
      const full = employeeFullName(emp).toLowerCase();
      if (!full.includes(query)) continue;
    }

    // 2. Position filter
    if (positionSet && !positionSet.has(getEmployeePositionKey(emp))) {
      continue;
    }

    const stats = hoursMap.get(emp.id);
    const totalHours = stats?.totalHours ?? 0;
    const hasEntries = stats?.hasEntries ?? false;
    const isInTodayShift =
      periodContainsToday && todayOpenShift.employeeIds.has(emp.id);

    // If object filter is active, check if employee matches open shift objects
    let matchesShiftObject = true;
    if (hasObjectFilter && objectSet && isInTodayShift) {
      const shiftObjs = todayOpenShift.objectIdsByEmployeeId.get(emp.id);
      matchesShiftObject =
        Boolean(shiftObjs) &&
        Array.from(shiftObjs!).some((id) => objectSet.has(id));
    }

    // 3. Open shift scope filter
    if (periodContainsToday && openShiftScope === "inOpenShift") {
      if (!isInTodayShift) continue;
      if (hasObjectFilter && !matchesShiftObject) continue;
    } else if (periodContainsToday && openShiftScope === "notInOpenShift") {
      if (isInTodayShift) continue;
    }

    // 4. Base visibility (unless forced by being in today's open shift)
    const baseVisible = isEmployeeBaseVisible({
      isFired: emp.status === "fired",
      includeInTimesheet: emp.includeInTimesheet,
      hasEntries,
      hasObjectFilter,
    });

    const isVisible =
      baseVisible ||
      (isInTodayShift && (!hasObjectFilter || matchesShiftObject));

    if (!isVisible) continue;

    // 5. Hours scope filter (withHours / withoutHours)
    if (listScope === "withHours" && totalHours <= 0) {
      continue;
    }
    if (listScope === "withoutHours" && totalHours > 0) {
      continue;
    }

    result.push(emp);
  }

  result.sort((a, b) =>
    employeeFullName(a).localeCompare(employeeFullName(b), "ru")
  );

  return result;
}
