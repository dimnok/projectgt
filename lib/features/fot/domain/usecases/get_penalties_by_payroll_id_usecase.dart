import '../../data/models/payroll_penalty_model.dart';
import '../../data/repositories/payroll_penalty_repository.dart';

/// UseCase: Получить список штрафов по идентификатору расчёта ФОТ.
/// 
/// Инкапсулирует бизнес-логику получения штрафов, делегируя операцию соответствующему репозиторию.
class GetPenaltiesByPayrollIdUseCase {
  /// Репозиторий для работы со штрафами.
  final PayrollPenaltyRepository repository;

  /// Создаёт экземпляр [GetPenaltiesByPayrollIdUseCase] с переданным [repository].
  GetPenaltiesByPayrollIdUseCase(this.repository);

  /// Получить список штрафов по идентификатору расчёта ФОТ.
  /// 
  /// [payrollId] — идентификатор расчёта ФОТ.
  /// Возвращает список моделей [PayrollPenaltyModel].
  Future<List<PayrollPenaltyModel>> call(String payrollId) {
    return repository.getPenaltiesByPayrollId(payrollId);
  }
} 