import 'package:projectgt/domain/repositories/contract_file_repository.dart';

/// Сценарий сохранения пользовательского порядка документов договора.
class ReorderContractFilesUseCase {
  /// Репозиторий файлов договоров.
  final ContractFileRepository repository;

  /// Создаёт сценарий.
  ReorderContractFilesUseCase(this.repository);

  /// Сохраняет порядок [orderedFileIds] для договора [contractId].
  Future<void> execute({
    required String contractId,
    required List<String> orderedFileIds,
  }) {
    return repository.updateFilesDisplayOrder(
      contractId: contractId,
      orderedFileIds: orderedFileIds,
    );
  }
}
