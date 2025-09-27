import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/domain/repositories/contract_repository.dart';

/// UseCase для создания нового договора.
///
/// Используется для добавления договора через [ContractRepository].
///
/// Пример использования:
/// ```dart
/// final useCase = CreateContractUseCase(contractRepository);
/// final contract = await useCase.execute(contract);
/// ```
///
/// [contract] — данные договора.
/// Возвращает созданный [Contract].
/// Бросает [Exception] при ошибке.
class CreateContractUseCase {
  /// Репозиторий договоров для создания данных.
  final ContractRepository repository;

  /// Создаёт use case с указанным репозиторием.
  CreateContractUseCase(this.repository);

  /// Создание нового договора.
  ///
  /// [contract] — данные договора.
  /// Возвращает созданный [Contract].
  /// Бросает [Exception] при ошибке.
  Future<Contract> execute(Contract contract) async {
    return repository.createContract(contract);
  }
}
