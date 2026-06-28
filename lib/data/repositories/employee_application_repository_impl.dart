import 'package:projectgt/data/datasources/employee_application_data_source.dart';
import 'package:projectgt/domain/entities/employee_application.dart';
import 'package:projectgt/domain/repositories/employee_application_repository.dart';

/// Реализация [EmployeeApplicationRepository].
class EmployeeApplicationRepositoryImpl
    implements EmployeeApplicationRepository {
  /// Источник данных.
  final EmployeeApplicationDataSource dataSource;

  /// ID текущего пользователя (profiles.id).
  final String currentUserId;

  /// Создаёт репозиторий.
  EmployeeApplicationRepositoryImpl({
    required this.dataSource,
    required this.currentUserId,
  });

  @override
  Future<List<EmployeeApplication>> getByEmployee(String employeeId) async {
    final models = await dataSource.getByEmployee(employeeId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<EmployeeApplication> uploadSignedScan({
    required String employeeId,
    required EmployeeApplicationType applicationType,
    required DateTime startDate,
    DateTime? endDate,
    required int durationDays,
    required List<int> bytes,
    required String fileName,
    required String contentType,
  }) async {
    final model = await dataSource.uploadSignedScan(
      employeeId: employeeId,
      applicationType: applicationType,
      startDate: startDate,
      endDate: endDate,
      durationDays: durationDays,
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
      createdBy: currentUserId,
    );
    return model.toEntity();
  }

  @override
  Future<List<int>> downloadScan(String scanPath) {
    return dataSource.downloadScan(scanPath);
  }

  @override
  Future<void> delete(String applicationId, String scanPath) {
    return dataSource.delete(applicationId, scanPath);
  }
}
