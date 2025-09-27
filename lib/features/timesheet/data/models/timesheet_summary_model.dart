import 'package:freezed_annotation/freezed_annotation.dart';

part 'timesheet_summary_model.freezed.dart';
part 'timesheet_summary_model.g.dart';

/// Data-модель для сводки часов сотрудника.
///
/// Используется для сериализации/десериализации данных при работе с API и хранения агрегированных данных по часам.
@freezed
abstract class TimesheetSummaryModel with _$TimesheetSummaryModel {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)

  /// Создаёт data-модель сводки часов сотрудника.
  ///
  /// [employeeId] — идентификатор сотрудника
  /// [employeeName] — полное имя сотрудника
  /// [hoursByDate] — часы по датам: {'2023-05-01': 8, ...}
  /// [hoursByObject] — часы по объектам: {'Объект 1': 40, ...}
  /// [totalHours] — общее количество часов
  const factory TimesheetSummaryModel({
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
  }) = _TimesheetSummaryModel;

  /// Создаёт data-модель сводки часов сотрудника из JSON.
  factory TimesheetSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$TimesheetSummaryModelFromJson(json);
}
