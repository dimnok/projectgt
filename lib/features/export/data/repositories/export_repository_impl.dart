import '../../domain/entities/export_filter.dart';
import '../../domain/entities/export_report.dart';
import '../../domain/repositories/export_repository.dart';
import '../datasources/export_data_source.dart';
import '../models/export_filter_model.dart';
import '../models/export_report_model.dart';

/// Реализация репозитория для работы с выгрузкой данных.
class ExportRepositoryImpl implements ExportRepository {
  /// Источник данных для выгрузки.
  final ExportDataSource dataSource;

  /// Создаёт реализацию репозитория выгрузки.
  ExportRepositoryImpl({
    required this.dataSource,
  });

  @override
  Future<List<ExportReport>> getExportData(ExportFilter filter) async {
    final filterModel = _mapFilterToModel(filter);
    final reportModels = await dataSource.getExportData(filterModel);
    return reportModels.map(_mapReportModelToEntity).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getAvailableObjects() async {
    return await dataSource.getAvailableObjects();
  }

  @override
  Future<List<Map<String, dynamic>>> getAvailableContracts() async {
    return await dataSource.getAvailableContracts();
  }

  @override
  Future<List<String>> getAvailableSystems() async {
    return await dataSource.getAvailableSystems();
  }

  @override
  Future<List<String>> getAvailableSubsystems() async {
    return await dataSource.getAvailableSubsystems();
  }

  /// Маппинг фильтра из domain в data модель.
  ExportFilterModel _mapFilterToModel(ExportFilter filter) {
    return ExportFilterModel(
      dateFrom: filter.dateFrom,
      dateTo: filter.dateTo,
      objectIds: filter.objectIds,
      contractIds: filter.contractIds,
      systems: filter.systems,
      subsystems: filter.subsystems,
    );
  }

  /// Маппинг отчета из data модели в domain сущность.
  ExportReport _mapReportModelToEntity(ExportReportModel model) {
    return ExportReport(
      workDate: model.workDate,
      objectName: model.objectName,
      contractName: model.contractName,
      system: model.system,
      subsystem: model.subsystem,
      positionNumber: model.positionNumber,
      workName: model.workName,
      section: model.section,
      floor: model.floor,
      unit: model.unit,
      quantity: model.quantity,
      price: model.price,
      total: model.total,
      employeeName: model.employeeName,
      hours: model.hours,
      materials: model.materials,
    );
  }
} 