import 'package:projectgt/domain/entities/business_trip_rate.dart';
import 'package:projectgt/domain/repositories/business_trip_rate_repository.dart';

/// UseCase для создания новой ставки командировочных выплат.
///
/// Инкапсулирует бизнес-логику создания ставки с валидацией данных.
///
/// Пример использования:
/// ```dart
/// final useCase = CreateBusinessTripRateUseCase(repository);
/// final rate = BusinessTripRate(
///   id: 'new-id',
///   objectId: 'object-id',
///   rate: 1500.0,
///   validFrom: DateTime.now(),
/// );
/// final created = await useCase(rate);
/// ```
class CreateBusinessTripRateUseCase {
  /// Репозиторий для работы с ставками командировочных.
  final BusinessTripRateRepository _repository;

  /// Конструктор [CreateBusinessTripRateUseCase].
  ///
  /// [_repository] — репозиторий для работы с данными ставок.
  const CreateBusinessTripRateUseCase(this._repository);

  /// Выполняет создание новой ставки командировочных выплат.
  ///
  /// [rate] — ставка для создания.
  /// Возвращает созданную ставку с заполненными системными полями.
  ///
  /// Может выбросить исключение при:
  /// - Некорректных данных ставки
  /// - Пересекающихся периодах действия
  /// - Ошибке сохранения в БД
  Future<BusinessTripRate> call(BusinessTripRate rate) async {
    // Валидация входных данных
    _validateRate(rate);

    // Дополнительная проверка корректности периода
    if (rate.validTo != null && rate.validTo!.isBefore(rate.validFrom)) {
      throw ArgumentError(
          'Дата окончания действия ставки не может быть раньше даты начала');
    }

    return await _repository.createRate(rate);
  }

  /// Валидирует данные ставки командировочных.
  ///
  /// [rate] — ставка для валидации.
  /// Выбрасывает [ArgumentError] при некорректных данных.
  void _validateRate(BusinessTripRate rate) {
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
