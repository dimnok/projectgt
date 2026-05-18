import 'package:projectgt/domain/entities/contract_document_status.dart';
import 'package:projectgt/domain/repositories/contract_file_repository.dart';

/// Массовая смена статуса документооборота для выбранных файлов договора.
class BulkUpdateContractFilesDocumentStatusUseCase {
  /// Репозиторий файлов договоров.
  final ContractFileRepository repository;

  /// Создаёт сценарий.
  BulkUpdateContractFilesDocumentStatusUseCase(this.repository);

  /// Выставляет [status] всем файлам с идентификаторами из [fileIds].
  Future<void> execute({
    required List<String> fileIds,
    required ContractDocumentStatus status,
  }) {
    return repository.updateFilesDocumentStatus(
      fileIds: fileIds,
      status: status,
    );
  }
}
