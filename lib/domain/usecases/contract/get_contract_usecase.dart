import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/domain/repositories/contract_repository.dart';

/// UseCase для получения договора по идентификатору.
///
/// Используется для поиска договора по id через [ContractRepository].
///
/// Пример использования:
/// ```dart
/// final useCase = GetContractUseCase(contractRepository);
/// final contract = await useCase.execute('contractId');
/// if (contract != null) print(contract.number);
/// ```
///
/// [id] — идентификатор договора.
/// Возвращает [Contract] или null, если не найден.
/// Бросает [Exception] при ошибке.
class GetContractUseCase {
  /// Репозиторий договоров для получения данных.
  final ContractRepository repository;

  /// Создаёт use case с указанным репозиторием.
  GetContractUseCase(this.repository);

  /// Получение договора по id.
  ///
  /// [id] — идентификатор договора.
  /// Возвращает [Contract] или null, если не найден.
  /// Бросает [Exception] при ошибке.
  Future<Contract?> execute(String id) async {
    return repository.getContract(id);
  }
}
