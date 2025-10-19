import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/work.dart';
import '../../domain/repositories/work_repository.dart';
import 'month_groups_provider.dart';
import 'repositories_providers.dart';

/// Состояние для списка смен.
///
/// Содержит список смен [works], флаг загрузки [isLoading] и возможную ошибку [error].
class WorksState {
  /// Список смен.
  final List<Work> works;

  /// Флаг, указывающий на процесс загрузки.
  final bool isLoading;

  /// Сообщение об ошибке, если есть.
  final String? error;

  /// Создаёт состояние для списка смен.
  WorksState({
    required this.works,
    this.isLoading = false,
    this.error,
  });

  /// Возвращает копию состояния с обновлёнными полями.
  WorksState copyWith({
    List<Work>? works,
    bool? isLoading,
    String? error,
  }) {
    return WorksState(
      works: works ?? this.works,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// StateNotifier для управления операциями со сменами (add/update/delete).
///
/// ⚠️ НЕ загружает список смен автоматически! Для списка используйте monthGroupsProvider.
/// Этот провайдер используется для:
/// - Операций add/update/delete
/// - Явной загрузки всех смен (метод loadWorks) для специфичных сценариев (notifications)
class WorksNotifier extends StateNotifier<WorksState> {
  /// Репозиторий для работы со сменами.
  final WorkRepository repository;

  /// Создаёт [WorksNotifier] БЕЗ автоматической загрузки.
  ///
  /// Для списка смен в UI используйте monthGroupsProvider.
  /// Вызовите loadWorks() явно только если нужны ВСЕ смены.
  WorksNotifier(this.repository) : super(WorksState(works: []));

  /// Загружает список ВСЕ смен из репозитория.
  ///
  /// ⚠️ Используйте только для специфичных задач (notifications, reports).
  /// Для UI списка смен используйте monthGroupsProvider!
  Future<void> loadWorks() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final works = await repository.getWorks();
      state = state.copyWith(works: works, isLoading: false);
    } catch (e) {
      state =
          state.copyWith(error: 'Ошибка загрузки смен: $e', isLoading: false);
    }
  }

  /// Добавляет новую смену.
  ///
  /// Возвращает созданную смену или null в случае ошибки.
  Future<Work?> addWork({
    required DateTime date,
    required String objectId,
    required String openedBy,
    required String status,
    String? photoUrl,
    String? eveningPhotoUrl,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final work = Work(
        id: id,
        date: date,
        objectId: objectId,
        openedBy: openedBy,
        status: status,
        photoUrl: photoUrl,
        eveningPhotoUrl: eveningPhotoUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        // Агрегатные поля инициализируются нулями (триггеры пересчитают при добавлении работ)
        totalAmount: 0,
        itemsCount: 0,
        employeesCount: 0,
      );
      final created = await repository.addWork(work);
      state = state.copyWith(
        works: [...state.works, created],
        isLoading: false,
      );
      return created;
    } catch (e) {
      state =
          state.copyWith(error: 'Ошибка создания смены: $e', isLoading: false);
      return null;
    }
  }

  /// Обновляет данные смены [work] в репозитории и состоянии.
  Future<void> updateWork(Work work) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await repository.updateWork(work);
      state = state.copyWith(
        works: [
          for (final w in state.works)
            if (w.id == updated.id) updated else w
        ],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
          error: 'Ошибка обновления смены: $e', isLoading: false);
    }
  }

  /// Удаляет смену по [id] из репозитория и состояния.
  Future<void> deleteWork(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await repository.deleteWork(id);
      state = state.copyWith(
        works: state.works.where((w) => w.id != id).toList(),
        isLoading: false,
      );
    } catch (e) {
      state =
          state.copyWith(error: 'Ошибка удаления смены: $e', isLoading: false);
    }
  }
}

/// Провайдер для операций со сменами (add/update/delete).
///
/// ⚠️ Используйте только для операций! Для списка смен используйте monthGroupsProvider.
/// Не хранит список смен для избежания дублирования с monthGroupsProvider.
final worksProvider = StateNotifierProvider<WorksNotifier, WorksState>((ref) {
  final repository = ref.watch(workRepositoryProvider);
  return WorksNotifier(repository);
});

/// Провайдер для получения конкретной смены по [id].
///
/// Пытается найти смену в monthGroupsProvider сначала, иначе загружает из БД.
final workProvider = Provider.family<Work?, String>((ref, id) {
  // Пытаемся найти смену в загруженных группах месяцев
  final monthGroupsState = ref.watch(monthGroupsProvider);
  for (final group in monthGroupsState.groups) {
    if (group.works != null) {
      try {
        final found = group.works!.firstWhere((work) => work.id == id);
        return found;
      } catch (e) {
        continue;
      }
    }
  }
  // Если не найдено в группах, возвращаем null
  // В реальности смена должна быть в одной из раскрытых групп
  return null;
});
