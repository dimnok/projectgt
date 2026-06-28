import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/domain/entities/employee.dart';

import '../../domain/entities/timesheet_entry.dart';
import '../../domain/timesheet_today_open_shift.dart';

part 'timesheet_state.freezed.dart';

/// Состояние экрана табеля рабочего времени.
@freezed
abstract class TimesheetState with _$TimesheetState {
  /// Создаёт [TimesheetState].
  const factory TimesheetState({
    /// Записи табеля за выбранный период.
    @Default([]) List<TimesheetEntry> entries,

    /// Справочник сотрудников компании (загружается вместе с табелем).
    @Default([]) List<Employee> employees,

    /// Идёт загрузка данных с сервера.
    @Default(false) bool isLoading,

    /// Текст ошибки загрузки.
    String? error,

    /// Начало периода (включительно).
    required DateTime startDate,

    /// Конец периода (включительно).
    required DateTime endDate,

    /// Выбранные объекты для клиентского фильтра (`null` — без фильтра).
    List<String>? selectedObjectIds,

    /// Назначения в открытых сменах на сегодня (контроль выхода).
    @Default(TimesheetTodayOpenShiftIndex.empty)
    TimesheetTodayOpenShiftIndex todayOpenShift,
  }) = _TimesheetState;

  /// Начальное состояние: текущий календарный месяц.
  factory TimesheetState.initial() {
    final now = DateTime.now();
    return TimesheetState(
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month + 1, 0),
    );
  }
}
