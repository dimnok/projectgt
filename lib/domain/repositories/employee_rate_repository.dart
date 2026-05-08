import '../entities/employee_rate.dart';

/// Репозиторий для работы со ставками сотрудников
abstract class EmployeeRateRepository {
  /// Получить все ставки сотрудника (включая историю)
  Future<List<EmployeeRate>> getEmployeeRates(String employeeId);

  /// Получить текущую активную ставку сотрудника
  Future<EmployeeRate?> getCurrentRate(String employeeId);

  /// Получить ставку сотрудника на конкретную дату
  Future<double> getRateForDate(String employeeId, DateTime date);

  /// Установить новую ставку сотрудника
  /// Автоматически закрывает предыдущую ставку и создаёт новую
  Future<void> setNewRate(String employeeId, double rate, DateTime validFrom);

  /// Найти все ставки сотрудника, период действия которых пересекается
  /// с открытым полуинтервалом [validFrom, +∞).
  ///
  /// Используется UI для предупреждения пользователя о пересечениях
  /// перед сохранением новой ставки.
  Future<List<EmployeeRate>> findOverlappingRates(
    String employeeId,
    DateTime validFrom,
  );
}
