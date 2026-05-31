/**
 * Правила видимости строк табеля (сетка UI и Excel).
 *
 * Держите в синхронизации с
 * `lib/features/timesheet/domain/timesheet_employee_visibility.dart`.
 *
 * Сегмент «С часами / Без часов» в Excel не применяется — только базовые правила
 * (объекты, уволенные с часами) и опционально `onlyEmployeeIds` из чекбоксов.
 */

export interface TimesheetHoursIndex {
  employeeIdsWithEntries: Set<string>;
  hoursSumByEmployeeId: Map<string, number>;
}

export function buildTimesheetHoursIndex(
  entries: { employeeId: string; hours: number }[],
): TimesheetHoursIndex {
  const employeeIdsWithEntries = new Set<string>();
  const hoursSumByEmployeeId = new Map<string, number>();

  for (const entry of entries) {
    employeeIdsWithEntries.add(entry.employeeId);
    hoursSumByEmployeeId.set(
      entry.employeeId,
      (hoursSumByEmployeeId.get(entry.employeeId) ?? 0) + entry.hours,
    );
  }

  return { employeeIdsWithEntries, hoursSumByEmployeeId };
}

export function isTimesheetGridEmployeeVisible(
  employee: { id: string; status: string; includeInTimesheet: boolean },
  hoursIndex: TimesheetHoursIndex,
  hasObjectFilter: boolean,
): boolean {
  if (hasObjectFilter) {
    return hoursIndex.employeeIdsWithEntries.has(employee.id);
  }
  if (!employee.includeInTimesheet) {
    return hoursIndex.employeeIdsWithEntries.has(employee.id);
  }
  if (employee.status !== "fired") return true;
  return hoursIndex.employeeIdsWithEntries.has(employee.id);
}

export function filterTimesheetGridEmployees<T extends {
  id: string;
  status: string;
  includeInTimesheet: boolean;
  fullName: string;
}>(
  employees: T[],
  hoursIndex: TimesheetHoursIndex,
  hasObjectFilter: boolean,
  onlyEmployeeIds?: string[],
): T[] {
  let visible = employees
    .filter((employee) =>
      isTimesheetGridEmployeeVisible(employee, hoursIndex, hasObjectFilter)
    )
    .sort((a, b) => a.fullName.localeCompare(b.fullName, "ru"));

  if (onlyEmployeeIds && onlyEmployeeIds.length > 0) {
    const pick = new Set(onlyEmployeeIds);
    visible = visible.filter((e) => pick.has(e.id));
  }

  return visible;
}
