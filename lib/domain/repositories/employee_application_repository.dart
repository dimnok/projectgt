import 'package:projectgt/domain/entities/employee_application.dart';

/// Репозиторий заявлений сотрудников (подписанные сканы).
abstract class EmployeeApplicationRepository {
  /// Список заявлений сотрудника, от новых к старым.
  Future<List<EmployeeApplication>> getByEmployee(String employeeId);

  /// Загружает подписанный скан и создаёт запись заявления.
  Future<EmployeeApplication> uploadSignedScan({
    required String employeeId,
    required EmployeeApplicationType applicationType,
    required DateTime startDate,
    DateTime? endDate,
    required int durationDays,
    required List<int> bytes,
    required String fileName,
    required String contentType,
  });

  /// Скачивает байты скана из Storage.
  Future<List<int>> downloadScan(String scanPath);

  /// Удаляет заявление и файл из Storage.
  Future<void> delete(String applicationId, String scanPath);
}
