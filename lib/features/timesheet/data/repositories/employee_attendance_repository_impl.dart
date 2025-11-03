import 'package:projectgt/domain/repositories/employee_repository.dart';
import 'package:projectgt/domain/repositories/object_repository.dart';
import '../../domain/entities/employee_attendance_entry.dart';
import '../../domain/repositories/employee_attendance_repository.dart';
import '../datasources/employee_attendance_data_source.dart';
import '../models/employee_attendance_model.dart';

/// Реализация репозитория для работы с посещаемостью сотрудников.
///
/// Выполняет обогащение данных именами сотрудников и названиями объектов.
class EmployeeAttendanceRepositoryImpl implements EmployeeAttendanceRepository {
  /// Источник данных для посещаемости.
  final EmployeeAttendanceDataSource dataSource;

  /// Репозиторий сотрудников для обогащения данных.
  final EmployeeRepository employeeRepository;

  /// Репозиторий объектов для обогащения данных.
  final ObjectRepository objectRepository;

  /// Создает экземпляр [EmployeeAttendanceRepositoryImpl].
  EmployeeAttendanceRepositoryImpl({
    required this.dataSource,
    required this.employeeRepository,
    required this.objectRepository,
  });

  @override
  Future<List<EmployeeAttendanceEntry>> getAttendanceRecords({
    DateTime? startDate,
    DateTime? endDate,
    String? employeeId,
    String? objectId,
  }) async {
    // Получаем данные из источника
    final models = await dataSource.getAttendanceRecords(
      startDate: startDate,
      endDate: endDate,
      employeeId: employeeId,
      objectId: objectId,
    );

    // Просто преобразуем в доменные сущности (без обогащения)
    return models.map((model) => model.toDomain()).toList();
  }

  @override
  Future<EmployeeAttendanceEntry> createAttendance(
      EmployeeAttendanceEntry entry) async {
    final model = employeeAttendanceModelFromDomain(entry);
    final createdModel = await dataSource.createAttendance(model);
    return createdModel.toDomain();
  }

  @override
  Future<EmployeeAttendanceEntry> updateAttendance(
      EmployeeAttendanceEntry entry) async {
    final model = employeeAttendanceModelFromDomain(entry);
    final updatedModel = await dataSource.updateAttendance(model);
    return updatedModel.toDomain();
  }

  @override
  Future<void> deleteAttendance(String id) async {
    await dataSource.deleteAttendance(id);
  }

  @override
  Future<EmployeeAttendanceEntry?> getAttendanceById(String id) async {
    final model = await dataSource.getAttendanceById(id);
    return model?.toDomain();
  }

  @override
  Future<List<EmployeeAttendanceEntry>> batchUpsertAttendance(
      List<EmployeeAttendanceEntry> entries) async {
    final models =
        entries.map((e) => employeeAttendanceModelFromDomain(e)).toList();
    await dataSource.batchUpsertAttendance(models);

    // Возвращаем обогащённые записи
    return getAttendanceRecords(
      employeeId: entries.first.employeeId,
      objectId: entries.first.objectId,
      startDate:
          entries.map((e) => e.date).reduce((a, b) => a.isBefore(b) ? a : b),
      endDate:
          entries.map((e) => e.date).reduce((a, b) => a.isAfter(b) ? a : b),
    );
  }
}
