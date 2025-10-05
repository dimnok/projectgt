import '../../repositories/employee_rate_repository.dart';

/// Use case для получения ставки сотрудника на конкретную дату
class GetEmployeeRateForDateUseCase {
  final EmployeeRateRepository _repository;

  const GetEmployeeRateForDateUseCase(this._repository);

  /// Получает ставку сотрудника на указанную дату
  ///
  /// [employeeId] — идентификатор сотрудника
  /// [date] — дата, на которую нужно получить ставку
  ///
  /// Возвращает почасовую ставку в рублях или 0, если ставка не найдена
  Future<double> call(String employeeId, DateTime date) async {
    return await _repository.getRateForDate(employeeId, date);
  }
}
