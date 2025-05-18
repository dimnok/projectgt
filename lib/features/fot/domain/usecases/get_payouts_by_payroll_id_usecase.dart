import '../../data/models/payroll_payout_model.dart';
import '../../data/repositories/payroll_payout_repository.dart';

/// UseCase: Получить список выплат по идентификатору расчёта ФОТ.
/// 
/// Инкапсулирует бизнес-логику получения выплат, делегируя операцию соответствующему репозиторию.
class GetPayoutsByPayrollIdUseCase {
  /// Репозиторий для работы с выплатами.
  final PayrollPayoutRepository repository;

  /// Создаёт экземпляр [GetPayoutsByPayrollIdUseCase] с переданным [repository].
  GetPayoutsByPayrollIdUseCase(this.repository);

  /// Получить список выплат по идентификатору расчёта ФОТ.
  /// 
  /// [payrollId] — идентификатор расчёта ФОТ.
  /// Возвращает список моделей [PayrollPayoutModel].
  Future<List<PayrollPayoutModel>> call(String payrollId) {
    return repository.getPayoutsByPayrollId(payrollId);
  }
} 