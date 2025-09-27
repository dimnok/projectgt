import 'package:projectgt/domain/repositories/employee_repository.dart';

/// UseCase для удаления сотрудника по идентификатору через репозиторий.
class DeleteEmployeeUseCase {
  /// Репозиторий сотрудников для удаления данных.
  final EmployeeRepository repository;

  /// Создаёт use case с указанным репозиторием.
  DeleteEmployeeUseCase(this.repository);

  /// Удали сотрудника по [id].
  ///
  /// Возвращает void. Бросает [Exception] при ошибке.
  Future<void> execute(String id) async {
    return await repository.deleteEmployee(id);
  }
}
