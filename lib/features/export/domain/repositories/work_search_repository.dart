import '../entities/work_search_result.dart';

/// Абстрактный репозиторий для поиска работ.
/// 
/// Определяет методы для поиска работ с фильтрацией по различным параметрам.
abstract class WorkSearchRepository {
  /// Выполняет поиск работ по параметрам.
  /// 
  /// [searchQuery] — поисковый запрос по наименованию работ
  /// [startDate] — дата начала периода (опционально)
  /// [endDate] — дата окончания периода (опционально)
  /// [objectId] — идентификатор объекта (опционально)
  /// 
  /// Возвращает список результатов поиска [WorkSearchResult].
  Future<List<WorkSearchResult>> searchMaterials({
    required String searchQuery,
    DateTime? startDate,
    DateTime? endDate,
    String? objectId,
  });
} 