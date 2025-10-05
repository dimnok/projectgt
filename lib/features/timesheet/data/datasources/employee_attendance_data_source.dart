import '../models/employee_attendance_model.dart';

/// Абстракция источника данных для работы с посещаемостью сотрудников.
abstract class EmployeeAttendanceDataSource {
  /// Получить записи посещаемости за период.
  ///
  /// Параметры:
  /// - [startDate] — дата начала периода
  /// - [endDate] — дата окончания периода
  /// - [employeeId] — ID сотрудника (опционально)
  /// - [objectId] — ID объекта (опционально)
  Future<List<EmployeeAttendanceModel>> getAttendanceRecords({
    DateTime? startDate,
    DateTime? endDate,
    String? employeeId,
    String? objectId,
  });

  /// Создать запись посещаемости.
  Future<EmployeeAttendanceModel> createAttendance(
      EmployeeAttendanceModel model);

  /// Обновить запись посещаемости.
  Future<EmployeeAttendanceModel> updateAttendance(
      EmployeeAttendanceModel model);

  /// Удалить запись посещаемости.
  Future<void> deleteAttendance(String id);

  /// Получить запись посещаемости по ID.
  Future<EmployeeAttendanceModel?> getAttendanceById(String id);

  /// Массовое создание/обновление записей посещаемости.
  ///
  /// Используется для быстрого заполнения часов в календаре.
  Future<void> batchUpsertAttendance(List<EmployeeAttendanceModel> models);
}
