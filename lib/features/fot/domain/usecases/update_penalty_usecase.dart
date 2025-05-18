import '../../data/models/payroll_penalty_model.dart';
import '../../data/repositories/payroll_penalty_repository.dart';

/// UseCase: Обновить штраф для расчёта ФОТ.
/// 
/// Инкапсулирует бизнес-логику обновления штрафа, делегируя операцию соответствующему репозиторию.
class UpdatePenaltyUseCase {
  /// Репозиторий для работы со штрафами.
  final PayrollPenaltyRepository repository;

  /// Создаёт экземпляр [UpdatePenaltyUseCase] с переданным [repository].
  UpdatePenaltyUseCase(this.repository);

  /// Выполнить обновление штрафа.
  /// 
  /// [penalty] — модель штрафа для обновления.
  /// Возвращает обновлённую модель [PayrollPenaltyModel].
  Future<PayrollPenaltyModel> call(PayrollPenaltyModel penalty) {
    return repository.updatePenalty(penalty);
  }
} 