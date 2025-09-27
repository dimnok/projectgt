import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/work.dart';
import '../../domain/repositories/work_repository.dart';
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

/// StateNotifier для управления состоянием списка смен.
class WorksNotifier extends StateNotifier<WorksState> {
  /// Репозиторий для работы со сменами.
  final WorkRepository repository;

  /// Создаёт [WorksNotifier] и сразу загружает список смен.
  WorksNotifier(this.repository) : super(WorksState(works: [])) {
    loadWorks();
  }

  /// Загружает список смен из репозитория.
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

/// Провайдер состояния списка смен.
final worksProvider = StateNotifierProvider<WorksNotifier, WorksState>((ref) {
  final repository = ref.watch(workRepositoryProvider);
  return WorksNotifier(repository);
});

/// Провайдер для получения конкретной смены по [id].
final workProvider = Provider.family<Work?, String>((ref, id) {
  final state = ref.watch(worksProvider);
  if (state.works.isEmpty) return null;
  try {
    return state.works.firstWhere((work) => work.id == id);
  } catch (_) {
    return null;
  }
});
