import 'package:projectgt/domain/entities/business_trip_rate.dart';
import 'package:projectgt/domain/repositories/business_trip_rate_repository.dart';

/// UseCase для получения всех ставок командировочных выплат.
///
/// Инкапсулирует бизнес-логику получения списка всех ставок командировочных.
///
/// Пример использования:
/// ```dart
/// final useCase = GetBusinessTripRatesUseCase(repository);
/// final rates = await useCase();
/// ```
class GetBusinessTripRatesUseCase {
  /// Репозиторий для работы с ставками командировочных.
  final BusinessTripRateRepository _repository;

  /// Конструктор [GetBusinessTripRatesUseCase].
  ///
  /// [_repository] — репозиторий для работы с данными ставок.
  const GetBusinessTripRatesUseCase(this._repository);

  /// Выполняет получение всех ставок командировочных выплат.
  ///
  /// Возвращает список всех ставок, отсортированных по дате создания.
  ///
  /// Может выбросить исключение при ошибке получения данных.
  Future<List<BusinessTripRate>> call() async {
    return await _repository.getAllRates();
  }
}
