import '../../data/models/payroll_deduction_model.dart';
import '../../data/repositories/payroll_deduction_repository.dart';

/// UseCase: Получить список удержаний по идентификатору расчёта ФОТ.
/// 
/// Инкапсулирует бизнес-логику получения удержаний, делегируя операцию соответствующему репозиторию.
class GetDeductionsByPayrollIdUseCase {
  /// Репозиторий для работы с удержаниями.
  final PayrollDeductionRepository repository;

  /// Создаёт экземпляр [GetDeductionsByPayrollIdUseCase] с переданным [repository].
  GetDeductionsByPayrollIdUseCase(this.repository);

  /// Получить список удержаний по идентификатору расчёта ФОТ.
  /// 
  /// [payrollId] — идентификатор расчёта ФОТ.
  /// Возвращает список моделей [PayrollDeductionModel].
  Future<List<PayrollDeductionModel>> call(String payrollId) {
    return repository.getDeductionsByPayrollId(payrollId);
  }
} 