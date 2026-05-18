import 'package:projectgt/domain/entities/contract_act.dart';
import 'package:projectgt/domain/repositories/contract_act_repository.dart';

/// Загрузка списка актов по договору.
class GetContractActsUseCase {
  /// Репозиторий актов.
  final ContractActRepository _repository;

  /// Создаёт use case.
  GetContractActsUseCase(this._repository);

  /// Возвращает акты для [contractId].
  Future<List<ContractAct>> call(String contractId) {
    return _repository.listByContract(contractId);
  }
}
