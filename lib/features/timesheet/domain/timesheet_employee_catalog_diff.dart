import 'package:projectgt/domain/entities/employee.dart';

/// Изменился ли справочник сотрудников табеля (без учёта ставок и прочих полей карточки).
///
/// Используется синхронизацией табеля с модулем «Сотрудники»: подгрузка одного
/// сотрудника для карточки ([Employee.currentHourlyRate]) не должна перезагружать сетку.
bool timesheetEmployeeCatalogChanged(
  List<Employee> before,
  List<Employee> after,
) {
  if (identical(before, after)) return false;
  if (before.length != after.length) return true;

  final afterById = {for (final e in after) e.id: e};
  for (final employee in before) {
    final next = afterById[employee.id];
    if (next == null) return true;
    if (employee.includeInTimesheet != next.includeInTimesheet ||
        employee.status != next.status ||
        employee.lastName != next.lastName ||
        employee.firstName != next.firstName ||
        employee.middleName != next.middleName ||
        employee.position != next.position ||
        !_objectIdsEqual(employee.objectIds, next.objectIds)) {
      return true;
    }
  }
  return false;
}

bool _objectIdsEqual(List<String> before, List<String> after) {
  if (before.length != after.length) return false;
  final afterSet = after.toSet();
  return before.every(afterSet.contains);
}
