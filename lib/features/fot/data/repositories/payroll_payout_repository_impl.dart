import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payroll_payout_model.dart';
import '../../domain/repositories/payroll_payout_repository.dart';

/// Имплементация репозитория для работы с выплатами по расчёту ФОТ через Supabase.
///
/// Позволяет получать, создавать, обновлять и удалять выплаты, связанные с расчётом фонда оплаты труда (ФОТ).
class PayrollPayoutRepositoryImpl implements PayrollPayoutRepository {
  /// Экземпляр SupabaseClient для доступа к базе данных.
  final SupabaseClient client;

  /// Создаёт экземпляр [PayrollPayoutRepositoryImpl] с переданным [client].
  PayrollPayoutRepositoryImpl(this.client);

  /// Создать новую выплату.
  ///
  /// [payout] — модель выплаты для создания.
  /// Возвращает созданную модель [PayrollPayoutModel].
  @override
  Future<PayrollPayoutModel> createPayout(PayrollPayoutModel payout) async {
    // Создать новую выплату
    final response = await client
        .from('payroll_payout')
        .insert(payout.toJson())
        .select()
        .single();

    return PayrollPayoutModel.fromJson(response);
  }

  /// Обновить выплату по идентификатору.
  ///
  /// [payout] — модель выплаты для обновления.
  /// Возвращает обновлённую модель [PayrollPayoutModel].
  @override
  Future<PayrollPayoutModel> updatePayout(PayrollPayoutModel payout) async {
    // Обновить выплату по id
    final response = await client
        .from('payroll_payout')
        .update(payout.toJson())
        .eq('id', payout.id)
        .select()
        .single();

    return PayrollPayoutModel.fromJson(response);
  }

  /// Удалить выплату по идентификатору.
  ///
  /// [id] — идентификатор выплаты для удаления.
  @override
  Future<void> deletePayout(String id) async {
    // Удалить выплату по id
    await client.from('payroll_payout').delete().eq('id', id);
  }
}
