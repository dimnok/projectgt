import '../models/export_filter_model.dart';
import '../models/export_report_model.dart';

/// Абстрактный источник данных для работы с выгрузкой.
///
/// Определяет методы для получения агрегированных данных из базы данных.
abstract class ExportDataSource {
  /// Возвращает список агрегированных данных по работам согласно фильтру.
  Future<List<ExportReportModel>> getExportData(ExportFilterModel filter);

  /// Возвращает список доступных объектов для фильтрации.
  Future<List<Map<String, dynamic>>> getAvailableObjects();

  /// Возвращает список доступных договоров для фильтрации.
  Future<List<Map<String, dynamic>>> getAvailableContracts();

  /// Возвращает список доступных систем для фильтрации.
  Future<List<String>> getAvailableSystems();

  /// Возвращает список доступных подсистем для фильтрации.
  Future<List<String>> getAvailableSubsystems();
}
