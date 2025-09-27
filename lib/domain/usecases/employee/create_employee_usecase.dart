import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/domain/repositories/employee_repository.dart';

/// UseCase для создания нового сотрудника.
///
/// Используется для добавления сотрудника через [EmployeeRepository].
///
/// Пример использования:
/// ```dart
/// final useCase = CreateEmployeeUseCase(employeeRepository);
/// final employee = await useCase.execute(employee);
/// ```
///
/// [employee] — данные сотрудника.
/// Возвращает созданного [Employee].
/// Бросает [Exception] при ошибке.
class CreateEmployeeUseCase {
  /// Репозиторий сотрудников для создания данных.
  final EmployeeRepository repository;

  /// Создаёт use case с указанным репозиторием.
  CreateEmployeeUseCase(this.repository);

  /// Создание нового сотрудника.
  ///
  /// [employee] — данные сотрудника.
  /// Возвращает созданного [Employee].
  /// Бросает [Exception] при ошибке.
  Future<Employee> execute(Employee employee) async {
    return await repository.createEmployee(employee);
  }
}
