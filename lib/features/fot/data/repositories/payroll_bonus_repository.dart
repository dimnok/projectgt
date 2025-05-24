import '../models/payroll_bonus_model.dart';

/// Репозиторий для работы с премиями, связанными с расчётом ФОТ.
/// 
/// Предоставляет методы для получения, создания, обновления и удаления премий по расчёту ФОТ.
abstract class PayrollBonusRepository {
  /// Получить список премий по идентификатору расчёта ФОТ.
  Future<List<PayrollBonusModel>> getBonusesByPayrollId(String payrollId);

  /// Создать новую премию.
  Future<PayrollBonusModel> createBonus(PayrollBonusModel bonus);

  /// Обновить существующую премию.
  Future<PayrollBonusModel> updateBonus(PayrollBonusModel bonus);

  /// Удалить премию по идентификатору.
  Future<void> deleteBonus(String id);

  /// Получить все премии (без фильтрации по payrollId).
  Future<List<PayrollBonusModel>> getAllBonuses();
} 