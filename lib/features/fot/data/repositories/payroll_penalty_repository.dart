import '../models/payroll_penalty_model.dart';

/// Репозиторий для работы со штрафами, связанными с расчётом ФОТ.
/// 
/// Предоставляет методы для получения, создания, обновления и удаления штрафов по расчёту ФОТ.
abstract class PayrollPenaltyRepository {
  /// Получить список штрафов по идентификатору расчёта ФОТ.
  Future<List<PayrollPenaltyModel>> getPenaltiesByPayrollId(String payrollId);

  /// Создать новый штраф.
  Future<PayrollPenaltyModel> createPenalty(PayrollPenaltyModel penalty);

  /// Обновить существующий штраф.
  Future<PayrollPenaltyModel> updatePenalty(PayrollPenaltyModel penalty);

  /// Удалить штраф по идентификатору.
  Future<void> deletePenalty(String id);

  /// Получить все штрафы (без фильтрации по payroll_id)
  Future<List<PayrollPenaltyModel>> getAllPenalties();
} 