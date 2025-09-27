import 'package:projectgt/domain/entities/employee.dart';

/// Абстракция репозитория для работы с сотрудниками.
abstract class EmployeeRepository {
  /// Получи список всех сотрудников.
  ///
  /// Возвращает список [Employee]. Бросает [Exception] при ошибке.
  Future<List<Employee>> getEmployees();

  /// Получи сотрудника по [id].
  ///
  /// Возвращает [Employee] или null, если не найден. Бросает [Exception] при ошибке.
  Future<Employee?> getEmployee(String id);

  /// Создай нового сотрудника [employee] в источнике данных.
  ///
  /// Возвращает созданного [Employee]. Бросает [Exception] при ошибке.
  Future<Employee> createEmployee(Employee employee);

  /// Обнови сотрудника [employee] в источнике данных.
  ///
  /// Возвращает обновлённого [Employee]. Бросает [Exception] при ошибке.
  Future<Employee> updateEmployee(Employee employee);

  /// Удали сотрудника по [id].
  ///
  /// Возвращает void. Бросает [Exception] при ошибке.
  Future<void> deleteEmployee(String id);

  /// Получить уникальные должности сотрудников
  Future<List<String>> getPositions();
}
