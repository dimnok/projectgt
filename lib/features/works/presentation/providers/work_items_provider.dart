import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../domain/entities/work_item.dart';
import '../../domain/repositories/work_item_repository.dart';
import 'repositories_providers.dart';

/// Состояние списка работ.
///
/// Содержит список работ [items], флаг загрузки [isLoading] и возможную ошибку [error].
class WorkItemsState {
  /// Список работ.
  final List<WorkItem> items;

  /// Флаг, указывающий на процесс загрузки.
  final bool isLoading;

  /// Сообщение об ошибке, если есть.
  final String? error;

  /// Создаёт состояние для списка работ.
  WorkItemsState({
    required this.items,
    this.isLoading = false,
    this.error,
  });

  /// Возвращает копию состояния с обновлёнными полями.
  WorkItemsState copyWith({
    List<WorkItem>? items,
    bool? isLoading,
    String? error,
  }) {
    return WorkItemsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// StateNotifier для управления списком работ в смене.
class WorkItemsNotifier extends StateNotifier<AsyncValue<List<WorkItem>>> {
  /// Репозиторий для работы с работами.
  final WorkItemRepository repository;

  /// Идентификатор смены, для которой ведётся учёт работ.
  final String workId;
  StreamSubscription<List<WorkItem>>? _subscription;

  /// Создаёт [WorkItemsNotifier] и сразу инициирует загрузку работ для смены [workId].
  WorkItemsNotifier(this.repository, this.workId)
      : super(const AsyncValue.loading()) {
    if (workId.isNotEmpty) {
      // Инициализируем начальную загрузку и подписку на realtime
      fetch();
      _subscription = repository.watchWorkItems(workId).listen(
        (items) {
          state = AsyncValue.data(items);
        },
        onError: (e, st) {
          state = AsyncValue.error(e, st);
        },
        cancelOnError: false,
      );
    }
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
    await fetch();
  }

  /// Пакетно добавляет несколько работ и делает один финальный fetch().
  Future<void> addMany(List<WorkItem> items) async {
    if (items.isEmpty) return;
    await repository.addWorkItems(items);
    await fetch();
  }

  /// Обновляет существующую работу [item] в смене и обновляет список.
  Future<void> update(WorkItem item) async {
    await repository.updateWorkItem(item);
    await fetch();
  }

  /// Обновляет работу [item] без полного обновления списка (оптимистично).
  /// Сохраняет порядок текущего списка и заменяет элемент по id.
  Future<void> updateOptimistic(WorkItem item) async {
    await repository.updateWorkItem(item);
    final current = state;
    current.when(
      data: (items) {
        final updated = items
            .map((e) => e.id == item.id ? item : e)
            .toList(growable: false);
        state = AsyncValue.data(updated);
      },
      loading: () {},
      error: (_, __) {},
    );
  }

  /// Удаляет работу по идентификатору [id] и обновляет список.
  Future<void> delete(String id) async {
    await repository.deleteWorkItem(id);
    await fetch();
  }

  /// Удаляет работу оптимистично: без fetch(), сразу из локального списка.
  Future<void> deleteOptimistic(String id) async {
    await repository.deleteWorkItem(id);
    final current = state;
    current.when(
      data: (items) {
        final updated = items.where((e) => e.id != id).toList(growable: false);
        state = AsyncValue.data(updated);
      },
      loading: () {},
      error: (_, __) {},
    );
  }

  /// Возвращает все работы из всех смен.
  Future<List<WorkItem>> getAllWorkItems() async {
    return await repository.getAllWorkItems();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Провайдер для управления и получения списка работ смены по [workId].
final workItemsProvider = StateNotifierProvider.family<WorkItemsNotifier,
    AsyncValue<List<WorkItem>>, String>((ref, workId) {
  final repo = ref.watch(workItemRepositoryProvider);
  return WorkItemsNotifier(repo, workId);
});

/// Провайдер для доступа к методам WorkItemsNotifier без привязки к конкретной смене.
final workItemsNotifierProvider = Provider<WorkItemsNotifier>((ref) {
  final repo = ref.watch(workItemRepositoryProvider);
  return WorkItemsNotifier(repo, ''); // Пустой ID для доступа к общим методам
});
