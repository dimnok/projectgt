import '../models/employee_attendance_model.dart';

/// Источник данных таблицы `employee_attendance`.
abstract class EmployeeAttendanceDataSource {
  /// Записи посещаемости за период.
  ///
  /// [objectIds] — при непустом списке только записи на этих объектах.
  Future<List<EmployeeAttendanceModel>> getAttendanceRecords({
    DateTime? startDate,
    DateTime? endDate,
    String? employeeId,
    List<String>? objectIds,
  });

  /// Пакетный upsert через RPC `upsert_employee_attendance_batch`.
  Future<void> batchUpsertAttendance(List<EmployeeAttendanceModel> models);
}
