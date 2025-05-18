import '../models/work_model.dart';

/// Абстрактный источник данных для работы со сменами.
///
/// Определяет методы для получения, создания, обновления и удаления смен.
abstract class WorkDataSource {
  /// Возвращает список всех смен.
  Future<List<WorkModel>> getWorks();

  /// Возвращает смену по идентификатору [id].
  Future<WorkModel?> getWork(String id);

  /// Добавляет новую смену [work] и возвращает созданную модель.
  Future<WorkModel> addWork(WorkModel work);

  /// Обновляет данные смены [work] и возвращает обновлённую модель.
  Future<WorkModel> updateWork(WorkModel work);

  /// Удаляет смену по идентификатору [id].
  Future<void> deleteWork(String id);
} 