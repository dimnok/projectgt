import '../../data/models/payroll_bonus_model.dart';
import '../../data/repositories/payroll_bonus_repository.dart';

/// UseCase: Получить список премий по идентификатору расчёта ФОТ.
/// 
/// Инкапсулирует бизнес-логику получения премий, делегируя операцию соответствующему репозиторию.
class GetBonusesByPayrollIdUseCase {
  /// Репозиторий для работы с премиями.
  final PayrollBonusRepository repository;

  /// Создаёт экземпляр [GetBonusesByPayrollIdUseCase] с переданным [repository].
  GetBonusesByPayrollIdUseCase(this.repository);

  /// Получить список премий по идентификатору расчёта ФОТ.
  /// 
  /// [payrollId] — идентификатор расчёта ФОТ.
  /// Возвращает список моделей [PayrollBonusModel].
  Future<List<PayrollBonusModel>> call(String payrollId) {
    return repository.getBonusesByPayrollId(payrollId);
  }
} 