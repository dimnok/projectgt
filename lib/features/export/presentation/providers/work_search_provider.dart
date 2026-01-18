import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/work_search_result.dart';
import '../../domain/repositories/work_search_repository.dart';
import 'repositories_providers.dart';

/// Состояние поиска материалов по работам с пагинацией.
class WorkSearchState {
  /// Результаты поиска для текущей страницы.
  final List<WorkSearchResult> results;

  /// Флаг загрузки.
  final bool isLoading;

  /// Сообщение об ошибке.
  final String? error;

  /// Текущая страница (начинается с 1).
  final int currentPage;

  /// Размер страницы.
  final int pageSize;

  /// Общее количество результатов.
  final int totalCount;

  /// Общее количество (сумма по всем страницам).
  final num totalQuantity;

  /// Общая сумма (сумма по всем страницам).
  final double? totalSum;

  /// Общее количество страниц.
  int get totalPages => (totalCount / pageSize).ceil();

  /// Создаёт состояние поиска.
  const WorkSearchState({
    required this.results,
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.pageSize = 250,
    this.totalCount = 0,
    this.totalQuantity = 0,
    this.totalSum,
  });

  /// Возвращает копию состояния с обновлёнными полями.
  WorkSearchState copyWith({
    List<WorkSearchResult>? results,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? pageSize,
    int? totalCount,
    num? totalQuantity,
    double? totalSum,
  }) {
    return WorkSearchState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      totalCount: totalCount ?? this.totalCount,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      totalSum: totalSum ?? this.totalSum,
    );
  }
}

/// StateNotifier для управления поиском материалов.
class WorkSearchNotifier extends StateNotifier<WorkSearchState> {
  /// Репозиторий для поиска материалов.
  final WorkSearchRepository repository;

  /// Параметры последнего поиска (для переключения страниц).
  DateTime? _lastStartDate;
  DateTime? _lastEndDate;
  String? _lastObjectId;
  String? _lastSearchQuery;
  List<String>? _lastSystemFilters;
  List<String>? _lastSectionFilters;
  List<String>? _lastFloorFilters;

  /// Создаёт [WorkSearchNotifier].
  WorkSearchNotifier(this.repository)
      : super(const WorkSearchState(results: []));

  /// Выполняет поиск материалов по параметрам.
  /// Объект обязателен для поиска.
  Future<void> searchMaterials({
    DateTime? startDate,
    DateTime? endDate,
    String? objectId,
    String? searchQuery,
    int page = 1,
    List<String>? systemFilters,
    List<String>? sectionFilters,
    List<String>? floorFilters,
  }) async {
    // Объект обязателен для поиска
    if (objectId == null || objectId.isEmpty) {
      state = state.copyWith(results: [], error: null, totalCount: 0);
      return;
    }

    // Сохраняем параметры для переключения страниц
    _lastStartDate = startDate;
    _lastEndDate = endDate;
    _lastObjectId = objectId;
    _lastSearchQuery = searchQuery;
    _lastSystemFilters = systemFilters;
    _lastSectionFilters = sectionFilters;
    _lastFloorFilters = floorFilters;

    state = state.copyWith(isLoading: true, error: null, results: []);

    try {
      final result = await repository.searchMaterials(
        searchQuery: searchQuery?.trim(),
        startDate: startDate,
        endDate: endDate,
        objectId: objectId,
        page: page,
        pageSize: state.pageSize,
        systemFilters: systemFilters,
        sectionFilters: sectionFilters,
        floorFilters: floorFilters,
      );

      state = state.copyWith(
        results: result.results,
        isLoading: false,
        currentPage: result.currentPage,
        totalCount: result.totalCount,
        totalQuantity: result.totalQuantity,
        totalSum: result.totalSum,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Ошибка поиска: $e',
        isLoading: false,
      );
    }
  }

  /// Переключается на следующую страницу.
  Future<void> nextPage() async {
    if (state.currentPage >= state.totalPages) return;
    await searchMaterials(
      startDate: _lastStartDate,
      endDate: _lastEndDate,
      objectId: _lastObjectId,
      searchQuery: _lastSearchQuery,
      systemFilters: _lastSystemFilters,
      sectionFilters: _lastSectionFilters,
      floorFilters: _lastFloorFilters,
      page: state.currentPage + 1,
    );
  }

  /// Переключается на предыдущую страницу.
  Future<void> previousPage() async {
    if (state.currentPage <= 1) return;
    await searchMaterials(
      startDate: _lastStartDate,
      endDate: _lastEndDate,
      objectId: _lastObjectId,
      searchQuery: _lastSearchQuery,
      systemFilters: _lastSystemFilters,
      sectionFilters: _lastSectionFilters,
      floorFilters: _lastFloorFilters,
      page: state.currentPage - 1,
    );
  }

  /// Переключается на указанную страницу.
  Future<void> goToPage(int page) async {
    if (page < 1 || page > state.totalPages) return;
    await searchMaterials(
      startDate: _lastStartDate,
      endDate: _lastEndDate,
      objectId: _lastObjectId,
      searchQuery: _lastSearchQuery,
      systemFilters: _lastSystemFilters,
      sectionFilters: _lastSectionFilters,
      floorFilters: _lastFloorFilters,
      page: page,
    );
  }

  /// Очищает результаты поиска.
  void clearResults() {
    state = state.copyWith(results: [], error: null, totalCount: 0);
  }
}

/// Провайдер состояния поиска материалов.
final workSearchProvider =
    StateNotifierProvider<WorkSearchNotifier, WorkSearchState>((ref) {
  final repository = ref.watch(workSearchRepositoryProvider);
  return WorkSearchNotifier(repository);
});
