import 'package:projectgt/domain/entities/contract_document_status.dart';
import 'package:projectgt/domain/entities/contract_file.dart';
import 'package:projectgt/domain/repositories/contract_file_repository.dart';

/// Сценарий обновления отображаемого имени, примечания и полей документооборота.
class UpdateContractFileMetadataUseCase {
  /// Репозиторий файлов договоров.
  final ContractFileRepository repository;

  /// Создаёт сценарий.
  UpdateContractFileMetadataUseCase(this.repository);

  /// Обновляет метаданные записи [fileId].
  ///
  /// Поля [documentStatus], [documentVersion] и [isAmendment], если `null`, в БД не передаются.
  Future<ContractFile> execute({
    required String fileId,
    required String name,
    String? description,
    ContractDocumentStatus? documentStatus,
    int? documentVersion,
    bool? isAmendment,
  }) {
    return repository.updateFileMetadata(
      fileId: fileId,
      name: name,
      description: description,
      documentStatus: documentStatus,
      documentVersion: documentVersion,
      isAmendment: isAmendment,
    );
  }
}
