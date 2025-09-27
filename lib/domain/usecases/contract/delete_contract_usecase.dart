import 'package:projectgt/domain/repositories/contract_repository.dart';

/// UseCase для удаления договора по идентификатору.
///
/// Используется для удаления договора по id через [ContractRepository].
///
/// Пример использования:
/// ```dart
/// final useCase = DeleteContractUseCase(contractRepository);
/// await useCase.execute('contractId');
/// ```
///
/// [id] — идентификатор договора.
/// Возвращает void.
/// Бросает [Exception] при ошибке.
class DeleteContractUseCase {
  /// Репозиторий договоров для удаления данных.
  final ContractRepository repository;

  /// Создаёт use case с указанным репозиторием.
  DeleteContractUseCase(this.repository);

  /// Удаление договора по id.
  ///
  /// [id] — идентификатор договора.
  /// Возвращает void.
  /// Бросает [Exception] при ошибке.
  Future<void> execute(String id) async {
    return repository.deleteContract(id);
  }
}
