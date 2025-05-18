import '../../data/models/payroll_payout_model.dart';
import '../../data/repositories/payroll_payout_repository.dart';

/// UseCase: Обновить выплату для расчёта ФОТ.
/// 
/// Инкапсулирует бизнес-логику обновления выплаты, делегируя операцию соответствующему репозиторию.
class UpdatePayoutUseCase {
  /// Репозиторий для работы с выплатами.
  final PayrollPayoutRepository repository;

  /// Создаёт экземпляр [UpdatePayoutUseCase] с переданным [repository].
  UpdatePayoutUseCase(this.repository);

  /// Выполнить обновление выплаты.
  /// 
  /// [payout] — модель выплаты для обновления.
  /// Возвращает обновлённую модель [PayrollPayoutModel].
  Future<PayrollPayoutModel> call(PayrollPayoutModel payout) {
    return repository.updatePayout(payout);
  }
} 