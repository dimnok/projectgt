import 'package:projectgt/domain/entities/contractor.dart';
import 'package:projectgt/domain/repositories/contractor_repository.dart';

/// UseCase для создания нового контрагента.
///
/// Используется для добавления контрагента через [ContractorRepository].
///
/// Пример использования:
/// ```dart
/// final useCase = CreateContractorUseCase(contractorRepository);
/// final contractor = await useCase.execute(contractor);
/// ```
///
/// [contractor] — данные контрагента.
/// Возвращает созданного [Contractor].
/// Бросает [Exception] при ошибке.
class CreateContractorUseCase {
  /// Репозиторий контрагентов для создания данных.
  final ContractorRepository repository;

  /// Создаёт use case с указанным репозиторием.
  CreateContractorUseCase(this.repository);

  /// Создание нового контрагента.
  ///
  /// [contractor] — данные контрагента.
  /// Возвращает созданного [Contractor].
  /// Бросает [Exception] при ошибке.
  Future<Contractor> execute(Contractor contractor) async {
    return repository.createContractor(contractor);
  }
}
