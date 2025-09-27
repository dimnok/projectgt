import '../entities/estimate.dart';

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
}
