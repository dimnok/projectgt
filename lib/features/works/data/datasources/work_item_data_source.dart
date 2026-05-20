import '../models/work_item_model.dart';

/// Абстрактный источник данных для работы с работами в смене.
///
/// Определяет методы для получения, добавления, обновления и удаления работ для конкретной смены, а также получения всех работ.
abstract class WorkItemDataSource {
  /// Возвращает список работ для смены по идентификатору [workId].
  Future<List<WorkItemModel>> fetchWorkItems(String workId);

  /// Возвращает одну работу по [workItemId] или `null`, если не найдена.
  Future<WorkItemModel?> fetchWorkItemById(String workItemId);

  /// [estimate_id] позиций смены с той же комбинацией участок/этаж/система/подсистема/подрядчик.
  Future<Set<String>> fetchEstimateIdsForCombo({
    required String workId,
    required String section,
    required String floor,
    required String system,
    required String subsystem,
    String? contractorId,
  });

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
}
