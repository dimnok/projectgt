import 'dart:io';
import 'package:projectgt/data/datasources/contract_file_data_source.dart';
import 'package:projectgt/domain/entities/contract_document_status.dart';
import 'package:projectgt/domain/entities/contract_file.dart';
import 'package:projectgt/domain/repositories/contract_file_repository.dart';

/// Реализация репозитория для работы с файлами договоров.
///
/// Обеспечивает связь между доменным слоем и источником данных (Data Source).
class ContractFileRepositoryImpl implements ContractFileRepository {
  /// Источник данных для работы с файлами в БД и хранилище.
  final ContractFileDataSource dataSource;

  /// Создает экземпляр реализации репозитория с заданным [dataSource].
  ContractFileRepositoryImpl(this.dataSource);

  @override
  Future<List<ContractFile>> getFilesByContract(String contractId) async {
    final models = await dataSource.getFilesByContract(contractId);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<ContractFile> uploadFile({
    required String contractId,
    required File file,
    required String fileName,
    String? description,
  }) async {
    final model = await dataSource.uploadFile(
      contractId: contractId,
      file: file,
      fileName: fileName,
      description: description,
    );
    return model.toEntity();
  }

  @override
  Future<void> deleteFile(String fileId, String filePath) async {
    await dataSource.deleteFile(fileId, filePath);
  }

  @override
  Future<ContractFile> updateFileMetadata({
    required String fileId,
    required String name,
    String? description,
    ContractDocumentStatus? documentStatus,
    int? documentVersion,
    bool? isAmendment,
  }) async {
    if (documentVersion != null && documentVersion < 1) {
      throw ArgumentError.value(documentVersion, 'documentVersion', '>= 1');
    }
    final model = await dataSource.updateFileMetadata(
      fileId: fileId,
      name: name,
      description: description,
      documentStatus: documentStatus,
      documentVersion: documentVersion,
      isAmendment: isAmendment,
    );
    return model.toEntity();
  }

  @override
  Future<void> updateFilesDocumentStatus({
    required List<String> fileIds,
    required ContractDocumentStatus status,
  }) async {
    await dataSource.updateDocumentStatusForFileIds(
      fileIds: fileIds,
      status: status,
    );
  }

  @override
  Future<List<int>> downloadFile(String filePath) async {
    return await dataSource.downloadFile(filePath);
  }

  @override
  Future<void> updateFilesDisplayOrder({
    required String contractId,
    required List<String> orderedFileIds,
  }) async {
    final existing = await getFilesByContract(contractId);
    if (existing.isEmpty && orderedFileIds.isEmpty) return;
    if (existing.length != orderedFileIds.length) {
      throw StateError(
        'Сохранение порядка: ожидалось ${existing.length} файлов, передано ${orderedFileIds.length}',
      );
    }
    final idSet = existing.map((e) => e.id).toSet();
    if (orderedFileIds.length != orderedFileIds.toSet().length) {
      throw StateError('Сохранение порядка: повторяющиеся идентификаторы');
    }
    for (final id in orderedFileIds) {
      if (!idSet.contains(id)) {
        throw StateError('Сохранение порядка: неизвестный id $id');
      }
    }
    await dataSource.updateDisplayOrdersForContract(
      contractId: contractId,
      orderedFileIds: orderedFileIds,
    );
  }
}
