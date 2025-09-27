import '../entities/export_filter.dart';
import '../entities/export_report.dart';

/// Абстрактный репозиторий для работы с выгрузкой данных.
///
/// Определяет методы для получения агрегированных данных по работам.
abstract class ExportRepository {
  /// Возвращает список агрегированных данных по работам согласно фильтру.
  Future<List<ExportReport>> getExportData(ExportFilter filter);

  /// Возвращает список доступных объектов для фильтрации.
  Future<List<Map<String, dynamic>>> getAvailableObjects();

  /// Возвращает список доступных договоров для фильтрации.
  Future<List<Map<String, dynamic>>> getAvailableContracts();

  /// Возвращает список доступных систем для фильтрации.
  Future<List<String>> getAvailableSystems();

  /// Возвращает список доступных подсистем для фильтрации.
  Future<List<String>> getAvailableSubsystems();
}
