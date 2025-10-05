import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/employee_attendance_entry.dart';

part 'employee_attendance_model.freezed.dart';
part 'employee_attendance_model.g.dart';

/// Data-модель записи посещаемости сотрудника для сериализации/десериализации.
@freezed
abstract class EmployeeAttendanceModel with _$EmployeeAttendanceModel {
  /// Основной конструктор [EmployeeAttendanceModel].
  const factory EmployeeAttendanceModel({
    required String id,
    @JsonKey(name: 'employee_id') required String employeeId,
    @JsonKey(name: 'object_id') required String objectId,
    required String date,
    required num hours,
    @JsonKey(name: 'attendance_type')
    @Default(AttendanceType.work)
    AttendanceType attendanceType,
    String? comment,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
  }) = _EmployeeAttendanceModel;

  /// Создание из JSON (Supabase)
  factory EmployeeAttendanceModel.fromJson(Map<String, dynamic> json) =>
      _$EmployeeAttendanceModelFromJson(json);
}

/// Extension для преобразования между моделью и доменной сущностью
extension EmployeeAttendanceModelX on EmployeeAttendanceModel {
  /// Преобразование в доменную сущность
  EmployeeAttendanceEntry toDomain() {
    return EmployeeAttendanceEntry(
      id: id,
      employeeId: employeeId,
      objectId: objectId,
      date: DateTime.parse(date),
      hours: hours,
      attendanceType: attendanceType,
      comment: comment,
      createdBy: createdBy,
      createdAt: createdAt != null ? DateTime.parse(createdAt!) : null,
      updatedAt: updatedAt != null ? DateTime.parse(updatedAt!) : null,
    );
  }
}

/// Helper для создания модели из доменной сущности
EmployeeAttendanceModel employeeAttendanceModelFromDomain(
    EmployeeAttendanceEntry entry) {
  return EmployeeAttendanceModel(
    id: entry.id,
    employeeId: entry.employeeId,
    objectId: entry.objectId,
    date: entry.date.toIso8601String().split('T')[0], // Только дата
    hours: entry.hours,
    attendanceType: entry.attendanceType,
    comment: entry.comment,
    createdBy: entry.createdBy,
    createdAt: entry.createdAt?.toIso8601String(),
    updatedAt: entry.updatedAt?.toIso8601String(),
  );
}
