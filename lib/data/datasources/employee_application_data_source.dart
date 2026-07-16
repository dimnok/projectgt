import 'package:projectgt/data/models/employee_application_model.dart';
import 'package:projectgt/domain/entities/employee_application.dart';

/// Источник данных заявлений сотрудников (PostgREST + Storage).
abstract class EmployeeApplicationDataSource {
  /// Список заявлений сотрудника.
  Future<List<EmployeeApplicationModel>> getByEmployee(String employeeId);

  /// Загружает скан и создаёт запись.
  Future<EmployeeApplicationModel> uploadSignedScan({
    required String employeeId,
    required EmployeeApplicationType applicationType,
    required DateTime startDate,
    DateTime? endDate,
    required int durationDays,
    required List<int> bytes,
    required String fileName,
    required String contentType,
    required String createdBy,
  });

  /// Скачивает файл из Storage.
  Future<List<int>> downloadScan(String scanPath);

  /// Удаляет запись и файл.
  Future<void> delete(String applicationId, String scanPath);
}
