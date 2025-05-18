import '../../data/repositories/payroll_penalty_repository.dart';

/// UseCase: Удалить штраф по идентификатору.
/// 
/// Инкапсулирует бизнес-логику удаления штрафа, делегируя операцию соответствующему репозиторию.
class DeletePenaltyUseCase {
  /// Репозиторий для работы со штрафами.
  final PayrollPenaltyRepository repository;

  /// Создаёт экземпляр [DeletePenaltyUseCase] с переданным [repository].
  DeletePenaltyUseCase(this.repository);

  /// Выполнить удаление штрафа.
  /// 
  /// [penaltyId] — идентификатор штрафа для удаления.
  Future<void> call(String penaltyId) {
    return repository.deletePenalty(penaltyId);
  }
} 