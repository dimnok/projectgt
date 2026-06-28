import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/domain/entities/employee.dart';

import 'timesheet_employee_list_scope.dart';
import 'timesheet_hours_index.dart';

/// Правила видимости строк табеля (сетка UI и Excel).
///
/// **Единый контракт** для экрана и `export-timesheet`. Держите в синхронизации
/// с `supabase/functions/export-timesheet/timesheet_employee_visibility.ts`.
///
/// Сегмент [TimesheetEmployeeListScope] (`С часами` / `Без часов`) — **только UI**;
/// экспорт Excel его не применяет (всегда [TimesheetEmployeeListScope.all]).

/// Показывать ли сотрудника в сетке/Excel по базовым правилам.
///
/// Объекты, мягкое исключение из табеля (`includeInTimesheet == false`) и уволенные:
/// без записей часов за период — строка скрыта (кроме режима «только с объектами»).
bool isTimesheetGridEmployeeVisible({
  required bool isFired,
  required bool includeInTimesheet,
  required String employeeId,
  required TimesheetHoursIndex hoursIndex,
  required bool hasObjectFilter,
}) {
  if (hasObjectFilter) {
    return hoursIndex.employeeIdsWithEntries.contains(employeeId);
  }
  if (!includeInTimesheet) {
    return hoursIndex.employeeIdsWithEntries.contains(employeeId);
  }
  if (!isFired) return true;
  return hoursIndex.employeeIdsWithEntries.contains(employeeId);
}

/// Применяет сегмент «Все / С часами / Без часов» (только UI).
List<Employee> filterEmployeesByTimesheetListScope(
  List<Employee> employees,
  TimesheetHoursIndex hoursIndex,
  TimesheetEmployeeListScope listScope,
) {
  switch (listScope) {
    case TimesheetEmployeeListScope.withHours:
      final withHours = hoursIndex.employeeIdsWithPositiveHours;
      return employees.where((e) => withHours.contains(e.id)).toList();
    case TimesheetEmployeeListScope.withoutHours:
      return employees
          .where((e) => hoursIndex.hoursSumFor(e.id) <= 0)
          .toList();
    case TimesheetEmployeeListScope.all:
      return employees;
  }
}

List<Employee> _applyListScope(
  List<Employee> employees,
  TimesheetHoursIndex hoursIndex,
  TimesheetEmployeeListScope listScope,
) =>
    filterEmployeesByTimesheetListScope(employees, hoursIndex, listScope);

/// Список сотрудников для строк сетки табеля (без поиска по ФИО).
List<Employee> visibleTimesheetGridEmployees({
  required List<Employee> employees,
  required TimesheetHoursIndex hoursIndex,
  required bool hasObjectFilter,
  TimesheetEmployeeListScope listScope = TimesheetEmployeeListScope.all,
}) {
  final base = employees
      .where(
        (e) => isTimesheetGridEmployeeVisible(
          isFired: e.status == EmployeeStatus.fired,
          includeInTimesheet: e.includeInTimesheet,
          employeeId: e.id,
          hoursIndex: hoursIndex,
          hasObjectFilter: hasObjectFilter,
        ),
      )
      .toList();

  final scoped = _applyListScope(base, hoursIndex, listScope);

  scoped.sort((a, b) {
    final nameA = formatFullName(a.lastName, a.firstName, a.middleName);
    final nameB = formatFullName(b.lastName, b.firstName, b.middleName);
    return nameA.compareTo(nameB);
  });

  return scoped;
}

/// Сотрудники для Excel: базовые правила + опционально только выбранные id.
///
/// [onlyEmployeeIds] — чекбоксы в сетке; `null` или пусто — без ограничения.
List<Employee> visibleTimesheetExportEmployees({
  required List<Employee> employees,
  required TimesheetHoursIndex hoursIndex,
  required bool hasObjectFilter,
  List<String>? onlyEmployeeIds,
}) {
  var visible = visibleTimesheetGridEmployees(
    employees: employees,
    hoursIndex: hoursIndex,
    hasObjectFilter: hasObjectFilter,
    listScope: TimesheetEmployeeListScope.all,
  );

  if (onlyEmployeeIds != null && onlyEmployeeIds.isNotEmpty) {
    final pick = onlyEmployeeIds.toSet();
    visible = visible.where((e) => pick.contains(e.id)).toList();
  }

  return visible;
}
