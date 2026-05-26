import '../entities/estimate.dart';
import '../entities/estimate_bulk_update.dart';
import '../entities/estimate_completion_history.dart';
import '../entities/estimate_revision.dart';
import '../entities/vor.dart';
import '../entities/vor_recalc_preview.dart';
import 'dart:io';
import 'dart:typed_data';

/// Абстракция репозитория для работы со сметами.
///
/// Определяет методы для получения, создания, обновления и удаления смет.
abstract class EstimateRepository {
  /// Получает список всех смет.
  Future<List<Estimate>> getEstimates();

  /// Получает смету по идентификатору [id].
  Future<Estimate?> getEstimate(String id);

  /// Создаёт новую смету [estimate].
  Future<void> createEstimate(Estimate estimate);

  /// Обновляет существующую смету [estimate].
  Future<void> updateEstimate(Estimate estimate);

  /// Удаляет смету по идентификатору [id].
  Future<void> deleteEstimate(String id);

  /// Получает список уникальных систем из всех смет.
  /// Если [estimateTitle] указан, возвращает только системы из этой сметы.
  Future<List<String>> getSystems({String? estimateTitle});

  /// Получает список уникальных подсистем из всех смет.
  /// Если [estimateTitle] указан, возвращает только подсистемы из этой сметы.
  Future<List<String>> getSubsystems({String? estimateTitle});

  /// Получает список уникальных единиц измерения из всех смет.
  /// Если [estimateTitle] указан, возвращает только единицы измерения из этой сметы.
  Future<List<String>> getUnits({String? estimateTitle});

  /// Получает историю выполнения для конкретной позиции сметы.
  Future<List<EstimateCompletionHistory>> getEstimateCompletionHistory(
    String estimateId,
  );

  /// Получает список всех сметных позиций по конкретному договору.
  Future<List<Estimate>> getEstimatesByContract(String contractId);

  /// Получает список всех ВОР по договору.
  Future<List<Vor>> getVors(String contractId);

  /// Создает новую ведомость ВОР.
  Future<String> createVor({
    required String contractId,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> systems,
    bool includeCombinedSheet = false,
  });

  /// Обновляет статус ведомости ВОР.
  Future<void> updateVorStatus(
    String vorId,
    VorStatus status, {
    String? comment,
  });

  /// Удаляет ведомость ВОР.
  Future<void> deleteVor(String vorId);

  /// Наполняет состав ведомости ВОР фактически выполненными работами.
  Future<void> populateVorItems(String vorId);

  /// Пересчитывает состав черновика ВОР из журналов работ без удаления ведомости.
  Future<void> recalculateVor(String vorId);

  /// Возвращает признак необходимости пересчёта для черновиков ВОР по договору.
  Future<Map<String, bool>> getDraftVorNeedsRecalc(String contractId);

  /// Возвращает список отличий для окна подтверждения пересчёта ВОР.
  Future<VorRecalcPreview> getVorRecalcChanges(String vorId);

  /// Загружает подписанный PDF-файл для ведомости ВОР.
  Future<void> uploadVorPdf({
    required String vorId,
    required File file,
    required String fileName,
  });

  /// Создает временную ссылку для просмотра PDF-файла ведомости ВОР.
  Future<String> getVorPdfViewUrl(String vorId);

  /// Возвращает строки текущей сметы для выгрузки шаблона LC / ДС.
  ///
  /// Новый поток работает параллельно старому `estimates` flow и не заменяет его.
  Future<List<EstimateAddendumTemplateRow>> getAddendumTemplateRows({
    required String estimateTitle,
    required String contractId,
    String? objectId,
  });

  /// Возвращает готовый Excel-файл шаблона LC / ДС, сгенерированный на сервере.
  Future<Map<String, dynamic>> getAddendumTemplateFile({
    required String estimateTitle,
    required String contractId,
    String? objectId,
  });

  /// Excel со сметой по договору и колонками ДС (Edge Function `export-contract-estimate-addenda`).
  Future<Map<String, dynamic>> exportContractEstimateWithAddendaExcel({
    required String estimateTitle,
    required String contractId,
    String? objectId,
  });

  /// Read-only история позиции по ревизиям (базовая + ДС), без изменения [estimates].
  Future<List<EstimatePositionAddendumHistoryEntry>>
  getEstimatePositionAddendumHistory({
    required String contractId,
    required String estimateTitle,
    required String estimateRowId,
  });

  /// Создаёт ревизию LC / ДС (в БД — сразу «согласовано») и сохраняет строки в новых таблицах.
  ///
  /// Старые таблицы `estimates` и текущие ВОР при этом не меняются до вызова
  /// [applyAddendumRevisionToEstimates].
  Future<EstimateRevisionDraftResult> createEstimateRevisionDraft({
    required String estimateTitle,
    required String contractId,
    String? objectId,
    required String fileName,
    required Uint8List fileBytes,
    required List<EstimateAddendumImportRow> rows,
    DateTime? effectiveFrom,
    String? userDescription,
  });

  /// Переносит снимок ревизии ДС в таблицу `estimates` (данные ДС имеют приоритет).
  Future<EstimateBulkUpdateResult> applyAddendumRevisionToEstimates({
    required String revisionId,
  });

  /// Обновляет дату действия и краткое описание ревизии ДС.
  Future<void> updateEstimateRevisionMetadata({
    required String revisionId,
    DateTime? effectiveFrom,
    String? userDescription,
  });

  /// Удаляет ревизию ДС и её строки, если ДС ещё не перенесён в `estimates`
  /// и нет другой ревизии с `based_on_revision_id`, указывающего на эту.
  Future<void> deleteAddendumRevision({required String revisionId});

  /// Возвращает строки текущей сметы для Excel-файла массового обновления.
  Future<List<EstimateBulkUpdateTemplateRow>> getBulkUpdateTemplateRows({
    required String estimateTitle,
    required String contractId,
    String? objectId,
  });

  /// Возвращает готовый Excel-файл массового обновления, сгенерированный на сервере.
  Future<Map<String, dynamic>> getBulkUpdateTemplateFile({
    required String estimateTitle,
    required String contractId,
    String? objectId,
  });

  /// Пустой Excel-шаблон импорта сметы (заголовки и пример строки), сгенерированный на сервере.
  ///
  /// [contractId] — если задан и договор доступен, в имя файла включается номер договора и дата.
  Future<Map<String, dynamic>> getEstimateImportTemplateFile({
    String? contractId,
  });

  /// Проверяет Excel-строки массового обновления без изменения данных.
  Future<EstimateBulkUpdateResult> previewBulkUpdate({
    required String estimateTitle,
    required String contractId,
    String? objectId,
    required List<EstimateBulkUpdateImportRow> rows,
    String? sourceFileName,
  });

  /// Применяет Excel-строки массового обновления транзакционно через RPC.
  Future<EstimateBulkUpdateResult> applyBulkUpdate({
    required String estimateTitle,
    required String contractId,
    String? objectId,
    required List<EstimateBulkUpdateImportRow> rows,
    String? sourceFileName,
  });
}
