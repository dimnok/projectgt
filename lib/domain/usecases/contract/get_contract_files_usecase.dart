import 'package:projectgt/domain/entities/contract_file.dart';
import 'package:projectgt/domain/repositories/contract_file_repository.dart';

/// Сценарий использования для получения списка файлов конкретного договора.
class GetContractFilesUseCase {
  /// Репозиторий для работы с файлами договоров.
  final ContractFileRepository repository;

  /// Создает экземпляр сценария использования.
  GetContractFilesUseCase(this.repository);

  /// Выполняет получение списка файлов для договора с идентификатором [contractId].
  Future<List<ContractFile>> execute(String contractId) async {
    return repository.getFilesByContract(contractId);
  }
}
