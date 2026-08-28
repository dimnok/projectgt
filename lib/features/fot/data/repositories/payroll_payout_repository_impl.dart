import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payroll_payout_model.dart';
import '../../domain/repositories/payroll_payout_repository.dart';

/// Имплементация репозитория для работы с выплатами по расчёту ФОТ через Supabase.
///
/// Позволяет получать, создавать, обновлять и удалять выплаты, связанные с расчётом фонда оплаты труда (ФОТ).
class PayrollPayoutRepositoryImpl implements PayrollPayoutRepository {
  /// Экземпляр SupabaseClient для доступа к базе данных.
  final SupabaseClient client;

  /// Идентификатор активной компании.
  final String activeCompanyId;

  /// Создаёт экземпляр [PayrollPayoutRepositoryImpl] с переданным [client] и [activeCompanyId].
  PayrollPayoutRepositoryImpl(this.client, this.activeCompanyId);

  /// Максимум строк в одном ответе PostgREST; без пагинации дальнейшие строки отбрасываются.
  static const int _postgrestPageSize = 1000;

  /// Возвращает все выплаты [activeCompanyId], обходя лимит PostgREST на размер ответа.
  ///
  /// Порядок страниц: `payout_date`, затем `id` (оба по возрастанию), чтобы соседние
  /// страницы не дублировали и не пропускали строки с одной датой.
  @override
  Future<List<PayrollPayoutModel>> getAllPayouts() async {
    final all = <PayrollPayoutModel>[];
    var offset = 0;
    var hasMore = true;

    while (hasMore) {
      final response = await client
          .from('payroll_payout')
          .select()
          .eq('company_id', activeCompanyId)
          .order('payout_date', ascending: true)
          .order('id', ascending: true)
          .range(offset, offset + _postgrestPageSize - 1);

      if (response.isEmpty) {
        break;
      }

      for (final row in response) {
        all.add(
          PayrollPayoutModel.fromJson(Map<String, dynamic>.from(row as Map)),
        );
      }

      if (response.length < _postgrestPageSize) {
        hasMore = false;
      } else {
        offset += _postgrestPageSize;
      }
    }

    return all;
  }

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
        .eq('company_id', activeCompanyId)
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
    await client
        .from('payroll_payout')
        .delete()
        .eq('id', id)
        .eq('company_id', activeCompanyId);
  }
}
