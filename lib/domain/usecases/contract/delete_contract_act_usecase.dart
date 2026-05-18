import 'package:projectgt/domain/repositories/contract_act_repository.dart';

/// Удаление акта по договору.
class DeleteContractActUseCase {
  /// Репозиторий актов.
  final ContractActRepository _repository;

  /// Создаёт use case.
  DeleteContractActUseCase(this._repository);

  /// Удаляет строку акта.
  Future<void> call({
    required String id,
    required String companyId,
    required String contractId,
  }) {
    return _repository.delete(
      id: id,
      companyId: companyId,
      contractId: contractId,
    );
  }
}
