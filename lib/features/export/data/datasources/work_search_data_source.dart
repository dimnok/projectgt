import '../../domain/entities/work_search_result.dart';

/// Результат поиска с пагинацией.
class WorkSearchPaginatedResult {
  /// Результаты поиска для текущей страницы.
  final List<WorkSearchResult> results;

  /// Общее количество результатов.
  final int totalCount;

  /// Общее количество (сумма по всем страницам).
  final num totalQuantity;

  /// Общая сумма (сумма по всем страницам).
  final double? totalSum;

  /// Текущая страница (начинается с 1).
  final int currentPage;

  /// Размер страницы.
  final int pageSize;

  /// Общее количество страниц.
  int get totalPages => (totalCount / pageSize).ceil();

  /// Создаёт результат поиска с пагинацией.
  const WorkSearchPaginatedResult({
    required this.results,
    required this.totalCount,
    required this.totalQuantity,
    this.totalSum,
    required this.currentPage,
    required this.pageSize,
  });
}

/// Уникальные значения фильтров для объекта.
class WorkSearchFilterValues {
  /// Уникальные системы.
  final List<String> systems;

  /// Уникальные участки.
  final List<String> sections;

  /// Уникальные этажи.
  final List<String> floors;

  /// Создаёт значения фильтров.
  const WorkSearchFilterValues({
    required this.systems,
    required this.sections,
    required this.floors,
  });
}

/// Абстрактный источник данных для поиска работ.
///
/// Определяет методы для получения данных из внешних источников.
abstract class WorkSearchDataSource {
  /// Выполняет поиск работ по параметрам с пагинацией.
  ///
  /// [searchQuery] — поисковый запрос по наименованию работ (опционально)
  /// [startDate] — дата начала периода (опционально)
  /// [endDate] — дата окончания периода (опционально)
  /// [objectId] — идентификатор объекта (опционально)
  /// [page] — номер страницы (начинается с 1)
  /// [pageSize] — размер страницы
  /// [systemFilters] — фильтр по системам (опционально)
  /// [sectionFilters] — фильтр по участкам (опционально)
  /// [floorFilters] — фильтр по этажам (опционально)
  ///
  /// Возвращает результат поиска с пагинацией [WorkSearchPaginatedResult].
  Future<WorkSearchPaginatedResult> searchMaterials({
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
    String? objectId,
    int page = 1,
    int pageSize = 250,
    List<String>? systemFilters,
    List<String>? sectionFilters,
    List<String>? floorFilters,
  });

  /// Получает уникальные значения фильтров (системы, участки, этажи) для объекта.
  ///
  /// [objectId] — идентификатор объекта (обязательно)
  /// [startDate] — дата начала периода (опционально)
  /// [endDate] — дата окончания периода (опционально)
  /// [systemFilters] — текущие фильтры по системам (для каскада)
  /// [sectionFilters] — текущие фильтры по участкам (для каскада)
  /// [searchQuery] — текущий поисковый запрос (для каскада)
  ///
  /// Возвращает уникальные значения фильтров [WorkSearchFilterValues].
  Future<WorkSearchFilterValues> getFilterValues({
    required String objectId,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? systemFilters,
    List<String>? sectionFilters,
    String? searchQuery,
  });
}
