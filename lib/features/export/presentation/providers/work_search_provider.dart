import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/work_search_result.dart';
import '../../domain/repositories/work_search_repository.dart';
import 'repositories_providers.dart';

/// Состояние поиска материалов по работам.
class WorkSearchState {
  /// Результаты поиска.
  final List<WorkSearchResult> results;
  /// Флаг загрузки.
  final bool isLoading;
  /// Сообщение об ошибке.
  final String? error;

  /// Создаёт состояние поиска.
  const WorkSearchState({
    required this.results,
    this.isLoading = false,
    this.error,
  });

  /// Возвращает копию состояния с обновлёнными полями.
  WorkSearchState copyWith({
    List<WorkSearchResult>? results,
    bool? isLoading,
    String? error,
  }) {
    return WorkSearchState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// StateNotifier для управления поиском материалов.
class WorkSearchNotifier extends StateNotifier<WorkSearchState> {
  /// Репозиторий для поиска материалов.
  final WorkSearchRepository repository;

  /// Создаёт [WorkSearchNotifier].
  WorkSearchNotifier(this.repository) : super(const WorkSearchState(results: []));

  /// Выполняет поиск материалов по параметрам.
  Future<void> searchMaterials({
    DateTime? startDate,
    DateTime? endDate,
    String? objectId,
    String? searchQuery,
  }) async {
    if (searchQuery == null || searchQuery.trim().isEmpty) {
      state = state.copyWith(results: [], error: null);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final results = await repository.searchMaterials(
        searchQuery: searchQuery.trim(),
        startDate: startDate,
        endDate: endDate,
        objectId: objectId,
      );
      
      state = state.copyWith(results: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        error: 'Ошибка поиска: $e',
        isLoading: false,
      );
    }
  }

  /// Очищает результаты поиска.
  void clearResults() {
    state = state.copyWith(results: [], error: null);
  }
}

/// Провайдер состояния поиска материалов.
final workSearchProvider = StateNotifierProvider<WorkSearchNotifier, WorkSearchState>((ref) {
  final repository = ref.watch(workSearchRepositoryProvider);
  return WorkSearchNotifier(repository);
}); 