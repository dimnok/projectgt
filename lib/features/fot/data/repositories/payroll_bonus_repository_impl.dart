import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payroll_bonus_model.dart';
import 'payroll_bonus_repository.dart';

/// Имплементация репозитория для работы с премиями по расчёту ФОТ через Supabase.
/// 
/// Позволяет получать, создавать, обновлять и удалять премии, связанные с расчётом фонда оплаты труда (ФОТ).
class PayrollBonusRepositoryImpl implements PayrollBonusRepository {
  /// Экземпляр SupabaseClient для доступа к базе данных.
  final SupabaseClient client;

  /// Создаёт экземпляр [PayrollBonusRepositoryImpl] с переданным [client].
  PayrollBonusRepositoryImpl(this.client);

  /// Получить все премии по идентификатору расчёта ФОТ.
  /// 
  /// [payrollId] — идентификатор расчёта ФОТ.
  /// Возвращает список моделей [PayrollBonusModel].
  @override
  Future<List<PayrollBonusModel>> getBonusesByPayrollId(String payrollId) async {
    // Получить все премии по идентификатору расчёта ФОТ
    final response = await client
        .from('payroll_bonus')
        .select()
        .eq('payroll_id', payrollId);
    return (response as List)
        .map((json) => PayrollBonusModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Создать новую премию.
  /// 
  /// [bonus] — модель премии для создания.
  /// Возвращает созданную модель [PayrollBonusModel].
  @override
  Future<PayrollBonusModel> createBonus(PayrollBonusModel bonus) async {
    // Создать новую премию
    final response = await client
        .from('payroll_bonus')
        .insert(bonus.toJson())
        .select()
        .single();
    return PayrollBonusModel.fromJson(response);
  }

  /// Обновить премию по идентификатору.
  /// 
  /// [bonus] — модель премии для обновления.
  /// Возвращает обновлённую модель [PayrollBonusModel].
  @override
  Future<PayrollBonusModel> updateBonus(PayrollBonusModel bonus) async {
    // Обновить премию по id
    final response = await client
        .from('payroll_bonus')
        .update(bonus.toJson())
        .eq('id', bonus.id)
        .select()
        .single();
    return PayrollBonusModel.fromJson(response);
  }

  /// Удалить премию по идентификатору.
  /// 
  /// [id] — идентификатор премии для удаления.
  @override
  Future<void> deleteBonus(String id) async {
    // Удалить премию по id
    await client.from('payroll_bonus').delete().eq('id', id);
  }

  @override
  Future<List<PayrollBonusModel>> getAllBonuses() async {
    final response = await client.from('payroll_bonus').select();
    return (response as List)
        .map((json) => PayrollBonusModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
} 