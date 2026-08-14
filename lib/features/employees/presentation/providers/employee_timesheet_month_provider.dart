import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:projectgt/features/timesheet/presentation/providers/repositories_providers.dart';

/// Ключ загрузки табеля одного сотрудника за календарный месяц.
@immutable
class EmployeeTimesheetMonthKey {
  /// Создаёт ключ для [employeeId] и месяца [monthStart] (день игнорируется).
  const EmployeeTimesheetMonthKey({
    required this.employeeId,
    required this.monthStart,
  });

  /// Идентификатор сотрудника.
  final String employeeId;

  /// Первое число выбранного месяца.
  final DateTime monthStart;

  /// Год месяца.
  int get year => monthStart.year;

  /// Номер месяца (1–12).
  int get month => monthStart.month;

  /// Начало периода (00:00 первого дня).
  DateTime get startDate => DateTime(year, month, 1);

  /// Конец периода (последний день месяца).
  DateTime get endDate => DateTime(year, month + 1, 0);

  @override
  bool operator ==(Object other) {
    return other is EmployeeTimesheetMonthKey &&
        other.employeeId == employeeId &&
        other.year == year &&
        other.month == month;
  }

  @override
  int get hashCode => Object.hash(employeeId, year, month);
}

/// Часы сотрудника на одном объекте (день или итог за месяц).
@immutable
class EmployeeTimesheetObjectHours {
  /// Создаёт срез часов по [objectId].
  const EmployeeTimesheetObjectHours({
    required this.objectId,
    required this.hours,
  });

  /// Идентификатор объекта.
  final String objectId;

  /// Сумма часов на объекте.
  final num hours;
}

/// Примечание к дню на конкретном объекте.
@immutable
class EmployeeTimesheetDayComment {
  /// Создаёт примечание с текстом [text] на [objectId].
  const EmployeeTimesheetDayComment({
    required this.objectId,
    required this.text,
  });

  /// Идентификатор объекта, к которому относится примечание.
  final String objectId;

  /// Текст примечания без пробелов по краям.
  final String text;
}

/// Агрегированные часы сотрудника за месяц для вкладки «Табель».
@immutable
class EmployeeTimesheetMonthData {
  /// Создаёт сводку по дням.
  const EmployeeTimesheetMonthData({
    required this.shiftHoursByDay,
    required this.manualHoursByDay,
    required this.hoursByObjectByDay,
    required this.commentsByDay,
  });

  /// Часы из закрытых смен по дням (сумма за день).
  final Map<DateTime, num> shiftHoursByDay;

  /// Ручные часы посещаемости по дням (сумма по объектам за день).
  final Map<DateTime, num> manualHoursByDay;

  /// Часы по объектам за каждый день (смены + ручной ввод).
  final Map<DateTime, List<EmployeeTimesheetObjectHours>> hoursByObjectByDay;

  /// Уникальные примечания за день (смены + ручной ввод).
  final Map<DateTime, List<EmployeeTimesheetDayComment>> commentsByDay;

  /// Пустая сводка.
  static const empty = EmployeeTimesheetMonthData(
    shiftHoursByDay: {},
    manualHoursByDay: {},
    hoursByObjectByDay: {},
    commentsByDay: {},
  );

  /// Сумма часов из смен.
  num get shiftTotal =>
      shiftHoursByDay.values.fold<num>(0, (sum, h) => sum + h);

  /// Сумма ручных часов.
  num get manualTotal =>
      manualHoursByDay.values.fold<num>(0, (sum, h) => sum + h);

  /// Всего часов за месяц.
  num get totalHours => shiftTotal + manualTotal;

  /// Число дней, в которых есть хотя бы одни часы.
  int get daysWithHours {
    final days = <DateTime>{...shiftHoursByDay.keys, ...manualHoursByDay.keys};
    return days.where((d) => dayTotal(d) > 0).length;
  }

  /// Сумма часов за [day] (смены + ручной ввод).
  num dayTotal(DateTime day) {
    final key = _normalizeDate(day);
    return (shiftHoursByDay[key] ?? 0) + (manualHoursByDay[key] ?? 0);
  }

  /// Часы из смен за [day].
  num shiftHours(DateTime day) => shiftHoursByDay[_normalizeDate(day)] ?? 0;

  /// Ручные часы за [day].
  num manualHours(DateTime day) => manualHoursByDay[_normalizeDate(day)] ?? 0;

  /// Срезы часов по объектам за [day] (объекты с нулём часов не входят).
  List<EmployeeTimesheetObjectHours> objectsForDay(DateTime day) =>
      hoursByObjectByDay[_normalizeDate(day)] ?? const [];

  /// Примечания за [day] (пустой список, если комментариев нет).
  List<EmployeeTimesheetDayComment> commentsForDay(DateTime day) =>
      commentsByDay[_normalizeDate(day)] ?? const [];

  /// Уникальные объекты месяца с суммой часов, по убыванию часов.
  List<EmployeeTimesheetObjectHours> get objectsLegend {
    final totals = <String, num>{};
    for (final slices in hoursByObjectByDay.values) {
      for (final slice in slices) {
        if (slice.hours <= 0) continue;
        totals[slice.objectId] = (totals[slice.objectId] ?? 0) + slice.hours;
      }
    }
    final list =
        [
          for (final entry in totals.entries)
            EmployeeTimesheetObjectHours(
              objectId: entry.key,
              hours: entry.value,
            ),
        ]..sort((a, b) {
          final byHours = b.hours.compareTo(a.hours);
          if (byHours != 0) return byHours;
          return a.objectId.compareTo(b.objectId);
        });
    return list;
  }
}

DateTime _normalizeDate(DateTime date) =>
    DateTime(date.year, date.month, date.day);

/// Загружает часы одного сотрудника за месяц (смены + ручная посещаемость).
///
/// Запрос выполняется только при подписке (вкладка «Табель» в дереве виджетов).
final employeeTimesheetMonthProvider = FutureProvider.autoDispose
    .family<EmployeeTimesheetMonthData, EmployeeTimesheetMonthKey>((
      ref,
      key,
    ) async {
      final attendanceRepository = ref.watch(
        employeeAttendanceRepositoryProvider,
      );
      final timesheetRepository = ref.watch(timesheetRepositoryProvider);

      final (attendance, shiftEntries) = await (
        attendanceRepository.getAttendanceRecords(
          employeeId: key.employeeId,
          startDate: key.startDate,
          endDate: key.endDate,
        ),
        timesheetRepository.getShiftHoursForEmployee(
          employeeId: key.employeeId,
          startDate: key.startDate,
          endDate: key.endDate,
        ),
      ).wait;

      final shiftHoursByDay = <DateTime, num>{};
      final objectHoursAcc = <DateTime, Map<String, num>>{};
      final commentsAcc = <DateTime, List<EmployeeTimesheetDayComment>>{};
      for (final entry in shiftEntries) {
        final date = _normalizeDate(entry.date);
        shiftHoursByDay[date] = (shiftHoursByDay[date] ?? 0) + entry.hours;
        _addObjectHours(objectHoursAcc, date, entry.objectId, entry.hours);
        _addDayComment(commentsAcc, date, entry.objectId, entry.comment);
      }

      final manualHoursByDay = <DateTime, num>{};
      for (final record in attendance) {
        final date = _normalizeDate(record.date);
        manualHoursByDay[date] = (manualHoursByDay[date] ?? 0) + record.hours;
        _addObjectHours(objectHoursAcc, date, record.objectId, record.hours);
        _addDayComment(commentsAcc, date, record.objectId, record.comment);
      }

      return EmployeeTimesheetMonthData(
        shiftHoursByDay: shiftHoursByDay,
        manualHoursByDay: manualHoursByDay,
        hoursByObjectByDay: _freezeObjectHours(objectHoursAcc),
        commentsByDay: commentsAcc,
      );
    });

void _addDayComment(
  Map<DateTime, List<EmployeeTimesheetDayComment>> acc,
  DateTime date,
  String objectId,
  String? comment,
) {
  final text = comment?.trim();
  if (text == null || text.isEmpty) return;
  final list = acc.putIfAbsent(date, () => <EmployeeTimesheetDayComment>[]);
  final exists = list.any(
    (item) => item.objectId == objectId && item.text == text,
  );
  if (exists) return;
  list.add(EmployeeTimesheetDayComment(objectId: objectId, text: text));
}

void _addObjectHours(
  Map<DateTime, Map<String, num>> acc,
  DateTime date,
  String objectId,
  num hours,
) {
  if (hours <= 0 || objectId.isEmpty) return;
  final byObject = acc.putIfAbsent(date, () => <String, num>{});
  byObject[objectId] = (byObject[objectId] ?? 0) + hours;
}

Map<DateTime, List<EmployeeTimesheetObjectHours>> _freezeObjectHours(
  Map<DateTime, Map<String, num>> acc,
) {
  return {
    for (final entry in acc.entries)
      entry.key: [
        for (final objectEntry in entry.value.entries)
          EmployeeTimesheetObjectHours(
            objectId: objectEntry.key,
            hours: objectEntry.value,
          ),
      ]..sort((a, b) => b.hours.compareTo(a.hours)),
  };
}
