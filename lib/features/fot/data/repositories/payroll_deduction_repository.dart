import '../models/payroll_deduction_model.dart';

/// Репозиторий для работы с удержаниями, связанными с расчётом ФОТ.
/// 
/// Предоставляет методы для получения, создания, обновления и удаления удержаний по расчёту ФОТ.
abstract class PayrollDeductionRepository {
  /// Получить список удержаний по идентификатору расчёта ФОТ.
  Future<List<PayrollDeductionModel>> getDeductionsByPayrollId(String payrollId);

  /// Создать новое удержание.
  Future<PayrollDeductionModel> createDeduction(PayrollDeductionModel deduction);

  /// Обновить существующее удержание.
  Future<PayrollDeductionModel> updateDeduction(PayrollDeductionModel deduction);

  /// Удалить удержание по идентификатору.
  Future<void> deleteDeduction(String id);
} 