import '../../data/models/payroll_deduction_model.dart';
import '../../data/repositories/payroll_deduction_repository.dart';

/// UseCase: Обновить удержание для расчёта ФОТ.
/// 
/// Инкапсулирует бизнес-логику обновления удержания, делегируя операцию соответствующему репозиторию.
class UpdateDeductionUseCase {
  /// Репозиторий для работы с удержаниями.
  final PayrollDeductionRepository repository;

  /// Создаёт экземпляр [UpdateDeductionUseCase] с переданным [repository].
  UpdateDeductionUseCase(this.repository);

  /// Выполнить обновление удержания.
  /// 
  /// [deduction] — модель удержания для обновления.
  /// Возвращает обновлённую модель [PayrollDeductionModel].
  Future<PayrollDeductionModel> call(PayrollDeductionModel deduction) {
    return repository.updateDeduction(deduction);
  }
} 