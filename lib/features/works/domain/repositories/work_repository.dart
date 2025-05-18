import '../entities/work.dart';

/// Абстрактный репозиторий для работы со сменами.
/// 
/// Определяет методы для получения, создания, обновления и удаления смен.
abstract class WorkRepository {
  /// Возвращает список всех смен.
  Future<List<Work>> getWorks();

  /// Возвращает смену по идентификатору [id].
  Future<Work?> getWork(String id);

  /// Добавляет новую смену [work] и возвращает созданную сущность.
  Future<Work> addWork(Work work);

  /// Обновляет данные смены [work] и возвращает обновлённую сущность.
  Future<Work> updateWork(Work work);

  /// Удаляет смену по идентификатору [id].
  Future<void> deleteWork(String id);
} 