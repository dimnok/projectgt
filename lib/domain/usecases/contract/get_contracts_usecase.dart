import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/domain/repositories/contract_repository.dart';

/// UseCase для получения списка всех договоров.
///
/// Используется для загрузки списка договоров через [ContractRepository].
///
/// Пример использования:
/// ```dart
/// final useCase = GetContractsUseCase(contractRepository);
/// final contracts = await useCase.execute();
/// print(contracts.length);
/// ```
///
/// Возвращает список [Contract].
/// Бросает [Exception] при ошибке.
class GetContractsUseCase {
  /// Репозиторий договоров для получения данных.
  final ContractRepository repository;

  /// Создаёт use case с указанным репозиторием.
  GetContractsUseCase(this.repository);

  /// Получение списка всех договоров.
  ///
  /// Возвращает список [Contract].
  /// Бросает [Exception] при ошибке.
  Future<List<Contract>> execute() async {
    return repository.getContracts();
  }
}
