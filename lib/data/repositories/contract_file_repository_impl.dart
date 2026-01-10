import 'dart:io';
import 'package:projectgt/data/datasources/contract_file_data_source.dart';
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
  }) async {
    final model = await dataSource.uploadFile(
      contractId: contractId,
      file: file,
      fileName: fileName,
    );
    return model.toEntity();
  }

  @override
  Future<void> deleteFile(String fileId, String filePath) async {
    await dataSource.deleteFile(fileId, filePath);
  }

  @override
  Future<String> getDownloadUrl(String filePath, String originalName) async {
    return await dataSource.getDownloadUrl(filePath, originalName);
  }

  @override
  Future<List<int>> downloadFile(String filePath) async {
    return await dataSource.downloadFile(filePath);
  }
}
