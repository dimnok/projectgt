import '../../repositories/employee_rate_repository.dart';

/// Use case для установки новой ставки сотрудника
class SetEmployeeRateUseCase {
  final EmployeeRateRepository _repository;

  /// Создаёт экземпляр [SetEmployeeRateUseCase] с заданным [_repository].
  const SetEmployeeRateUseCase(this._repository);

  /// Устанавливает новую ставку для сотрудника
  ///
  /// [employeeId] — идентификатор сотрудника
  /// [newRate] — новая почасовая ставка в рублях
  /// [validFrom] — дата начала действия новой ставки
  ///
  /// Автоматически закрывает предыдущую ставку и создаёт новую.
  /// Обновляет текущую ставку в таблице employees для обратной совместимости.
  Future<void> call(
      String employeeId, double newRate, DateTime validFrom) async {
    if (newRate <= 0) {
      throw ArgumentError('Ставка должна быть больше нуля');
    }

    await _repository.setNewRate(employeeId, newRate, validFrom);
  }
}
