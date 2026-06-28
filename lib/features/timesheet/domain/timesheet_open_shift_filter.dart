import 'package:projectgt/domain/entities/employee.dart';

import 'timesheet_position_filter.dart';
import 'timesheet_today_open_shift.dart';

/// Фильтр списка по назначению в открытые смены **сегодня** (только UI).
enum TimesheetOpenShiftFilterScope {
  /// Без дополнительного фильтра по сменам.
  all,

  /// Только назначенные в открытую смену сегодня.
  inOpenShift,

  /// Только не назначенные в открытую смену сегодня.
  notInOpenShift,
}

/// Сужает [employees] по [scope] и [todayOpenShift].
///
/// Если [periodContainsToday] — `false`, фильтр не применяется.
List<Employee> filterEmployeesByOpenShiftScope(
  List<Employee> employees, {
  required TimesheetTodayOpenShiftIndex todayOpenShift,
  required TimesheetOpenShiftFilterScope scope,
  required bool periodContainsToday,
}) {
  if (!periodContainsToday || scope == TimesheetOpenShiftFilterScope.all) {
    return employees;
  }

  return switch (scope) {
    TimesheetOpenShiftFilterScope.inOpenShift => employees
        .where((e) => todayOpenShift.contains(e.id))
        .toList(),
    TimesheetOpenShiftFilterScope.notInOpenShift => employees
        .where((e) => !todayOpenShift.contains(e.id))
        .toList(),
    TimesheetOpenShiftFilterScope.all => employees,
  };
}

/// Список сотрудников в открытых сменах сегодня с учётом фильтров должностей и объектов.
List<Employee> employeesInTodayOpenShift({
  required List<Employee> allEmployees,
  required TimesheetTodayOpenShiftIndex todayOpenShift,
  required Set<String> positionKeys,
  required List<String>? selectedObjectIds,
}) {
  var list = allEmployees
      .where((e) => todayOpenShift.contains(e.id))
      .toList();

  list = filterEmployeesByTimesheetPositionKeys(list, positionKeys);

  final objectFilter = selectedObjectIds?.where((id) => id.isNotEmpty).toSet();
  if (objectFilter != null && objectFilter.isNotEmpty) {
    list = list
        .where(
          (e) => todayOpenShift.objectIdsFor(e.id).any(objectFilter.contains),
        )
        .toList();
  }

  return list;
}
