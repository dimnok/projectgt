import 'dart:io';
import 'package:projectgt/domain/entities/contract_file.dart';
import 'package:projectgt/domain/repositories/contract_file_repository.dart';

/// Сценарий использования для загрузки файла и прикрепления его к договору.
class UploadContractFileUseCase {
  /// Репозиторий для работы с файлами договоров.
  final ContractFileRepository repository;

  /// Создает экземпляр сценария использования.
  UploadContractFileUseCase(this.repository);

  /// Выполняет загрузку файла [file] с именем [fileName] для договора [contractId].
  Future<ContractFile> execute({
    required String contractId,
    required File file,
    required String fileName,
  }) async {
    return repository.uploadFile(
      contractId: contractId,
      file: file,
      fileName: fileName,
    );
  }
}
