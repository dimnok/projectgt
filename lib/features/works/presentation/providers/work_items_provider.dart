import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/work_item.dart';
import '../../domain/repositories/work_item_repository.dart';
import 'month_groups_provider.dart';
import 'repositories_providers.dart';

/// StateNotifier для управления списком работ в смене.
class WorkItemsNotifier extends StateNotifier<AsyncValue<List<WorkItem>>> {
  /// Репозиторий для работы с работами.
  final WorkItemRepository repository;

  /// Ссылка на контейнер Riverpod для синхронизации связанных провайдеров.
  final Ref ref;

  /// Идентификатор смены, для которой ведётся учёт работ.
  final String workId;

  /// Создаёт [WorkItemsNotifier] и сразу инициирует загрузку работ для смены [workId].
  WorkItemsNotifier(this.repository, this.workId, this.ref)
    : super(const AsyncValue.loading()) {
    if (workId.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    fetch();
  }

  /// Загружает список работ для текущей смены.
  Future<void> fetch() async {
    state = const AsyncValue.loading();
    try {
      final items = await repository.fetchWorkItems(workId);
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Добавляет новую работу [item] в смену и обновляет список.
  Future<void> add(WorkItem item) async {
    await repository.addWorkItem(item);
    await _refreshAfterMutation();
  }

  /// Пакетно добавляет несколько работ и обновляет локальный список.
  Future<void> addMany(List<WorkItem> items) async {
    if (items.isEmpty) return;
    await repository.addWorkItems(items);
    await _refreshAfterMutation();
  }

  /// Обновляет существующую работу [item] в смене и обновляет список.
  Future<void> update(WorkItem item) async {
    await repository.updateWorkItem(item);
    await _refreshAfterMutation();
  }

  /// Удаляет работу по идентификатору [id] и обновляет список.
  Future<void> delete(String id) async {
    await repository.deleteWorkItem(id);
    await _refreshAfterMutation();
  }

  Future<void> _refreshAfterMutation() async {
    await fetch();
    await _refreshParentWork();
  }

  Future<void> _refreshParentWork() async {
    if (workId.isEmpty) return;

    try {
      final freshWork = await ref.read(workRepositoryProvider).getWork(workId);
      if (freshWork == null) return;

      ref.read(monthGroupsProvider.notifier).updateWorkInGroup(freshWork);
    } catch (_) {
      // Сама операция с работой уже выполнена; сбой обновления агрегатов
      // не должен откатывать локальное изменение списка.
    }
  }

  /// Возвращает все работы из всех смен.
  Future<List<WorkItem>> getAllWorkItems() async {
    return await repository.getAllWorkItems();
  }
}

/// Провайдер для управления и получения списка работ смены по [workId].
final workItemsProvider =
    StateNotifierProvider.family<
      WorkItemsNotifier,
      AsyncValue<List<WorkItem>>,
      String
    >((ref, workId) {
      final repo = ref.watch(workItemRepositoryProvider);
      return WorkItemsNotifier(repo, workId, ref);
    });

/// Провайдер для доступа к методам WorkItemsNotifier без привязки к конкретной смене.
final workItemsNotifierProvider = Provider<WorkItemsNotifier>((ref) {
  final repo = ref.watch(workItemRepositoryProvider);
  return WorkItemsNotifier(
    repo,
    '',
    ref,
  ); // Пустой ID для доступа к общим методам
});
