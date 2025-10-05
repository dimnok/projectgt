import '../../entities/employee_rate.dart';
import '../../repositories/employee_rate_repository.dart';

/// Use case для получения истории ставок сотрудника
class GetEmployeeRatesUseCase {
  final EmployeeRateRepository _repository;

  const GetEmployeeRatesUseCase(this._repository);

  /// Получает историю всех ставок сотрудника
  ///
  /// [employeeId] — идентификатор сотрудника
  ///
  /// Возвращает список всех ставок сотрудника, отсортированный по дате начала действия (новые первыми)
  Future<List<EmployeeRate>> call(String employeeId) async {
    return await _repository.getEmployeeRates(employeeId);
  }
}
