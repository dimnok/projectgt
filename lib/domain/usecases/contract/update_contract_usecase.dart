import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/domain/repositories/contract_repository.dart';

/// UseCase для обновления данных договора.
///
/// Используется для обновления информации о договоре через [ContractRepository].
///
/// Пример использования:
/// ```dart
/// final useCase = UpdateContractUseCase(contractRepository);
/// final updated = await useCase.execute(contract.copyWith(number: 'NEW-2024'));
/// ```
///
/// [contract] — обновлённые данные договора.
/// Возвращает обновлённый [Contract].
/// Бросает [Exception] при ошибке.
class UpdateContractUseCase {
  /// Репозиторий договоров для обновления данных.
  final ContractRepository repository;

  /// Создаёт use case с указанным репозиторием.
  UpdateContractUseCase(this.repository);

  /// Обновление договора.
  ///
  /// [contract] — обновлённые данные договора.
  /// Возвращает обновлённый [Contract].
  /// Бросает [Exception] при ошибке.
  Future<Contract> execute(Contract contract) async {
    return repository.updateContract(contract);
  }
}
