import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/domain/repositories/employee_repository.dart';

/// UseCase для обновления данных сотрудника.
///
/// Используется для обновления информации о сотруднике через [EmployeeRepository].
///
/// Пример использования:
/// ```dart
/// final useCase = UpdateEmployeeUseCase(employeeRepository);
/// final updated = await useCase.execute(employee.copyWith(firstName: 'НовоеИмя'));
/// ```
///
/// [employee] — обновлённые данные сотрудника.
/// Возвращает обновлённого [Employee].
/// Бросает [Exception] при ошибке.
class UpdateEmployeeUseCase {
  /// Репозиторий сотрудников для обновления данных.
  final EmployeeRepository repository;

  /// Создаёт use case с указанным репозиторием.
  UpdateEmployeeUseCase(this.repository);

  /// Обновление сотрудника.
  ///
  /// [employee] — обновлённые данные сотрудника.
  /// Возвращает обновлённого [Employee].
  /// Бросает [Exception] при ошибке.
  Future<Employee> execute(Employee employee) async {
    return await repository.updateEmployee(employee);
  }
} 