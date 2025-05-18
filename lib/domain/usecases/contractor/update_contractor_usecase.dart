import 'package:projectgt/domain/entities/contractor.dart';
import 'package:projectgt/domain/repositories/contractor_repository.dart';

/// UseCase для обновления данных контрагента.
///
/// Используется для обновления информации о контрагенте через [ContractorRepository].
///
/// Пример использования:
/// ```dart
/// final useCase = UpdateContractorUseCase(contractorRepository);
/// final updated = await useCase.execute(contractor.copyWith(fullName: 'НовоеИмя'));
/// ```
///
/// [contractor] — обновлённые данные контрагента.
/// Возвращает обновлённого [Contractor].
/// Бросает [Exception] при ошибке.
class UpdateContractorUseCase {
  /// Репозиторий контрагентов для обновления данных.
  final ContractorRepository repository;

  /// Создаёт use case с указанным репозиторием.
  UpdateContractorUseCase(this.repository);

  /// Обновление контрагента.
  ///
  /// [contractor] — обновлённые данные контрагента.
  /// Возвращает обновлённого [Contractor].
  /// Бросает [Exception] при ошибке.
  Future<Contractor> execute(Contractor contractor) async {
    return repository.updateContractor(contractor);
  }
} 