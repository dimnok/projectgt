import 'entities/timesheet_entry.dart';

/// Агрегат часов табеля по сотрудникам для правил видимости строк.
///
/// Строится из записей за период (на UI — уже с учётом фильтра объектов;
/// в Excel — после серверной фильтрации `objectIds`).
class TimesheetHoursIndex {
  /// Создаёт индекс из записей табеля.
  factory TimesheetHoursIndex.fromEntries(List<TimesheetEntry> entries) {
    final employeeIdsWithEntries = <String>{};
    final hoursSumByEmployeeId = <String, num>{};

    for (final entry in entries) {
      employeeIdsWithEntries.add(entry.employeeId);
      hoursSumByEmployeeId[entry.employeeId] =
          (hoursSumByEmployeeId[entry.employeeId] ?? 0) + entry.hours;
    }

    return TimesheetHoursIndex._(
      employeeIdsWithEntries: employeeIdsWithEntries,
      hoursSumByEmployeeId: hoursSumByEmployeeId,
    );
  }

  /// Создаёт индекс из плоских строк (Edge Function / тесты).
  factory TimesheetHoursIndex.fromEmployeeHours(
    Iterable<({String employeeId, num hours})> rows,
  ) {
    final employeeIdsWithEntries = <String>{};
    final hoursSumByEmployeeId = <String, num>{};

    for (final row in rows) {
      employeeIdsWithEntries.add(row.employeeId);
      hoursSumByEmployeeId[row.employeeId] =
          (hoursSumByEmployeeId[row.employeeId] ?? 0) + row.hours;
    }

    return TimesheetHoursIndex._(
      employeeIdsWithEntries: employeeIdsWithEntries,
      hoursSumByEmployeeId: hoursSumByEmployeeId,
    );
  }

  const TimesheetHoursIndex._({
    required this.employeeIdsWithEntries,
    required this.hoursSumByEmployeeId,
  });

  /// Сотрудники, у которых есть хотя бы одна запись в переданном наборе.
  final Set<String> employeeIdsWithEntries;

  /// Сумма [hours] по `employee_id` в переданном наборе.
  final Map<String, num> hoursSumByEmployeeId;

  /// Сотрудники с суммой часов строго больше нуля.
  Set<String> get employeeIdsWithPositiveHours => hoursSumByEmployeeId.entries
      .where((e) => e.value > 0)
      .map((e) => e.key)
      .toSet();

  /// Сумма часов сотрудника в индексе (0, если записей не было).
  num hoursSumFor(String employeeId) =>
      hoursSumByEmployeeId[employeeId] ?? 0;
}
