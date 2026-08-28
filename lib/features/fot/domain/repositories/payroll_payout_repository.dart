import '../../data/models/payroll_payout_model.dart';

/// Репозиторий для работы с выплатами по расчёту ФОТ.
///
/// Предоставляет методы для получения, создания, обновления и удаления выплат по расчёту ФОТ.
/// Интерфейс в слое Domain согласно Clean Architecture.
abstract class PayrollPayoutRepository {
  /// Возвращает все выплаты активной компании.
  ///
  /// Загрузка идёт порциями, чтобы не потерять строки за лимитом PostgREST (1000).
  /// Используется FIFO-расчётом колонок «Выплаты» и «Баланс».
  Future<List<PayrollPayoutModel>> getAllPayouts();

  /// Создать новую выплату.
  ///
  /// [payout] — модель выплаты для создания.
  /// Возвращает созданную модель [PayrollPayoutModel].
  Future<PayrollPayoutModel> createPayout(PayrollPayoutModel payout);

  /// Обновить существующую выплату.
  ///
  /// [payout] — модель выплаты с обновлёнными данными.
  /// Возвращает обновлённую модель [PayrollPayoutModel].
  Future<PayrollPayoutModel> updatePayout(PayrollPayoutModel payout);

  /// Удалить выплату по идентификатору.
  ///
  /// [id] — уникальный идентификатор выплаты для удаления.
  Future<void> deletePayout(String id);
}
