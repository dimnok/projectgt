import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/domain/entities/employee.dart';

import 'entities/timesheet_entry.dart';
import 'timesheet_employee_list_scope.dart';
import 'timesheet_employee_visibility.dart';
import 'timesheet_hours_index.dart';
import 'timesheet_position_filter.dart';

/// Статистика посещаемости одного сотрудника за период табеля.
class TimesheetEmployeeAttendanceStat {
  /// Создаёт запись статистики.
  const TimesheetEmployeeAttendanceStat({
    required this.employeeId,
    required this.displayName,
    this.position,
    required this.workedDays,
    required this.totalDaysInPeriod,
    required this.totalHours,
  });

  /// Идентификатор сотрудника.
  final String employeeId;

  /// ФИО для отображения.
  final String displayName;

  /// Должность (если указана).
  final String? position;

  /// Число календарных дней периода с суммой часов > 0.
  final int workedDays;

  /// Число календарных дней в выбранном периоде (включительно).
  final int totalDaysInPeriod;

  /// Сумма часов за период.
  final num totalHours;

  /// Доля отработанных дней от длины периода, % (0–100).
  double get attendancePercent =>
      totalDaysInPeriod > 0 ? workedDays / totalDaysInPeriod * 100 : 0;
}

/// Результат расчёта топов посещаемости за месяц.
class TimesheetAttendanceStatsResult {
  /// Создаёт результат.
  const TimesheetAttendanceStatsResult({
    required this.topHighAttendance,
    required this.topLowAttendance,
    required this.totalEmployeesConsidered,
  });

  /// Топ сотрудников с высокой посещаемостью.
  final List<TimesheetEmployeeAttendanceStat> topHighAttendance;

  /// Топ сотрудников с низкой посещаемостью.
  final List<TimesheetEmployeeAttendanceStat> topLowAttendance;

  /// Сколько сотрудников участвовало в расчёте.
  final int totalEmployeesConsidered;

  /// Пустой результат (нет сотрудников в выборке).
  static const empty = TimesheetAttendanceStatsResult(
    topHighAttendance: [],
    topLowAttendance: [],
    totalEmployeesConsidered: 0,
  );
}

String _dateKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

int _inclusiveCalendarDays(DateTime start, DateTime end) {
  final startDay = DateTime(start.year, start.month, start.day);
  final endDay = DateTime(end.year, end.month, end.day);
  return endDay.difference(startDay).inDays + 1;
}

int _compareStatsHigh(
  TimesheetEmployeeAttendanceStat a,
  TimesheetEmployeeAttendanceStat b,
) {
  final byDays = b.workedDays.compareTo(a.workedDays);
  if (byDays != 0) return byDays;
  final byHours = b.totalHours.compareTo(a.totalHours);
  if (byHours != 0) return byHours;
  return a.displayName.compareTo(b.displayName);
}

int _compareStatsLow(
  TimesheetEmployeeAttendanceStat a,
  TimesheetEmployeeAttendanceStat b,
) {
  final byDays = a.workedDays.compareTo(b.workedDays);
  if (byDays != 0) return byDays;
  final byHours = a.totalHours.compareTo(b.totalHours);
  if (byHours != 0) return byHours;
  return a.displayName.compareTo(b.displayName);
}

/// Считает топ посещаемости за период по тем же правилам видимости, что сетка табеля
/// (без сегмента «С часами / Без часов» и без поиска по ФИО).
TimesheetAttendanceStatsResult computeTimesheetAttendanceStats({
  required List<Employee> employees,
  required List<TimesheetEntry> entries,
  required DateTime startDate,
  required DateTime endDate,
  required bool hasObjectFilter,
  Set<String> positionKeys = const {},
  int topCount = 5,
}) {
  if (employees.isEmpty || topCount <= 0) {
    return TimesheetAttendanceStatsResult.empty;
  }

  final hoursIndex = TimesheetHoursIndex.fromEntries(entries);
  var visible = visibleTimesheetGridEmployees(
    employees: employees,
    hoursIndex: hoursIndex,
    hasObjectFilter: hasObjectFilter,
    listScope: TimesheetEmployeeListScope.all,
  );
  visible = filterEmployeesByTimesheetPositionKeys(visible, positionKeys);

  if (visible.isEmpty) {
    return TimesheetAttendanceStatsResult.empty;
  }

  final totalDays = _inclusiveCalendarDays(startDate, endDate);
  final workedDaysByEmployee = <String, Set<String>>{};
  final hoursByEmployee = <String, num>{};

  for (final entry in entries) {
    if (entry.hours <= 0) continue;
    hoursByEmployee[entry.employeeId] =
        (hoursByEmployee[entry.employeeId] ?? 0) + entry.hours;
    workedDaysByEmployee
        .putIfAbsent(entry.employeeId, () => <String>{})
        .add(_dateKey(entry.date));
  }

  final stats = <TimesheetEmployeeAttendanceStat>[];
  for (final employee in visible) {
    final workedDays = workedDaysByEmployee[employee.id]?.length ?? 0;
    final positionRaw = employee.position?.trim();
    stats.add(
      TimesheetEmployeeAttendanceStat(
        employeeId: employee.id,
        displayName: formatFullName(
          employee.lastName,
          employee.firstName,
          employee.middleName,
        ),
        position: positionRaw == null || positionRaw.isEmpty
            ? null
            : positionRaw,
        workedDays: workedDays,
        totalDaysInPeriod: totalDays,
        totalHours: hoursByEmployee[employee.id] ?? 0,
      ),
    );
  }

  final sortedHigh = List<TimesheetEmployeeAttendanceStat>.from(stats)
    ..sort(_compareStatsHigh);
  final sortedLow = List<TimesheetEmployeeAttendanceStat>.from(stats)
    ..sort(_compareStatsLow);

  final limit = topCount.clamp(0, stats.length);

  return TimesheetAttendanceStatsResult(
    topHighAttendance: sortedHigh.take(limit).toList(growable: false),
    topLowAttendance: sortedLow.take(limit).toList(growable: false),
    totalEmployeesConsidered: stats.length,
  );
}
