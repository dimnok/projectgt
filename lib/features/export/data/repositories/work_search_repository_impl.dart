import '../../domain/entities/work_search_result.dart';
import '../../domain/repositories/work_search_repository.dart';
import '../datasources/work_search_data_source.dart';

/// Реализация репозитория для поиска работ.
class WorkSearchRepositoryImpl implements WorkSearchRepository {
  /// Источник данных для поиска.
  final WorkSearchDataSource dataSource;

  /// Создаёт реализацию репозитория.
  WorkSearchRepositoryImpl(this.dataSource);

  @override
  Future<List<WorkSearchResult>> searchMaterials({
    required String searchQuery,
    DateTime? startDate,
    DateTime? endDate,
    String? objectId,
  }) async {
    try {
      return await dataSource.searchMaterials(
        searchQuery: searchQuery,
        startDate: startDate,
        endDate: endDate,
        objectId: objectId,
      );
    } catch (e) {
      throw Exception('Ошибка поиска работ в репозитории: $e');
    }
  }
}
