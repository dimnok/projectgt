import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  /// Создаёт [WorkItemsNotifier] и сразу инициирует загрузку работ для смены [workId].
  WorkItemsNotifier(this.repository, this.workId) : super(const AsyncValue.loading()) {
    if (workId.isNotEmpty) {
      fetch();
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

  /// Обновляет существующую работу [item] в смене и обновляет список.
  Future<void> update(WorkItem item) async {
    await repository.updateWorkItem(item);
    await fetch();
  }

  /// Удаляет работу по идентификатору [id] и обновляет список.
  Future<void> delete(String id) async {
    await repository.deleteWorkItem(id);
    await fetch();
  }
  
  /// Возвращает все работы из всех смен.
  Future<List<WorkItem>> getAllWorkItems() async {
    return await repository.getAllWorkItems();
  }
}

/// Провайдер для управления и получения списка работ смены по [workId].
final workItemsProvider = StateNotifierProvider.family<WorkItemsNotifier, AsyncValue<List<WorkItem>>, String>((ref, workId) {
  final repo = ref.watch(workItemRepositoryProvider);
  return WorkItemsNotifier(repo, workId);
});

/// Провайдер для доступа к методам WorkItemsNotifier без привязки к конкретной смене.
final workItemsNotifierProvider = Provider<WorkItemsNotifier>((ref) {
  final repo = ref.watch(workItemRepositoryProvider);
  return WorkItemsNotifier(repo, ''); // Пустой ID для доступа к общим методам
}); 