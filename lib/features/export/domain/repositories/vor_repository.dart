import 'dart:typed_data';

/// Интерфейс репозитория для генерации отчетов ВОР.
abstract class VorRepository {
  /// Скачивает отчет ВОР в формате Excel.
  ///
  /// [objectId] - ID объекта.
  /// [dateFrom] - Начальная дата периода.
  /// [dateTo] - Конечная дата периода.
  /// [systemFilters] - Фильтры по системам.
  /// [sectionFilters] - Фильтры по разделам.
  /// [floorFilters] - Фильтры по этажам.
  /// [searchQuery] - Поисковый запрос.
  Future<Uint8List> downloadVorReport({
    required String objectId,
    required DateTime dateFrom,
    required DateTime dateTo,
    List<String>? systemFilters,
    List<String>? sectionFilters,
    List<String>? floorFilters,
    String? searchQuery,
  });

  /// Скачивает отчет ВОР в формате PDF.
  ///
  /// [objectId] - ID объекта.
  /// [dateFrom] - Начальная дата периода.
  /// [dateTo] - Конечная дата периода.
  /// [systemFilters] - Фильтры по системам.
  /// [sectionFilters] - Фильтры по разделам.
  /// [floorFilters] - Фильтры по этажам.
  /// [searchQuery] - Поисковый запрос.
  Future<Uint8List> downloadVorPdfReport({
    required String objectId,
    required DateTime dateFrom,
    required DateTime dateTo,
    List<String>? systemFilters,
    List<String>? sectionFilters,
    List<String>? floorFilters,
    String? searchQuery,
  });
}
