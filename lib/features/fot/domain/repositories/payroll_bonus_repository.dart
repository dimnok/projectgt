import '../../data/models/payroll_bonus_model.dart';

/// Репозиторий для работы с премиями, связанными с расчётом ФОТ.
///
/// Предоставляет методы для получения, создания, обновления и удаления премий по расчёту ФОТ.
/// Интерфейс в слое Domain согласно Clean Architecture.
abstract class PayrollBonusRepository {
  /// Создать новую премию.
  ///
  /// [bonus] — модель премии для создания.
  /// Возвращает созданную модель [PayrollBonusModel].
  Future<PayrollBonusModel> createBonus(PayrollBonusModel bonus);

  /// Обновить существующую премию.
  ///
  /// [bonus] — модель премии с обновлёнными данными.
  /// Возвращает обновлённую модель [PayrollBonusModel].
  Future<PayrollBonusModel> updateBonus(PayrollBonusModel bonus);

  /// Удалить премию по идентификатору.
  ///
  /// [id] — уникальный идентификатор премии для удаления.
  Future<void> deleteBonus(String id);

  /// Получить все премии без фильтрации.
  ///
  /// Возвращает список всех премий [PayrollBonusModel] из базы данных.
  Future<List<PayrollBonusModel>> getAllBonuses();
}
