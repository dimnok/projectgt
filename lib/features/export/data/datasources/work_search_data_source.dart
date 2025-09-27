import '../../domain/entities/work_search_result.dart';

/// Абстрактный источник данных для поиска работ.
///
/// Определяет методы для получения данных из внешних источников.
abstract class WorkSearchDataSource {
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
