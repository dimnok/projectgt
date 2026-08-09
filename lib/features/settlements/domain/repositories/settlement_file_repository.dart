import 'dart:io';

import 'package:projectgt/features/settlements/domain/entities/settlement_file.dart';

/// Контракт репозитория файлов счетов взаиморасчётов.
abstract class SettlementFileRepository {
  /// Список файлов по счёту.
  Future<List<SettlementFile>> getFiles(String settlementOperationId);

  /// Загрузить файл и сохранить метаданные.
  Future<SettlementFile> uploadFile({
    required String settlementOperationId,
    required File file,
    required String fileName,
    String? description,
  });

  /// Загрузить файл из байтов и сохранить метаданные.
  Future<SettlementFile> uploadFileBytes({
    required String settlementOperationId,
    required List<int> bytes,
    required String fileName,
    String? description,
  });

  /// Удалить файл (метаданные и объект в Storage).
  Future<void> deleteFile(String fileId, String filePath);

  /// Удалить все файлы счёта из Storage и БД.
  Future<void> deleteAllForOperation(String settlementOperationId);

  /// Скачать содержимое файла.
  Future<List<int>> downloadFile(String filePath);
}
