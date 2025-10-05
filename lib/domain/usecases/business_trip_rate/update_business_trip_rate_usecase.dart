import 'package:projectgt/domain/entities/business_trip_rate.dart';
import 'package:projectgt/domain/repositories/business_trip_rate_repository.dart';

/// UseCase для обновления существующей ставки командировочных выплат.
///
/// Инкапсулирует бизнес-логику обновления ставки с валидацией данных.
///
/// Пример использования:
/// ```dart
/// final useCase = UpdateBusinessTripRateUseCase(repository);
/// final updatedRate = existingRate.copyWith(rate: 2000.0);
/// final result = await useCase(updatedRate);
/// ```
class UpdateBusinessTripRateUseCase {
  /// Репозиторий для работы с ставками командировочных.
  final BusinessTripRateRepository _repository;

  /// Конструктор [UpdateBusinessTripRateUseCase].
  ///
  /// [_repository] — репозиторий для работы с данными ставок.
  const UpdateBusinessTripRateUseCase(this._repository);

  /// Выполняет обновление ставки командировочных выплат.
  ///
  /// [rate] — ставка с обновлёнными данными.
  /// Возвращает обновлённую ставку.
  ///
  /// Может выбросить исключение при:
  /// - Некорректных данных ставки
  /// - Пересекающихся периодах действия
  /// - Ошибке сохранения в БД
  /// - Отсутствии ставки с указанным ID
  Future<BusinessTripRate> call(BusinessTripRate rate) async {
    // Валидация входных данных
    _validateRate(rate);

    // Дополнительная проверка корректности периода
    if (rate.validTo != null && rate.validTo!.isBefore(rate.validFrom)) {
      throw ArgumentError(
          'Дата окончания действия ставки не может быть раньше даты начала');
    }

    // Проверяем, что ставка существует
    final existingRate = await _repository.getRateById(rate.id);
    if (existingRate == null) {
      throw ArgumentError('Ставка с ID ${rate.id} не найдена');
    }

    return await _repository.updateRate(rate);
  }

  /// Валидирует данные ставки командировочных.
  ///
  /// [rate] — ставка для валидации.
  /// Выбрасывает [ArgumentError] при некорректных данных.
  void _validateRate(BusinessTripRate rate) {
    if (rate.id.trim().isEmpty) {
      throw ArgumentError('ID ставки не может быть пустым');
    }

    if (rate.objectId.trim().isEmpty) {
      throw ArgumentError('ID объекта не может быть пустым');
    }

    if (rate.rate < 0) {
      throw ArgumentError('Ставка командировочных не может быть отрицательной');
    }

    if (rate.rate > 100000) {
      throw ArgumentError(
          'Ставка командировочных не может превышать 100,000 рублей');
    }
  }
}
