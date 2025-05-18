import '../../data/models/payroll_deduction_model.dart';
import '../../data/repositories/payroll_deduction_repository.dart';

/// UseCase: Создать удержание для расчёта ФОТ.
/// 
/// Инкапсулирует бизнес-логику создания удержания, делегируя операцию соответствующему репозиторию.
class CreateDeductionUseCase {
  /// Репозиторий для работы с удержаниями.
  final PayrollDeductionRepository repository;

  /// Создаёт экземпляр [CreateDeductionUseCase] с переданным [repository].
  CreateDeductionUseCase(this.repository);

  /// Выполнить создание удержания.
  /// 
  /// [deduction] — модель удержания для создания.
  /// Возвращает созданную модель [PayrollDeductionModel].
  Future<PayrollDeductionModel> call(PayrollDeductionModel deduction) {
    return repository.createDeduction(deduction);
  }
} 