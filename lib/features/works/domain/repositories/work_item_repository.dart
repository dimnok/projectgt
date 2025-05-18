import '../entities/work_item.dart';

/// Абстрактный репозиторий для работы с работами в смене.
/// 
/// Определяет методы для получения, добавления, обновления и удаления работ для конкретной смены, а также получения всех работ.
abstract class WorkItemRepository {
  /// Возвращает список работ для смены по идентификатору [workId].
  Future<List<WorkItem>> fetchWorkItems(String workId);

  /// Добавляет новую работу [item] в смену.
  Future<void> addWorkItem(WorkItem item);

  /// Обновляет работу [item] в смене.
  Future<void> updateWorkItem(WorkItem item);

  /// Удаляет работу по идентификатору [id].
  Future<void> deleteWorkItem(String id);

  /// Возвращает список всех работ из всех смен.
  Future<List<WorkItem>> getAllWorkItems();
} 