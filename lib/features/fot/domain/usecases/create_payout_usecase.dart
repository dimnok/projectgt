import '../../data/models/payroll_payout_model.dart';
import '../../data/repositories/payroll_payout_repository.dart';

/// UseCase: Создать выплату для расчёта ФОТ.
///
/// Инкапсулирует бизнес-логику создания выплаты, делегируя операцию соответствующему репозиторию.
class CreatePayoutUseCase {
  /// Репозиторий для работы с выплатами.
  final PayrollPayoutRepository repository;

  /// Создаёт экземпляр [CreatePayoutUseCase] с переданным [repository].
  CreatePayoutUseCase(this.repository);

  /// Выполнить создание выплаты.
  ///
  /// [payout] — модель выплаты для создания.
  /// Возвращает созданную модель [PayrollPayoutModel].
  Future<PayrollPayoutModel> call(PayrollPayoutModel payout) async {
    return await repository.createPayout(payout);
  }
}
