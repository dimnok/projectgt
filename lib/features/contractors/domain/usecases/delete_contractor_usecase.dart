import 'package:projectgt/features/contractors/domain/repositories/contractor_repository.dart';

/// UseCase для удаления контрагента по идентификатору.
///
/// Используется для удаления контрагента по id через [ContractorRepository].
///
/// Пример использования:
/// ```dart
/// final useCase = DeleteContractorUseCase(contractorRepository);
/// await useCase.execute('contractorId');
/// ```
///
/// [id] — идентификатор контрагента.
/// Возвращает void.
/// Бросает [Exception] при ошибке.
class DeleteContractorUseCase {
  /// Репозиторий контрагентов для удаления данных.
  final ContractorRepository repository;

  /// Создаёт use case с указанным репозиторием.
  DeleteContractorUseCase(this.repository);

  /// Удаление контрагента по id.
  ///
  /// [id] — идентификатор контрагента.
  /// Возвращает void.
  /// Бросает [Exception] при ошибке.
  Future<void> execute(String id) async {
    return repository.deleteContractor(id);
  }
}
