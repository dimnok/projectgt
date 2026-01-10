import 'package:projectgt/features/contractors/domain/entities/contractor.dart';
import 'package:projectgt/features/contractors/domain/repositories/contractor_repository.dart';

/// UseCase для получения подрядчика [Contractor] по идентификатору из репозитория.
///
/// Используется для поиска подрядчика по id через [ContractorRepository].
///
/// Пример использования:
/// ```dart
/// final useCase = GetContractorUseCase(contractorRepository);
/// final contractor = await useCase.execute('contractorId');
/// if (contractor != null) print(contractor.fullName);
/// ```
///
/// [id] — идентификатор подрядчика.
/// Возвращает [Contractor] или null, если не найден.
/// Бросает [Exception] при ошибке.
class GetContractorUseCase {
  /// Репозиторий подрядчиков для получения данных.
  final ContractorRepository repository;

  /// Создаёт use case с указанным репозиторием.
  GetContractorUseCase(this.repository);

  /// Получи подрядчика по [id].
  ///
  /// [id] — идентификатор подрядчика.
  /// Возвращает [Contractor] или null, если не найден.
  /// Бросает [Exception] при ошибке.
  Future<Contractor?> execute(String id) async {
    return repository.getContractor(id);
  }
}
