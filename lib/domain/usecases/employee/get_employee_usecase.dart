import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/domain/repositories/employee_repository.dart';

/// UseCase для получения сотрудника по идентификатору.
///
/// Используется для поиска сотрудника по id через [EmployeeRepository].
///
/// Пример использования:
/// ```dart
/// final useCase = GetEmployeeUseCase(employeeRepository);
/// final employee = await useCase.execute('employeeId');
/// if (employee != null) print(employee.firstName);
/// ```
///
/// [id] — идентификатор сотрудника.
/// Возвращает [Employee] или null, если не найден.
/// Бросает [Exception] при ошибке.
class GetEmployeeUseCase {
  /// Репозиторий сотрудников для получения данных.
  final EmployeeRepository repository;

  /// Создаёт use case с указанным репозиторием.
  GetEmployeeUseCase(this.repository);

  /// Получение сотрудника по id.
  ///
  /// [id] — идентификатор сотрудника.
  /// Возвращает [Employee] или null, если не найден.
  /// Бросает [Exception] при ошибке.
  Future<Employee?> execute(String id) async {
    return await repository.getEmployee(id);
  }
} 