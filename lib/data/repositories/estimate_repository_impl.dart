import '../../domain/entities/estimate.dart';
import '../../domain/entities/estimate_bulk_update.dart';
import '../../domain/entities/estimate_completion_history.dart';
import '../../domain/entities/estimate_revision.dart';
import '../../domain/entities/vor.dart';
import '../../domain/entities/vor_recalc_preview.dart';
import '../../domain/repositories/estimate_repository.dart';
import 'dart:io';
import 'dart:typed_data';
import '../datasources/estimate_data_source.dart';
import '../models/estimate_model.dart';
import '../models/estimate_completion_model.dart';

/// Реализация репозитория EstimateRepository для работы со сметами через data source.
class EstimateRepositoryImpl implements EstimateRepository {
  /// Источник данных для смет.
  final EstimateDataSource dataSource;

  /// Создаёт экземпляр [EstimateRepositoryImpl] с источником [dataSource].
  EstimateRepositoryImpl(this.dataSource);

  /// Получает список всех смет.
  @override
  Future<List<Estimate>> getEstimates() async {
    final models = await dataSource.getEstimates();
    return models.map((e) => e.toDomain()).toList();
  }

  /// Получает смету по идентификатору [id].
  @override
  Future<Estimate?> getEstimate(String id) async {
    final model = await dataSource.getEstimate(id);
    return model?.toDomain();
  }

  /// Создаёт новую смету [estimate].
  @override
  Future<void> createEstimate(Estimate estimate) async {
    await dataSource.createEstimate(estimate.toModel());
  }

  /// Обновляет существующую смету [estimate].
  @override
  Future<void> updateEstimate(Estimate estimate) async {
    await dataSource.updateEstimate(estimate.toModel());
  }

  /// Удаляет смету по идентификатору [id].
  @override
  Future<void> deleteEstimate(String id) async {
    await dataSource.deleteEstimate(id);
  }

  /// Получает список уникальных систем из всех смет.
  @override
  Future<List<String>> getSystems({String? estimateTitle}) async {
    return dataSource.getSystems(estimateTitle: estimateTitle);
  }

  /// Получает список уникальных подсистем из всех смет.
  @override
  Future<List<String>> getSubsystems({String? estimateTitle}) async {
    return dataSource.getSubsystems(estimateTitle: estimateTitle);
  }

  /// Получает сгруппированный список смет (заголовки).
  Future<List<Map<String, dynamic>>> getEstimateGroups() async {
    if (dataSource is SupabaseEstimateDataSource) {
      return (dataSource as SupabaseEstimateDataSource).getEstimateGroups();
    }
    return [];
  }

  /// Получает позиции сметы по фильтру (заголовок + объект + договор).
  Future<List<Estimate>> getEstimatesByFile({
    required String estimateTitle,
    String? objectId,
    String? contractId,
  }) async {
    if (dataSource is SupabaseEstimateDataSource) {
      final models = await (dataSource as SupabaseEstimateDataSource)
          .getEstimatesByFile(
            estimateTitle: estimateTitle,
            objectId: objectId,
            contractId: contractId,
          );
      return models.map((e) => e.toDomain()).toList();
    }
    return [];
  }

  /// Получает выполнение только для указанных ID сметных позиций.
  Future<List<EstimateCompletionModel>> getEstimateCompletionByIds(
    List<String> estimateIds,
  ) async {
    if (dataSource is SupabaseEstimateDataSource) {
      return (dataSource as SupabaseEstimateDataSource)
          .getEstimateCompletionByIds(estimateIds);
    }
    return [];
  }

  /// Получает список уникальных единиц измерения из всех смет.
  @override
  Future<List<String>> getUnits({String? estimateTitle}) async {
    return dataSource.getUnits(estimateTitle: estimateTitle);
  }

  @override
  Future<List<EstimateCompletionHistory>> getEstimateCompletionHistory(
    String estimateId,
  ) async {
    final rawData = await dataSource.getEstimateCompletionHistory(estimateId);

    final history = rawData.map((row) {
      final works = row['works'] as Map<String, dynamic>?;
      final dateStr = works?['date'] as String?;
      final quantity = (row['quantity'] as num?)?.toDouble() ?? 0.0;
      final section = row['section'] as String? ?? '';
      final floor = row['floor'] as String? ?? '';

      return EstimateCompletionHistory(
        date: dateStr != null ? DateTime.parse(dateStr) : DateTime.now(),
        quantity: quantity,
        section: section,
        floor: floor,
      );
    }).toList();

    // Сортируем: сначала новые даты (по убыванию)
    history.sort((a, b) => b.date.compareTo(a.date));

    return history;
  }

  @override
  Future<List<Estimate>> getEstimatesByContract(String contractId) async {
    final models = await dataSource.getEstimatesByContract(contractId);
    return models.map((e) => e.toDomain()).toList();
  }

  @override
  Future<List<Vor>> getVors(String contractId) async {
    final models = await dataSource.getVors(contractId);
    return models.map((m) => m.toDomain()).toList();
  }

  @override
  Future<String> createVor({
    required String contractId,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> systems,
    bool includeCombinedSheet = false,
  }) async {
    return dataSource.createVor(
      contractId: contractId,
      startDate: startDate,
      endDate: endDate,
      systems: systems,
      includeCombinedSheet: includeCombinedSheet,
    );
  }

  @override
  Future<void> updateVorStatus(
    String vorId,
    VorStatus status, {
    String? comment,
  }) async {
    await dataSource.updateVorStatus(vorId, status, comment: comment);
  }

  @override
  Future<void> deleteVor(String vorId) async {
    await dataSource.deleteVor(vorId);
  }

  @override
  Future<void> populateVorItems(String vorId) async {
    await dataSource.populateVorItems(vorId);
  }

  @override
  Future<void> recalculateVor(String vorId) async {
    await dataSource.recalculateVor(vorId);
  }

  @override
  Future<Map<String, bool>> getDraftVorNeedsRecalc(String contractId) async {
    return dataSource.getDraftVorNeedsRecalc(contractId);
  }

  @override
  Future<VorRecalcPreview> getVorRecalcChanges(String vorId) async {
    final raw = await dataSource.getVorRecalcChangesRaw(vorId);
    return VorRecalcPreview(
      changes: raw.map(VorRecalcChange.fromJson).toList(),
    );
  }

  @override
  Future<void> uploadVorPdf({
    required String vorId,
    required File file,
    required String fileName,
  }) async {
    await dataSource.uploadVorPdf(vorId: vorId, file: file, fileName: fileName);
  }

  @override
  Future<String> getVorPdfViewUrl(String vorId) {
    return dataSource.getVorPdfViewUrl(vorId);
  }

  @override
  Future<List<EstimateAddendumTemplateRow>> getAddendumTemplateRows({
    required String estimateTitle,
    required String contractId,
    String? objectId,
  }) {
    return dataSource.getAddendumTemplateRows(
      estimateTitle: estimateTitle,
      contractId: contractId,
      objectId: objectId,
    );
  }

  @override
  Future<Map<String, dynamic>> getAddendumTemplateFile({
    required String estimateTitle,
    required String contractId,
    String? objectId,
  }) {
    return dataSource.getAddendumTemplateFile(
      estimateTitle: estimateTitle,
      contractId: contractId,
      objectId: objectId,
    );
  }

  @override
  Future<Map<String, dynamic>> exportContractEstimateWithAddendaExcel({
    required String estimateTitle,
    required String contractId,
    String? objectId,
  }) {
    return dataSource.exportContractEstimateWithAddendaExcel(
      estimateTitle: estimateTitle,
      contractId: contractId,
      objectId: objectId,
    );
  }

  @override
  Future<Map<String, dynamic>> exportContractEstimateWithExecutionExcel({
    required String estimateTitle,
    required String contractId,
    String? objectId,
  }) {
    return dataSource.exportContractEstimateWithExecutionExcel(
      estimateTitle: estimateTitle,
      contractId: contractId,
      objectId: objectId,
    );
  }

  @override
  Future<List<EstimatePositionAddendumHistoryEntry>>
  getEstimatePositionAddendumHistory({
    required String contractId,
    required String estimateTitle,
    required String estimateRowId,
  }) {
    return dataSource.getEstimatePositionAddendumHistory(
      contractId: contractId,
      estimateTitle: estimateTitle,
      estimateRowId: estimateRowId,
    );
  }

  @override
  Future<EstimateRevisionDraftResult> createEstimateRevisionDraft({
    required String estimateTitle,
    required String contractId,
    String? objectId,
    required String fileName,
    required Uint8List fileBytes,
    required List<EstimateAddendumImportRow> rows,
    DateTime? effectiveFrom,
    String? userDescription,
  }) {
    return dataSource.createEstimateRevisionDraft(
      estimateTitle: estimateTitle,
      contractId: contractId,
      objectId: objectId,
      fileName: fileName,
      fileBytes: fileBytes,
      rows: rows,
      effectiveFrom: effectiveFrom,
      userDescription: userDescription,
    );
  }

  @override
  Future<EstimateBulkUpdateResult> applyAddendumRevisionToEstimates({
    required String revisionId,
  }) {
    return dataSource.applyAddendumRevisionToEstimates(revisionId: revisionId);
  }

  @override
  Future<void> updateEstimateRevisionMetadata({
    required String revisionId,
    DateTime? effectiveFrom,
    String? userDescription,
  }) {
    return dataSource.updateEstimateRevisionMetadata(
      revisionId: revisionId,
      effectiveFrom: effectiveFrom,
      userDescription: userDescription,
    );
  }

  @override
  Future<void> deleteAddendumRevision({required String revisionId}) {
    return dataSource.deleteAddendumRevision(revisionId: revisionId);
  }

  @override
  Future<List<EstimateBulkUpdateTemplateRow>> getBulkUpdateTemplateRows({
    required String estimateTitle,
    required String contractId,
    String? objectId,
  }) {
    return dataSource.getBulkUpdateTemplateRows(
      estimateTitle: estimateTitle,
      contractId: contractId,
      objectId: objectId,
    );
  }

  @override
  Future<Map<String, dynamic>> getBulkUpdateTemplateFile({
    required String estimateTitle,
    required String contractId,
    String? objectId,
  }) {
    return dataSource.getBulkUpdateTemplateFile(
      estimateTitle: estimateTitle,
      contractId: contractId,
      objectId: objectId,
    );
  }

  @override
  Future<Map<String, dynamic>> getEstimateImportTemplateFile({
    String? contractId,
  }) {
    return dataSource.getEstimateImportTemplateFile(contractId: contractId);
  }

  @override
  Future<EstimateBulkUpdateResult> previewBulkUpdate({
    required String estimateTitle,
    required String contractId,
    String? objectId,
    required List<EstimateBulkUpdateImportRow> rows,
    String? sourceFileName,
  }) {
    return dataSource.runBulkUpdate(
      estimateTitle: estimateTitle,
      contractId: contractId,
      objectId: objectId,
      rows: rows,
      dryRun: true,
      sourceFileName: sourceFileName,
    );
  }

  @override
  Future<EstimateBulkUpdateResult> applyBulkUpdate({
    required String estimateTitle,
    required String contractId,
    String? objectId,
    required List<EstimateBulkUpdateImportRow> rows,
    String? sourceFileName,
  }) {
    return dataSource.runBulkUpdate(
      estimateTitle: estimateTitle,
      contractId: contractId,
      objectId: objectId,
      rows: rows,
      dryRun: false,
      sourceFileName: sourceFileName,
    );
  }
}
