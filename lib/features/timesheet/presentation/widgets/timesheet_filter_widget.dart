import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/domain/entities/employee.dart';

import '../../domain/timesheet_employee_list_scope.dart';
import '../../domain/timesheet_open_shift_filter.dart';

export '../../domain/timesheet_employee_list_scope.dart';
export '../../domain/timesheet_open_shift_filter.dart';

/// Строка поиска по ФИО в табеле (клиентская фильтрация списка).
final timesheetSearchQueryProvider = StateProvider<String>((ref) => '');

/// Активный режим отображения списка сотрудников ([TimesheetEmployeeListScope]).
final timesheetEmployeeListScopeProvider =
    StateProvider<TimesheetEmployeeListScope>(
      (ref) => TimesheetEmployeeListScope.all,
    );

/// Фильтр по назначению в открытые смены сегодня ([TimesheetOpenShiftFilterScope]).
final timesheetOpenShiftFilterScopeProvider =
    StateProvider<TimesheetOpenShiftFilterScope>(
      (ref) => TimesheetOpenShiftFilterScope.all,
    );

/// Нормализованная строка поиска по ФИО (trim + lower case).
String normalizeTimesheetNameSearchQuery(String query) =>
    query.trim().toLowerCase();

/// Есть ли активные фильтры состава списка (часы / смена).
bool hasActiveTimesheetListFilters({
  required TimesheetEmployeeListScope hoursScope,
  required TimesheetOpenShiftFilterScope shiftScope,
  required bool periodContainsToday,
}) {
  if (hoursScope != TimesheetEmployeeListScope.all) return true;
  if (!periodContainsToday) return false;
  return shiftScope != TimesheetOpenShiftFilterScope.all;
}

/// Подпись на кнопке фильтра «Состав» в панели табеля.
String timesheetListFilterTriggerLabel({
  required TimesheetEmployeeListScope hoursScope,
  required TimesheetOpenShiftFilterScope shiftScope,
  required bool periodContainsToday,
}) {
  final parts = <String>[];
  switch (hoursScope) {
    case TimesheetEmployeeListScope.withHours:
      parts.add('С часами');
    case TimesheetEmployeeListScope.withoutHours:
      parts.add('Без часов');
    case TimesheetEmployeeListScope.all:
      break;
  }
  if (periodContainsToday) {
    switch (shiftScope) {
      case TimesheetOpenShiftFilterScope.inOpenShift:
        parts.add('В смене');
      case TimesheetOpenShiftFilterScope.notInOpenShift:
        parts.add('Не в смене');
      case TimesheetOpenShiftFilterScope.all:
        break;
    }
  }
  if (parts.isEmpty) return 'Состав';
  if (parts.length == 1) return parts.first;
  return parts.join(' · ');
}

/// Совпадение [employee] с поисковой строкой по [formatFullName].
bool employeeMatchesTimesheetNameSearch(Employee employee, String query) {
  final normalized = normalizeTimesheetNameSearchQuery(query);
  if (normalized.isEmpty) return true;
  return formatFullName(
    employee.lastName,
    employee.firstName,
    employee.middleName,
  ).toLowerCase().contains(normalized);
}

/// Сужает список сотрудников по поиску ФИО (единственный фильтр поиска в табеле).
List<Employee> filterEmployeesByTimesheetNameSearch(
  List<Employee> employees,
  String query,
) {
  final normalized = normalizeTimesheetNameSearchQuery(query);
  if (normalized.isEmpty) return employees;
  return employees
      .where((e) => employeeMatchesTimesheetNameSearch(e, query))
      .toList();
}
