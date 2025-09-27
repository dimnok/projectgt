import '../models/work_item_model.dart';

/// Абстрактный источник данных для работы с работами в смене.
///
/// Определяет методы для получения, добавления, обновления и удаления работ для конкретной смены, а также получения всех работ.
abstract class WorkItemDataSource {
  /// Возвращает список работ для смены по идентификатору [workId].
  Future<List<WorkItemModel>> fetchWorkItems(String workId);

  /// Добавляет новую работу [item] в смену.
  Future<void> addWorkItem(WorkItemModel item);

  /// Пакетно добавляет несколько работ [items] в смену одним запросом.
  Future<void> addWorkItems(List<WorkItemModel> items);

  /// Обновляет работу [item] в смене.
  Future<void> updateWorkItem(WorkItemModel item);

  /// Удаляет работу по идентификатору [id].
  Future<void> deleteWorkItem(String id);

  /// Возвращает список всех работ из всех смен.
  Future<List<WorkItemModel>> getAllWorkItems();

  /// Возвращает поток работ для смены по идентификатору [workId].
  ///
  /// Использует Supabase Realtime для мгновенного обновления данных в приложении
  /// при изменениях в таблице [work_items].
  Stream<List<WorkItemModel>> watchWorkItems(String workId);
}
