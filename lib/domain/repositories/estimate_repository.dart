import '../entities/estimate.dart';
import '../entities/estimate_completion_history.dart';
import '../entities/estimate_revision.dart';
import '../entities/vor.dart';
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

  /// Создаёт черновик ревизии LC / ДС и сохраняет строки в новых таблицах.
  ///
  /// Старые таблицы `estimates` и текущие ВОР при этом не меняются.
  Future<EstimateRevisionDraftResult> createEstimateRevisionDraft({
    required String estimateTitle,
    required String contractId,
    String? objectId,
    required String fileName,
    required Uint8List fileBytes,
    required List<EstimateAddendumImportRow> rows,
  });
}
