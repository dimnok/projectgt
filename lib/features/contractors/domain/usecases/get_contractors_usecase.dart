import 'package:projectgt/features/contractors/domain/entities/contractor.dart';
import 'package:projectgt/features/contractors/domain/repositories/contractor_repository.dart';

/// UseCase для получения списка всех контрагентов.
///
/// Используется для загрузки списка контрагентов через [ContractorRepository].
///
/// Пример использования:
/// ```dart
/// final useCase = GetContractorsUseCase(contractorRepository);
/// final contractors = await useCase.execute();
/// print(contractors.length);
/// ```
///
/// Возвращает список [Contractor].
/// Бросает [Exception] при ошибке.
class GetContractorsUseCase {
  /// Репозиторий контрагентов для получения данных.
  final ContractorRepository repository;

  /// Создаёт use case с указанным репозиторием.
  GetContractorsUseCase(this.repository);

  /// Получение списка всех контрагентов для указанной компании.
  ///
  /// [companyId] — идентификатор компании.
  /// Возвращает список [Contractor].
  /// Бросает [Exception] при ошибке.
  Future<List<Contractor>> execute(String companyId) async {
    return repository.getContractors(companyId);
  }
}
