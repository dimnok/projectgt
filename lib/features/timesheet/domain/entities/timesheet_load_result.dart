import 'package:projectgt/domain/entities/employee.dart';

import 'timesheet_entry.dart';

/// Результат загрузки табеля за период.
class TimesheetLoadResult {
  /// Создаёт результат загрузки табеля.
  const TimesheetLoadResult({
    required this.entries,
    required this.employees,
  });

  /// Записи часов за период.
  final List<TimesheetEntry> entries;

  /// Сотрудники компании (для сетки табеля и обогащения записей).
  final List<Employee> employees;
}
