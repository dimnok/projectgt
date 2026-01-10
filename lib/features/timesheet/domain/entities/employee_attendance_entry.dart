import 'package:freezed_annotation/freezed_annotation.dart';

part 'employee_attendance_entry.freezed.dart';
part 'employee_attendance_entry.g.dart';

/// Типы посещаемости сотрудника
enum AttendanceType {
  /// Работа
  @JsonValue('work')
  work,

  /// Отпуск
  @JsonValue('vacation')
  vacation,

  /// Больничный
  @JsonValue('sick_leave')
  sickLeave,

  /// Командировка
  @JsonValue('business_trip')
  businessTrip,

  /// Выходной
  @JsonValue('day_off')
  dayOff,
}

/// Доменная сущность записи посещаемости сотрудника (вне смен).
///
/// Используется для учёта рабочего времени:
/// - Постоянного персонала объектов (охрана, дежурные инженеры)
/// - Офисных сотрудников (бухгалтеры, менеджеры, HR)
/// - Других категорий сотрудников, не участвующих в сменах
@freezed
abstract class EmployeeAttendanceEntry with _$EmployeeAttendanceEntry {
  /// Основной конструктор [EmployeeAttendanceEntry].
  const factory EmployeeAttendanceEntry({
    /// Уникальный идентификатор записи
    required String id,

    /// ID компании
    required String companyId,

    /// ID сотрудника
    required String employeeId,

    /// ID объекта (ЦОД Дубна, Офис, Склад и т.д.)
    required String objectId,

    /// Дата работы
    required DateTime date,

    /// Количество отработанных часов
    required num hours,

    /// Тип посещаемости
    @Default(AttendanceType.work) AttendanceType attendanceType,

    /// Комментарий к записи
    String? comment,

    /// Кто создал запись
    String? createdBy,

    /// Дата и время создания записи
    DateTime? createdAt,

    /// Дата и время последнего обновления записи
    DateTime? updatedAt,

    // Обогащённые данные (не из БД)
    /// ФИО сотрудника
    String? employeeName,

    /// Должность сотрудника
    String? employeePosition,

    /// Название объекта
    String? objectName,
  }) = _EmployeeAttendanceEntry;

  /// Создание из JSON
  factory EmployeeAttendanceEntry.fromJson(Map<String, dynamic> json) =>
      _$EmployeeAttendanceEntryFromJson(json);
}
