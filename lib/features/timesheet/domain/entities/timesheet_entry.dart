import 'package:freezed_annotation/freezed_annotation.dart';

part 'timesheet_entry.freezed.dart';
part 'timesheet_entry.g.dart';

/// Сущность записи в табеле рабочего времени сотрудника.
///
/// Представляет собой запись рабочих часов сотрудника с привязкой к смене (workId), объекту и дополнительной информацией для отображения.
@freezed
abstract class TimesheetEntry with _$TimesheetEntry {
  @JsonSerializable(fieldRename: FieldRename.snake)
  /// Создаёт сущность записи в табеле рабочего времени сотрудника.
  ///
  /// [id] — идентификатор записи (совпадает с id в work_hours)
  /// [workId] — идентификатор смены
  /// [employeeId] — идентификатор сотрудника
  /// [hours] — количество отработанных часов
  /// [comment] — комментарий к записи (опционально)
  /// [date] — дата смены (добавляется из works)
  /// [objectId] — идентификатор объекта (добавляется из works)
  /// [employeeName] — имя сотрудника для отображения (опционально)
  /// [objectName] — название объекта для отображения (опционально)
  /// [employeePosition] — должность сотрудника (опционально)
  /// [createdAt] — дата создания записи (опционально)
  /// [updatedAt] — дата обновления записи (опционально)
  const factory TimesheetEntry({
    /// Идентификатор записи (совпадает с id в work_hours).
    required String id,
    /// Идентификатор смены.
    required String workId,
    /// Идентификатор сотрудника.
    required String employeeId,
    /// Количество отработанных часов.
    required num hours,
    /// Комментарий к записи.
    String? comment,
    /// Дата смены (не хранится в work_hours, добавляется из works).
    required DateTime date,
    /// Идентификатор объекта (не хранится в work_hours, добавляется из works).
    required String objectId,
    /// Имя сотрудника для отображения (не хранится в БД).
    String? employeeName,
    /// Название объекта для отображения (не хранится в БД).
    String? objectName,
    /// Должность сотрудника (не хранится в БД).
    String? employeePosition,
    /// Дата создания записи.
    DateTime? createdAt,
    /// Дата обновления записи.
    DateTime? updatedAt,
  }) = _TimesheetEntry;

  /// Создаёт сущность записи в табеле рабочего времени сотрудника из JSON.
  factory TimesheetEntry.fromJson(Map<String, dynamic> json) => _$TimesheetEntryFromJson(json);
} 