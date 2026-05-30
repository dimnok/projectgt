import '../../domain/entities/employee_attendance_entry.dart';
import '../../domain/repositories/employee_attendance_repository.dart';
import '../datasources/employee_attendance_data_source.dart';
import '../models/employee_attendance_model.dart';

/// Реализация [EmployeeAttendanceRepository].
class EmployeeAttendanceRepositoryImpl implements EmployeeAttendanceRepository {
  /// Источник данных для посещаемости.
  final EmployeeAttendanceDataSource dataSource;

  /// Создаёт [EmployeeAttendanceRepositoryImpl].
  EmployeeAttendanceRepositoryImpl({required this.dataSource});

  @override
  Future<List<EmployeeAttendanceEntry>> getAttendanceRecords({
    DateTime? startDate,
    DateTime? endDate,
    String? employeeId,
    List<String>? objectIds,
  }) async {
    final models = await dataSource.getAttendanceRecords(
      startDate: startDate,
      endDate: endDate,
      employeeId: employeeId,
      objectIds: objectIds,
    );
    return models.map((model) => model.toDomain()).toList();
  }

  @override
  Future<void> batchUpsertAttendance(
    List<EmployeeAttendanceEntry> entries,
  ) async {
    if (entries.isEmpty) return;
    final models =
        entries.map((e) => employeeAttendanceModelFromDomain(e)).toList();
    await dataSource.batchUpsertAttendance(models);
  }
}
