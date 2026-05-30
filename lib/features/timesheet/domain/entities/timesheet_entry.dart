import 'package:freezed_annotation/freezed_annotation.dart';

part 'timesheet_entry.freezed.dart';

/// Сущность записи в табеле рабочего времени сотрудника.
///
/// Представляет запись рабочих часов с привязкой к смене ([workId]), объекту
/// и полями для отображения (ФИО, объект, должность).
@freezed
abstract class TimesheetEntry with _$TimesheetEntry {
  /// Создаёт запись табеля.
  const factory TimesheetEntry({
    /// Идентификатор записи (`work_hours.id` или `employee_attendance.id`).
    required String id,

    /// Идентификатор смены; для ручной посещаемости совпадает с [id].
    required String workId,

    /// Идентификатор сотрудника.
    required String employeeId,

    /// Количество отработанных часов.
    required num hours,

    /// Комментарий к записи.
    String? comment,

    /// Дата (из `works.date` или `employee_attendance.date`).
    required DateTime date,

    /// Идентификатор объекта.
    required String objectId,

    /// ФИО для отображения (не хранится в БД).
    String? employeeName,

    /// Название объекта для отображения (не хранится в БД).
    String? objectName,

    /// Должность сотрудника (не хранится в БД).
    String? employeePosition,

    /// Дата создания записи.
    DateTime? createdAt,

    /// Дата обновления записи.
    DateTime? updatedAt,

    /// `true` — ручной ввод (`employee_attendance`), `false` — смена (`work_hours`).
    @Default(false) bool isManualEntry,
  }) = _TimesheetEntry;
}
