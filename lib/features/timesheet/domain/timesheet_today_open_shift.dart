/// Сотрудники, назначенные в **открытые** смены на сегодня (контроль выхода).
class TimesheetTodayOpenShiftIndex {
  /// Создаёт индекс назначений.
  const TimesheetTodayOpenShiftIndex({
    required this.employeeIds,
    required this.hintByEmployeeId,
    required this.objectIdsByEmployeeId,
  });

  /// Пустой индекс (нет открытых смен или день вне периода).
  static const empty = TimesheetTodayOpenShiftIndex(
    employeeIds: {},
    hintByEmployeeId: {},
    objectIdsByEmployeeId: {},
  );

  /// ID сотрудников в открытых сменах сегодня.
  final Set<String> employeeIds;

  /// Подсказка для tooltip: объекты смен (`employeeId` → текст).
  final Map<String, String> hintByEmployeeId;

  /// Объекты открытых смен сегодня (`employeeId` → id объектов).
  final Map<String, Set<String>> objectIdsByEmployeeId;

  /// Сотрудник назначен в открытую смену сегодня.
  bool contains(String employeeId) => employeeIds.contains(employeeId);

  /// Объекты открытых смен сотрудника сегодня.
  Set<String> objectIdsFor(String employeeId) =>
      objectIdsByEmployeeId[employeeId] ?? const {};

  /// Текст подсказки для ячейки.
  String hintFor(String employeeId) =>
      hintByEmployeeId[employeeId] ?? 'В открытой смене сегодня';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimesheetTodayOpenShiftIndex &&
        _setEquals(employeeIds, other.employeeIds) &&
        _mapEquals(hintByEmployeeId, other.hintByEmployeeId) &&
        _mapOfSetsEquals(objectIdsByEmployeeId, other.objectIdsByEmployeeId);
  }

  @override
  int get hashCode => Object.hash(
    employeeIds.length,
    hintByEmployeeId.length,
    objectIdsByEmployeeId.length,
  );
}

bool _setEquals<T>(Set<T> a, Set<T> b) =>
    a.length == b.length && a.containsAll(b);

bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}

bool _mapOfSetsEquals(Map<String, Set<String>> a, Map<String, Set<String>> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!_setEquals(entry.value, b[entry.key] ?? const {})) return false;
  }
  return true;
}

/// Парсит ответ PostgREST: `works` + вложенные `work_hours` + `objects`.
TimesheetTodayOpenShiftIndex parseTodayOpenShiftWorksResponse(
  Iterable<Map<String, dynamic>> worksRows,
) {
  final employeeIds = <String>{};
  final objectNamesByEmployee = <String, Set<String>>{};
  final objectIdsByEmployee = <String, Set<String>>{};

  for (final work in worksRows) {
    final objectName = _readObjectName(work['objects']);
    final objectId = work['object_id']?.toString();
    final hours = work['work_hours'] as List<dynamic>? ?? const [];

    for (final hourRaw in hours) {
      if (hourRaw is! Map) continue;
      final employeeId = hourRaw['employee_id']?.toString();
      if (employeeId == null || employeeId.isEmpty) continue;

      employeeIds.add(employeeId);
      if (objectName != null && objectName.isNotEmpty) {
        objectNamesByEmployee
            .putIfAbsent(employeeId, () => <String>{})
            .add(objectName);
      }
      if (objectId != null && objectId.isNotEmpty) {
        objectIdsByEmployee
            .putIfAbsent(employeeId, () => <String>{})
            .add(objectId);
      }
    }
  }

  final hints = <String, String>{};
  for (final entry in objectNamesByEmployee.entries) {
    final names = entry.value.toList()..sort();
    hints[entry.key] = 'В смене сегодня: ${names.join(', ')}';
  }

  return TimesheetTodayOpenShiftIndex(
    employeeIds: employeeIds,
    hintByEmployeeId: hints,
    objectIdsByEmployeeId: objectIdsByEmployee,
  );
}

String? _readObjectName(dynamic objectsField) {
  if (objectsField is Map) {
    return objectsField['name']?.toString();
  }
  if (objectsField is List && objectsField.isNotEmpty) {
    final first = objectsField.first;
    if (first is Map) return first['name']?.toString();
  }
  return null;
}

/// Календарное совпадение дня (без учёта времени).
bool isSameCalendarDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Сегодня (локальное время устройства) попадает в период [start]…[end] включительно.
bool timesheetPeriodContainsToday({
  required DateTime start,
  required DateTime end,
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  final startDay = DateTime(start.year, start.month, start.day);
  final endDay = DateTime(end.year, end.month, end.day);
  final todayDay = DateTime(today.year, today.month, today.day);
  return !todayDay.isBefore(startDay) && !todayDay.isAfter(endDay);
}
