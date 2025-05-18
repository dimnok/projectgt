import 'package:freezed_annotation/freezed_annotation.dart';

part 'timesheet_entry_model.freezed.dart';
part 'timesheet_entry_model.g.dart';

/// Data-модель для записи в табеле рабочего времени.
///
/// Используется для сериализации/десериализации данных при работе с API и хранения информации о часах сотрудника за смену.
@freezed
abstract class TimesheetEntryModel with _$TimesheetEntryModel {
  @JsonSerializable(fieldRename: FieldRename.snake)
  /// Создаёт data-модель записи в табеле рабочего времени.
  ///
  /// [id] — идентификатор записи
  /// [workId] — идентификатор смены
  /// [employeeId] — идентификатор сотрудника
  /// [hours] — количество отработанных часов
  /// [comment] — комментарий к записи (опционально)
  /// [date] — дата смены
  /// [objectId] — идентификатор объекта
  /// [employeeName] — имя сотрудника для отображения (опционально)
  /// [objectName] — название объекта для отображения (опционально)
  /// [createdAt] — дата создания записи (опционально)
  /// [updatedAt] — дата обновления записи (опционально)
  const factory TimesheetEntryModel({
    /// Идентификатор записи.
    required String id,
    /// Идентификатор смены.
    required String workId,
    /// Идентификатор сотрудника.
    required String employeeId,
    /// Количество отработанных часов.
    required num hours,
    /// Комментарий к записи.
    String? comment,
    /// Дата смены.
    required DateTime date,
    /// Идентификатор объекта.
    required String objectId,
    /// Имя сотрудника для отображения.
    String? employeeName,
    /// Название объекта для отображения.
    String? objectName,
    /// Дата создания записи.
    DateTime? createdAt,
    /// Дата обновления записи.
    DateTime? updatedAt,
  }) = _TimesheetEntryModel;

  /// Создаёт data-модель записи в табеле рабочего времени из JSON.
  factory TimesheetEntryModel.fromJson(Map<String, dynamic> json) => _$TimesheetEntryModelFromJson(json);
} 