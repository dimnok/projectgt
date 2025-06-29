import '../models/payroll_payout_model.dart';

/// Репозиторий для работы с выплатами по расчёту ФОТ.
/// 
/// Предоставляет методы для получения, создания, обновления и удаления выплат по расчёту ФОТ.
abstract class PayrollPayoutRepository {
  /// Создать новую выплату.
  Future<PayrollPayoutModel> createPayout(PayrollPayoutModel payout);

  /// Обновить существующую выплату.
  Future<PayrollPayoutModel> updatePayout(PayrollPayoutModel payout);

  /// Удалить выплату по идентификатору.
  Future<void> deletePayout(String id);
} 