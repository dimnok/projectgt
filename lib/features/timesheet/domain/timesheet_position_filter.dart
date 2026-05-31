import 'package:projectgt/domain/entities/employee.dart';

/// Ключ фильтра для сотрудников без указанной должности.
const String kTimesheetNoPositionFilterKey = '__no_position__';

/// Подпись строки «без должности» в меню фильтра.
const String kTimesheetNoPositionFilterLabel = 'Без должности';

/// Одна строка выпадающего фильтра по должностям.
class TimesheetPositionFilterOption {
  /// Создаёт опцию фильтра.
  const TimesheetPositionFilterOption({
    required this.key,
    required this.label,
  });

  /// Нормализованный ключ (сравнение без учёта регистра).
  final String key;

  /// Текст в меню и на триггере.
  final String label;
}

/// Стабильный ключ должности сотрудника для фильтра табеля.
String timesheetEmployeePositionFilterKey(Employee employee) {
  final raw = employee.position?.trim();
  if (raw == null || raw.isEmpty) return kTimesheetNoPositionFilterKey;
  return raw.toLowerCase();
}

/// Уникальные должности из каталога сотрудников (сортировка по подписи).
List<TimesheetPositionFilterOption> buildTimesheetPositionFilterOptions(
  List<Employee> employees,
) {
  final labelsByKey = <String, String>{};

  for (final employee in employees) {
    final key = timesheetEmployeePositionFilterKey(employee);
    if (labelsByKey.containsKey(key)) continue;

    if (key == kTimesheetNoPositionFilterKey) {
      labelsByKey[key] = kTimesheetNoPositionFilterLabel;
    } else {
      labelsByKey[key] = employee.position!.trim();
    }
  }

  final options = labelsByKey.entries
      .map(
        (e) => TimesheetPositionFilterOption(key: e.key, label: e.value),
      )
      .toList();
  options.sort(
    (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
  );
  return options;
}

/// Сужает список по выбранным ключам должностей (пустой набор — без фильтра).
List<Employee> filterEmployeesByTimesheetPositionKeys(
  List<Employee> employees,
  Set<String> selectedKeys,
) {
  if (selectedKeys.isEmpty) return employees;
  return employees
      .where(
        (e) => selectedKeys.contains(timesheetEmployeePositionFilterKey(e)),
      )
      .toList();
}

/// Есть ли активный клиентский фильтр по должностям.
bool hasActiveTimesheetPositionFilter(Set<String> selectedKeys) =>
    selectedKeys.isNotEmpty;
