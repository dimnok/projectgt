import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/domain/repositories/employee_repository.dart';

/// UseCase для получения списка всех сотрудников.
///
/// Используется для загрузки списка сотрудников через [EmployeeRepository].
///
/// Пример использования:
/// ```dart
/// final useCase = GetEmployeesUseCase(employeeRepository);
/// final employees = await useCase.execute();
/// print(employees.length);
/// ```
///
/// Возвращает список [Employee].
/// Бросает [Exception] при ошибке.
class GetEmployeesUseCase {
  /// Репозиторий сотрудников для получения данных.
  final EmployeeRepository repository;

  /// Создаёт use case с указанным репозиторием.
  GetEmployeesUseCase(this.repository);

  /// Получение списка всех сотрудников.
  ///
  /// Возвращает список [Employee].
  /// Бросает [Exception] при ошибке.
  Future<List<Employee>> execute() async {
    return await repository.getEmployees();
  }
} 