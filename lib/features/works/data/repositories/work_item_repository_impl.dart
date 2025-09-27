import '../../domain/entities/work_item.dart';
import '../../domain/repositories/work_item_repository.dart';
import '../datasources/work_item_data_source.dart';
import '../models/work_item_model.dart';

/// Реализация репозитория для работы с работами в смене через источник данных [WorkItemDataSource].
class WorkItemRepositoryImpl implements WorkItemRepository {
  /// Источник данных для работ в смене.
  final WorkItemDataSource dataSource;

  /// Создаёт репозиторий для работы с работами в смене.
  WorkItemRepositoryImpl(this.dataSource);

  /// Возвращает список работ для смены по идентификатору [workId].
  @override
  Future<List<WorkItem>> fetchWorkItems(String workId) async {
    final models = await dataSource.fetchWorkItems(workId);
    return models
        .map((e) => WorkItem(
              id: e.id,
              workId: e.workId,
              section: e.section,
              floor: e.floor,
              estimateId: e.estimateId,
              name: e.name,
              system: e.system,
              subsystem: e.subsystem,
              unit: e.unit,
              quantity: e.quantity,
              price: e.price,
              total: e.total,
              createdAt: e.createdAt,
              updatedAt: e.updatedAt,
            ))
        .toList();
  }

  /// Добавляет новую работу [item] в смену.
  @override
  Future<void> addWorkItem(WorkItem item) async {
    await dataSource.addWorkItem(WorkItemModel(
      id: item.id,
      workId: item.workId,
      section: item.section,
      floor: item.floor,
      estimateId: item.estimateId,
      name: item.name,
      system: item.system,
      subsystem: item.subsystem,
      unit: item.unit,
      quantity: item.quantity,
      price: item.price,
      total: item.total,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
    ));
  }

  /// Пакетно добавляет несколько работ [items] в смену одним вызовом.
  @override
  Future<void> addWorkItems(List<WorkItem> items) async {
    if (items.isEmpty) return;
    await dataSource.addWorkItems(items
        .map((item) => WorkItemModel(
              id: item.id,
              workId: item.workId,
              section: item.section,
              floor: item.floor,
              estimateId: item.estimateId,
              name: item.name,
              system: item.system,
              subsystem: item.subsystem,
              unit: item.unit,
              quantity: item.quantity,
              price: item.price,
              total: item.total,
              createdAt: item.createdAt,
              updatedAt: item.updatedAt,
            ))
        .toList());
  }

  /// Обновляет работу [item] в смене.
  @override
  Future<void> updateWorkItem(WorkItem item) async {
    await dataSource.updateWorkItem(WorkItemModel(
      id: item.id,
      workId: item.workId,
      section: item.section,
      floor: item.floor,
      estimateId: item.estimateId,
      name: item.name,
      system: item.system,
      subsystem: item.subsystem,
      unit: item.unit,
      quantity: item.quantity,
      price: item.price,
      total: item.total,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
    ));
  }

  /// Удаляет работу по идентификатору [id].
  @override
  Future<void> deleteWorkItem(String id) async {
    await dataSource.deleteWorkItem(id);
  }

  /// Возвращает список всех работ из всех смен.
  @override
  Future<List<WorkItem>> getAllWorkItems() async {
    final models = await dataSource.getAllWorkItems();
    return models
        .map((e) => WorkItem(
              id: e.id,
              workId: e.workId,
              section: e.section,
              floor: e.floor,
              estimateId: e.estimateId,
              name: e.name,
              system: e.system,
              subsystem: e.subsystem,
              unit: e.unit,
              quantity: e.quantity,
              price: e.price,
              total: e.total,
              createdAt: e.createdAt,
              updatedAt: e.updatedAt,
            ))
        .toList();
  }

  /// Реалтайм-поток работ конкретной смены
  @override
  Stream<List<WorkItem>> watchWorkItems(String workId) {
    return dataSource.watchWorkItems(workId).map((models) => models
        .map((e) => WorkItem(
              id: e.id,
              workId: e.workId,
              section: e.section,
              floor: e.floor,
              estimateId: e.estimateId,
              name: e.name,
              system: e.system,
              subsystem: e.subsystem,
              unit: e.unit,
              quantity: e.quantity,
              price: e.price,
              total: e.total,
              createdAt: e.createdAt,
              updatedAt: e.updatedAt,
            ))
        .toList());
  }
}
