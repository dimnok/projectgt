import 'package:projectgt/domain/entities/contract.dart';

/// Абстракция репозитория для работы с договорами (контрактами).
///
/// Определяет методы для получения, создания, обновления и удаления договоров.
/// Используется в слое домена для инкапсуляции бизнес-логики работы с контрактами.
///
/// Пример использования:
/// ```dart
/// final contracts = await contractRepository.getContracts();
/// ```
abstract class ContractRepository {
  /// Получает список всех договоров.
  ///
  /// Возвращает список [Contract].
  /// Бросает исключение при ошибке.
  Future<List<Contract>> getContracts();

  /// Получает договор по идентификатору [id].
  ///
  /// [id] — идентификатор договора.
  /// Возвращает [Contract], если найден, иначе — null.
  Future<Contract?> getContract(String id);

  /// Создаёт новый договор.
  ///
  /// [contract] — данные нового договора.
  /// Возвращает созданный [Contract].
  Future<Contract> createContract(Contract contract);

  /// Обновляет существующий договор.
  ///
  /// [contract] — обновлённые данные договора.
  /// Возвращает обновлённый [Contract].
  Future<Contract> updateContract(Contract contract);

  /// Удаляет договор по идентификатору [id].
  ///
  /// [id] — идентификатор договора.
  /// После удаления договор становится недоступен.
  Future<void> deleteContract(String id);
}
