import '../entities/employee_attendance_entry.dart';

/// Абстракция репозитория для работы с посещаемостью сотрудников.
abstract class EmployeeAttendanceRepository {
  /// Получить записи посещаемости за период с обогащением данными.
  Future<List<EmployeeAttendanceEntry>> getAttendanceRecords({
    DateTime? startDate,
    DateTime? endDate,
    String? employeeId,
    String? objectId,
  });

  /// Создать запись посещаемости.
  Future<EmployeeAttendanceEntry> createAttendance(
      EmployeeAttendanceEntry entry);

  /// Обновить запись посещаемости.
  Future<EmployeeAttendanceEntry> updateAttendance(
      EmployeeAttendanceEntry entry);

  /// Удалить запись посещаемости.
  Future<void> deleteAttendance(String id);

  /// Получить запись посещаемости по ID.
  Future<EmployeeAttendanceEntry?> getAttendanceById(String id);

  /// Массовое создание/обновление записей посещаемости.
  ///
  /// Используется для быстрого заполнения часов в календаре.
  /// Возвращает список созданных/обновлённых записей.
  Future<List<EmployeeAttendanceEntry>> batchUpsertAttendance(
      List<EmployeeAttendanceEntry> entries);
}
