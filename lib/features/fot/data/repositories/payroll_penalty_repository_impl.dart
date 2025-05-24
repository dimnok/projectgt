import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payroll_penalty_model.dart';
import 'payroll_penalty_repository.dart';

/// Имплементация репозитория для работы со штрафами по расчёту ФОТ через Supabase.
/// 
/// Позволяет получать, создавать, обновлять и удалять штрафы, связанные с расчётом фонда оплаты труда (ФОТ).
class PayrollPenaltyRepositoryImpl implements PayrollPenaltyRepository {
  /// Экземпляр SupabaseClient для доступа к базе данных.
  final SupabaseClient client;

  /// Создаёт экземпляр [PayrollPenaltyRepositoryImpl] с переданным [client].
  PayrollPenaltyRepositoryImpl(this.client);

  /// Получить все штрафы по идентификатору расчёта ФОТ.
  /// 
  /// [payrollId] — идентификатор расчёта ФОТ.
  /// Возвращает список моделей [PayrollPenaltyModel].
  @override
  Future<List<PayrollPenaltyModel>> getPenaltiesByPayrollId(String payrollId) async {
    // Получить все штрафы по идентификатору расчёта ФОТ
    final response = await client
        .from('payroll_penalty')
        .select()
        .eq('payroll_id', payrollId);
    return (response as List)
        .map((json) => PayrollPenaltyModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Создать новый штраф.
  /// 
  /// [penalty] — модель штрафа для создания.
  /// Возвращает созданную модель [PayrollPenaltyModel].
  @override
  Future<PayrollPenaltyModel> createPenalty(PayrollPenaltyModel penalty) async {
    // Создать новый штраф
    final response = await client
        .from('payroll_penalty')
        .insert(penalty.toJson())
        .select()
        .single();
    return PayrollPenaltyModel.fromJson(response);
  }

  /// Обновить штраф по идентификатору.
  /// 
  /// [penalty] — модель штрафа для обновления.
  /// Возвращает обновлённую модель [PayrollPenaltyModel].
  @override
  Future<PayrollPenaltyModel> updatePenalty(PayrollPenaltyModel penalty) async {
    // Обновить штраф по id
    final response = await client
        .from('payroll_penalty')
        .update(penalty.toJson())
        .eq('id', penalty.id)
        .select()
        .single();
    return PayrollPenaltyModel.fromJson(response);
  }

  /// Удалить штраф по идентификатору.
  /// 
  /// [id] — идентификатор штрафа для удаления.
  @override
  Future<void> deletePenalty(String id) async {
    // Удалить штраф по id
    await client.from('payroll_penalty').delete().eq('id', id);
  }

  @override
  Future<List<PayrollPenaltyModel>> getAllPenalties() async {
    final response = await client.from('payroll_penalty').select();
    return (response as List)
        .map((json) => PayrollPenaltyModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
} 