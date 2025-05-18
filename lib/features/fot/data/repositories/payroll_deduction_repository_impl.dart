import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payroll_deduction_model.dart';
import 'payroll_deduction_repository.dart';

/// Имплементация репозитория для работы с удержаниями по расчёту ФОТ через Supabase.
/// 
/// Позволяет получать, создавать, обновлять и удалять удержания, связанные с расчётом фонда оплаты труда (ФОТ).
class PayrollDeductionRepositoryImpl implements PayrollDeductionRepository {
  /// Экземпляр SupabaseClient для доступа к базе данных.
  final SupabaseClient client;

  /// Создаёт экземпляр [PayrollDeductionRepositoryImpl] с переданным [client].
  PayrollDeductionRepositoryImpl(this.client);

  /// Получить все удержания по идентификатору расчёта ФОТ.
  /// 
  /// [payrollId] — идентификатор расчёта ФОТ.
  /// Возвращает список моделей [PayrollDeductionModel].
  @override
  Future<List<PayrollDeductionModel>> getDeductionsByPayrollId(String payrollId) async {
    // Получить все удержания по идентификатору расчёта ФОТ
    final response = await client
        .from('payroll_deduction')
        .select()
        .eq('payroll_id', payrollId);
    return (response as List)
        .map((json) => PayrollDeductionModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Создать новое удержание.
  /// 
  /// [deduction] — модель удержания для создания.
  /// Возвращает созданную модель [PayrollDeductionModel].
  @override
  Future<PayrollDeductionModel> createDeduction(PayrollDeductionModel deduction) async {
    // Создать новое удержание
    final response = await client
        .from('payroll_deduction')
        .insert(deduction.toJson())
        .select()
        .single();
    return PayrollDeductionModel.fromJson(response);
  }

  /// Обновить удержание по идентификатору.
  /// 
  /// [deduction] — модель удержания для обновления.
  /// Возвращает обновлённую модель [PayrollDeductionModel].
  @override
  Future<PayrollDeductionModel> updateDeduction(PayrollDeductionModel deduction) async {
    // Обновить удержание по id
    final response = await client
        .from('payroll_deduction')
        .update(deduction.toJson())
        .eq('id', deduction.id)
        .select()
        .single();
    return PayrollDeductionModel.fromJson(response);
  }

  /// Удалить удержание по идентификатору.
  /// 
  /// [id] — идентификатор удержания для удаления.
  @override
  Future<void> deleteDeduction(String id) async {
    // Удалить удержание по id
    await client.from('payroll_deduction').delete().eq('id', id);
  }
} 