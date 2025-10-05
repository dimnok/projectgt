import 'package:projectgt/domain/entities/business_trip_rate.dart';
import 'package:projectgt/domain/repositories/business_trip_rate_repository.dart';

/// UseCase для получения ставок командировочных выплат для конкретного объекта.
///
/// Инкапсулирует бизнес-логику получения ставок для определённого объекта.
///
/// Пример использования:
/// ```dart
/// final useCase = GetBusinessTripRatesByObjectUseCase(repository);
/// final rates = await useCase('object-id');
/// ```
class GetBusinessTripRatesByObjectUseCase {
  /// Репозиторий для работы с ставками командировочных.
  final BusinessTripRateRepository _repository;

  /// Конструктор [GetBusinessTripRatesByObjectUseCase].
  ///
  /// [_repository] — репозиторий для работы с данными ставок.
  const GetBusinessTripRatesByObjectUseCase(this._repository);

  /// Выполняет получение ставок командировочных для объекта.
  ///
  /// [objectId] — идентификатор объекта.
  /// Возвращает список ставок для указанного объекта.
  ///
  /// Может выбросить исключение при ошибке получения данных или
  /// если objectId пустой.
  Future<List<BusinessTripRate>> call(String objectId) async {
    if (objectId.trim().isEmpty) {
      throw ArgumentError('ID объекта не может быть пустым');
    }

    return await _repository.getRatesByObjectId(objectId);
  }
}
