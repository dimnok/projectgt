import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/domain/entities/employee.dart';

import '../../domain/timesheet_employee_list_scope.dart';

export '../../domain/timesheet_employee_list_scope.dart';

/// Строка поиска по ФИО в табеле (клиентская фильтрация списка).
final timesheetSearchQueryProvider = StateProvider<String>((ref) => '');

/// Активный режим отображения списка сотрудников ([TimesheetEmployeeListScope]).
final timesheetEmployeeListScopeProvider =
    StateProvider<TimesheetEmployeeListScope>(
      (ref) => TimesheetEmployeeListScope.all,
    );

/// Нормализованная строка поиска по ФИО (trim + lower case).
String normalizeTimesheetNameSearchQuery(String query) =>
    query.trim().toLowerCase();

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
