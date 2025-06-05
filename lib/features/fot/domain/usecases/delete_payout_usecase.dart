import '../../data/repositories/payroll_payout_repository.dart';

/// UseCase: Удалить выплату по идентификатору.
/// 
/// Инкапсулирует бизнес-логику удаления выплаты, делегируя операцию соответствующему репозиторию.
class DeletePayoutUseCase {
  /// Репозиторий для работы с выплатами.
  final PayrollPayoutRepository repository;

  /// Создаёт экземпляр [DeletePayoutUseCase] с переданным [repository].
  DeletePayoutUseCase(this.repository);

  /// Выполнить удаление выплаты.
  /// 
  /// [payoutId] — идентификатор выплаты для удаления.
  Future<void> call(String payoutId) async {
    await repository.deletePayout(payoutId);
  }
} 