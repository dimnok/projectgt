import 'dart:io';

import 'package:projectgt/features/settlements/data/datasources/settlement_file_data_source.dart';
import 'package:projectgt/features/settlements/domain/entities/settlement_file.dart';
import 'package:projectgt/features/settlements/domain/repositories/settlement_file_repository.dart';

/// Реализация [SettlementFileRepository] через Supabase.
class SettlementFileRepositoryImpl implements SettlementFileRepository {
  /// Источник данных.
  final SettlementFileDataSource dataSource;

  /// Создаёт репозиторий.
  SettlementFileRepositoryImpl(this.dataSource);

  @override
  Future<List<SettlementFile>> getFiles(String settlementOperationId) async {
    final models = await dataSource.getFiles(settlementOperationId);
    return models.map((m) => m.toDomain()).toList();
  }

  @override
  Future<SettlementFile> uploadFile({
    required String settlementOperationId,
    required File file,
    required String fileName,
    String? description,
  }) async {
    final model = await dataSource.uploadFile(
      settlementOperationId: settlementOperationId,
      file: file,
      fileName: fileName,
      description: description,
    );
    return model.toDomain();
  }

  @override
  Future<SettlementFile> uploadFileBytes({
    required String settlementOperationId,
    required List<int> bytes,
    required String fileName,
    String? description,
  }) async {
    final model = await dataSource.uploadFileBytes(
      settlementOperationId: settlementOperationId,
      bytes: bytes,
      fileName: fileName,
      description: description,
    );
    return model.toDomain();
  }

  @override
  Future<void> deleteFile(String fileId, String filePath) async {
    await dataSource.deleteFile(fileId, filePath);
  }

  @override
  Future<void> deleteAllForOperation(String settlementOperationId) async {
    await dataSource.deleteAllForOperation(settlementOperationId);
  }

  @override
  Future<List<int>> downloadFile(String filePath) async {
    return dataSource.downloadFile(filePath);
  }
}
