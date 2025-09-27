import 'package:freezed_annotation/freezed_annotation.dart';

part 'timesheet_summary.freezed.dart';
part 'timesheet_summary.g.dart';

/// Сущность для агрегированных данных по часам сотрудника.
///
/// Используется для отображения сводки по часам сотрудника с разбивкой по датам и объектам.
@freezed
abstract class TimesheetSummary with _$TimesheetSummary {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)

  /// Создаёт сущность агрегированных данных по часам сотрудника.
  ///
  /// [employeeId] — идентификатор сотрудника
  /// [employeeName] — полное имя сотрудника
  /// [hoursByDate] — часы по датам: {'2023-05-01': 8, ...}
  /// [hoursByObject] — часы по объектам: {'Объект 1': 40, ...}
  /// [totalHours] — общее количество часов
  const factory TimesheetSummary({
    /// Идентификатор сотрудника.
    required String employeeId,

    /// Полное имя сотрудника.
    required String employeeName,

    /// Часы по датам: {'2023-05-01': 8, ...}.
    required Map<String, num> hoursByDate,

    /// Часы по объектам: {'Объект 1': 40, ...}.
    required Map<String, num> hoursByObject,

    /// Общее количество часов.
    required num totalHours,
  }) = _TimesheetSummary;

  /// Создаёт сущность агрегированных данных по часам сотрудника из JSON.
  factory TimesheetSummary.fromJson(Map<String, dynamic> json) =>
      _$TimesheetSummaryFromJson(json);
}
