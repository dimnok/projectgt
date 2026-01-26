import '../entities/estimate.dart';
import '../entities/estimate_completion_history.dart';
import '../entities/ks6a_period.dart';

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
  Future<List<EstimateCompletionHistory>> getEstimateCompletionHistory(String estimateId);

  /// Получает список всех сметных позиций по конкретному договору.
  Future<List<Estimate>> getEstimatesByContract(String contractId);

  /// Получает историю выполнения для всех смет договора.
  Future<List<Map<String, dynamic>>> getContractCompletionHistory(String contractId);

  /// Создает новый черновик периода КС-6а.
  /// 
  /// [contractId] — договор, к которому относится период.
  /// [startDate], [endDate] — границы периода.
  /// Возвращает идентификатор созданного периода.
  Future<String> createKs6aPeriod({
    required String contractId,
    required DateTime startDate,
    required DateTime endDate,
    String? title,
  });

  /// Синхронизирует черновик периода КС-6а с актуальными отчетами (`work_items`).
  Future<void> refreshKs6aPeriod(String periodId);

  /// Утверждает период КС-6а, фиксируя его данные.
  Future<void> approveKs6aPeriod(String periodId);

  /// Получает полный набор данных КС-6а по договору (периоды + строки).
  Future<Ks6aContractData> getKs6aContractData(String contractId);
}
