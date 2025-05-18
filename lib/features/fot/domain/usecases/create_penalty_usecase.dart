import '../../data/models/payroll_penalty_model.dart';
import '../../data/repositories/payroll_penalty_repository.dart';

/// UseCase: Создать штраф для расчёта ФОТ.
/// 
/// Инкапсулирует бизнес-логику создания штрафа, делегируя операцию соответствующему репозиторию.
class CreatePenaltyUseCase {
  /// Репозиторий для работы со штрафами.
  final PayrollPenaltyRepository repository;

  /// Создаёт экземпляр [CreatePenaltyUseCase] с переданным [repository].
  CreatePenaltyUseCase(this.repository);

  /// Выполнить создание штрафа.
  /// 
  /// [penalty] — модель штрафа для создания.
  /// Возвращает созданную модель [PayrollPenaltyModel].
  Future<PayrollPenaltyModel> call(PayrollPenaltyModel penalty) {
    return repository.createPenalty(penalty);
  }
} 