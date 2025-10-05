import '../../data/models/payroll_penalty_model.dart';

/// Репозиторий для работы со штрафами, связанными с расчётом ФОТ.
///
/// Предоставляет методы для получения, создания, обновления и удаления штрафов по расчёту ФОТ.
/// Интерфейс в слое Domain согласно Clean Architecture.
abstract class PayrollPenaltyRepository {
  /// Создать новый штраф.
  ///
  /// [penalty] — модель штрафа для создания.
  /// Возвращает созданную модель [PayrollPenaltyModel].
  Future<PayrollPenaltyModel> createPenalty(PayrollPenaltyModel penalty);

  /// Обновить существующий штраф.
  ///
  /// [penalty] — модель штрафа с обновлёнными данными.
  /// Возвращает обновлённую модель [PayrollPenaltyModel].
  Future<PayrollPenaltyModel> updatePenalty(PayrollPenaltyModel penalty);

  /// Удалить штраф по идентификатору.
  ///
  /// [id] — уникальный идентификатор штрафа для удаления.
  Future<void> deletePenalty(String id);

  /// Получить все штрафы без фильтрации.
  ///
  /// Возвращает список всех штрафов [PayrollPenaltyModel] из базы данных.
  Future<List<PayrollPenaltyModel>> getAllPenalties();
}
