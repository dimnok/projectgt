import '../entities/payroll_calculation.dart';
import '../repositories/payroll_repository.dart';

/// Use-case получения расчетов ФОТ за указанный месяц.
///
/// Делегирует запрос в [PayrollRepository] и возвращает список расчетов.
class GetPayrollsByMonthUseCase {
  /// Репозиторий расчетов ФОТ.
  final PayrollRepository _repository;

  /// Создает экземпляр use case.
  ///
  /// [repository] - репозиторий расчетов ФОТ.
  GetPayrollsByMonthUseCase(this._repository);

  /// Вызывает use case.
  ///
  /// [month] - первое число месяца, для которого требуется получить расчеты.
  /// Возвращает список расчетов ФОТ.
  Future<List<PayrollCalculation>> call(DateTime month) {
    return _repository.getPayrollsByMonth(month);
  }
} 