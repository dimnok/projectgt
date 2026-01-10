import 'package:projectgt/domain/repositories/contract_file_repository.dart';

/// Сценарий использования для удаления файла договора.
class DeleteContractFileUseCase {
  /// Репозиторий для работы с файлами договоров.
  final ContractFileRepository repository;

  /// Создает экземпляр сценария использования.
  DeleteContractFileUseCase(this.repository);

  /// Выполняет удаление файла по его [fileId] (ID в БД) и [filePath] (путь в хранилище).
  Future<void> execute(String fileId, String filePath) async {
    return repository.deleteFile(fileId, filePath);
  }
}
