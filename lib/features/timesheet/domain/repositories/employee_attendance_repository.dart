import '../entities/employee_attendance_entry.dart';

/// Репозиторий ручной посещаемости сотрудников (вне смен).
abstract class EmployeeAttendanceRepository {
  /// Записи посещаемости за период.
  ///
  /// [objectIds] — при непустом списке только записи на этих объектах.
  Future<List<EmployeeAttendanceEntry>> getAttendanceRecords({
    DateTime? startDate,
    DateTime? endDate,
    String? employeeId,
    List<String>? objectIds,
  });

  /// Пакетный upsert через RPC `upsert_employee_attendance_batch`.
  Future<void> batchUpsertAttendance(List<EmployeeAttendanceEntry> entries);
}
