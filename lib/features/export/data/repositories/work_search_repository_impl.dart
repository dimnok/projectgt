import '../../domain/repositories/work_search_repository.dart';
import '../datasources/work_search_data_source.dart';

/// Реализация репозитория для поиска работ.
class WorkSearchRepositoryImpl implements WorkSearchRepository {
  /// Источник данных для поиска.
  final WorkSearchDataSource dataSource;

  /// Создаёт реализацию репозитория.
  WorkSearchRepositoryImpl(this.dataSource);

  @override
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
  }) async {
    try {
      return await dataSource.searchMaterials(
        searchQuery: searchQuery,
        startDate: startDate,
        endDate: endDate,
        objectId: objectId,
        page: page,
        pageSize: pageSize,
        systemFilters: systemFilters,
        sectionFilters: sectionFilters,
        floorFilters: floorFilters,
      );
    } catch (e) {
      throw Exception('Ошибка поиска работ в репозитории: $e');
    }
  }

  @override
  Future<WorkSearchFilterValues> getFilterValues({
    required String objectId,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? systemFilters,
    List<String>? sectionFilters,
    String? searchQuery,
  }) async {
    try {
      return await dataSource.getFilterValues(
        objectId: objectId,
        startDate: startDate,
        endDate: endDate,
        systemFilters: systemFilters,
        sectionFilters: sectionFilters,
        searchQuery: searchQuery,
      );
    } catch (e) {
      throw Exception('Ошибка получения значений фильтров в репозитории: $e');
    }
  }
}
