import '../../data/datasources/work_search_data_source.dart';

/// Абстрактный репозиторий для поиска работ.
///
/// Определяет методы для поиска работ с фильтрацией по различным параметрам.
abstract class WorkSearchRepository {
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
  ///
  /// Возвращает уникальные значения фильтров [WorkSearchFilterValues].
  Future<WorkSearchFilterValues> getFilterValues({
    required String objectId,
    DateTime? startDate,
    DateTime? endDate,
  });
}
