import 'package:projectgt/domain/entities/business_trip_rate.dart';

/// Абстрактный репозиторий для работы с ставками командировочных выплат.
///
/// Определяет контракт для работы с данными командировочных ставок.
/// Реализация должна находиться в слое data.
///
/// Пример использования:
/// ```dart
/// final repository = BusinessTripRateRepositoryImpl();
/// final rates = await repository.getAllRates();
/// ```
abstract class BusinessTripRateRepository {
  /// Получает все ставки командировочных выплат.
  ///
  /// Возвращает список всех ставок, отсортированных по дате создания.
  Future<List<BusinessTripRate>> getAllRates();

  /// Получает ставки командировочных для конкретного объекта.
  ///
  /// [objectId] — идентификатор объекта.
  /// Возвращает список ставок для указанного объекта.
  Future<List<BusinessTripRate>> getRatesByObjectId(String objectId);

  /// Получает активную ставку командировочных для объекта на указанную дату.
  ///
  /// [objectId] — идентификатор объекта.
  /// [date] — дата, на которую нужно получить ставку.
  /// Возвращает ставку, действующую на указанную дату, или null если такой нет.
  Future<BusinessTripRate?> getActiveRateForDate(
      String objectId, DateTime date);

  /// Получает текущую активную ставку для объекта.
  ///
  /// [objectId] — идентификатор объекта.
  /// Возвращает ставку, действующую на текущую дату, или null если такой нет.
  Future<BusinessTripRate?> getCurrentRate(String objectId);

  /// Создаёт новую ставку командировочных выплат.
  ///
  /// [rate] — ставка для создания.
  /// Возвращает созданную ставку с заполненными системными полями.
  ///
  /// Может выбросить исключение, если есть пересекающиеся периоды.
  Future<BusinessTripRate> createRate(BusinessTripRate rate);

  /// Обновляет существующую ставку командировочных выплат.
  ///
  /// [rate] — ставка с обновлёнными данными.
  /// Возвращает обновлённую ставку.
  ///
  /// Может выбросить исключение, если есть пересекающиеся периоды.
  Future<BusinessTripRate> updateRate(BusinessTripRate rate);

  /// Удаляет ставку командировочных выплат.
  ///
  /// [id] — идентификатор ставки для удаления.
  Future<void> deleteRate(String id);

  /// Получает ставку по идентификатору.
  ///
  /// [id] — идентификатор ставки.
  /// Возвращает ставку или null, если не найдена.
  Future<BusinessTripRate?> getRateById(String id);

  /// Проверяет, есть ли пересекающиеся периоды для объекта и сотрудника.
  ///
  /// [objectId] — идентификатор объекта.
  /// [employeeId] — идентификатор сотрудника.
  /// [validFrom] — дата начала нового периода.
  /// [validTo] — дата окончания нового периода (может быть null).
  /// [excludeId] — идентификатор ставки, которую нужно исключить из проверки.
  ///
  /// Возвращает true, если есть пересекающиеся периоды.
  Future<bool> hasOverlappingPeriods(
    String objectId,
    String? employeeId,
    DateTime validFrom,
    DateTime? validTo, [
    String? excludeId,
  ]);
}
