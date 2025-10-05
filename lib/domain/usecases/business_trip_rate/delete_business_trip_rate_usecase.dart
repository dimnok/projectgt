import 'package:projectgt/domain/repositories/business_trip_rate_repository.dart';

/// UseCase для удаления ставки командировочных выплат.
///
/// Инкапсулирует бизнес-логику удаления ставки с проверками безопасности.
///
/// Пример использования:
/// ```dart
/// final useCase = DeleteBusinessTripRateUseCase(repository);
/// await useCase('rate-id');
/// ```
class DeleteBusinessTripRateUseCase {
  /// Репозиторий для работы с ставками командировочных.
  final BusinessTripRateRepository _repository;

  /// Конструктор [DeleteBusinessTripRateUseCase].
  ///
  /// [_repository] — репозиторий для работы с данными ставок.
  const DeleteBusinessTripRateUseCase(this._repository);

  /// Выполняет удаление ставки командировочных выплат.
  ///
  /// [id] — идентификатор ставки для удаления.
  ///
  /// Может выбросить исключение при:
  /// - Пустом или некорректном ID
  /// - Отсутствии ставки с указанным ID
  /// - Ошибке удаления из БД
  Future<void> call(String id) async {
    if (id.trim().isEmpty) {
      throw ArgumentError('ID ставки не может быть пустым');
    }

    // Проверяем, что ставка существует перед удалением
    final existingRate = await _repository.getRateById(id);
    if (existingRate == null) {
      throw ArgumentError('Ставка с ID $id не найдена');
    }

    await _repository.deleteRate(id);
  }
}
