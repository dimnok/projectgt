import '../../data/repositories/payroll_deduction_repository.dart';

/// UseCase: Удалить удержание по идентификатору.
/// 
/// Инкапсулирует бизнес-логику удаления удержания, делегируя операцию соответствующему репозиторию.
class DeleteDeductionUseCase {
  /// Репозиторий для работы с удержаниями.
  final PayrollDeductionRepository repository;

  /// Создаёт экземпляр [DeleteDeductionUseCase] с переданным [repository].
  DeleteDeductionUseCase(this.repository);

  /// Выполнить удаление удержания.
  /// 
  /// [deductionId] — идентификатор удержания для удаления.
  Future<void> call(String deductionId) {
    return repository.deleteDeduction(deductionId);
  }
} 