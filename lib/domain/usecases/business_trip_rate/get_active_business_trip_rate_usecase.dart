import 'package:projectgt/domain/entities/business_trip_rate.dart';
import 'package:projectgt/domain/repositories/business_trip_rate_repository.dart';

/// UseCase для получения активной ставки командировочных на определённую дату.
///
/// Инкапсулирует бизнес-логику получения ставки, действующей на указанную дату.
///
/// Пример использования:
/// ```dart
/// final useCase = GetActiveBusinessTripRateUseCase(repository);
/// final rate = await useCase('object-id', DateTime.now());
/// ```
class GetActiveBusinessTripRateUseCase {
  /// Репозиторий для работы с ставками командировочных.
  final BusinessTripRateRepository _repository;

  /// Конструктор [GetActiveBusinessTripRateUseCase].
  ///
  /// [_repository] — репозиторий для работы с данными ставок.
  const GetActiveBusinessTripRateUseCase(this._repository);

  /// Выполняет получение активной ставки командировочных на дату.
  ///
  /// [objectId] — идентификатор объекта.
  /// [date] — дата, на которую нужно получить ставку.
  /// Возвращает ставку, действующую на указанную дату, или null если такой нет.
  ///
  /// Может выбросить исключение при ошибке получения данных или
  /// если параметры некорректны.
  Future<BusinessTripRate?> call(String objectId, DateTime date) async {
    if (objectId.trim().isEmpty) {
      throw ArgumentError('ID объекта не может быть пустым');
    }

    return await _repository.getActiveRateForDate(objectId, date);
  }
}
