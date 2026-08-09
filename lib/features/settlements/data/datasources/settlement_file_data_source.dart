import 'dart:io';

import 'package:projectgt/features/settlements/data/models/settlement_file_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Имя bucket в Supabase Storage для файлов счетов.
const settlementFilesBucket = 'settlement_files';

/// Абстрактный источник данных файлов счетов.
abstract class SettlementFileDataSource {
  /// Список файлов по счёту.
  Future<List<SettlementFileModel>> getFiles(String settlementOperationId);

  /// Загрузить файл.
  Future<SettlementFileModel> uploadFile({
    required String settlementOperationId,
    required File file,
    required String fileName,
    String? description,
  });

  /// Удалить запись и объект в Storage.
  Future<void> deleteFile(String fileId, String filePath);

  /// Удалить все файлы счёта.
  Future<void> deleteAllForOperation(String settlementOperationId);

  /// Скачать байты файла.
  Future<List<int>> downloadFile(String filePath);
}

/// Реализация [SettlementFileDataSource] через Supabase.
class SupabaseSettlementFileDataSource implements SettlementFileDataSource {
  /// Клиент Supabase.
  final SupabaseClient client;

  /// Активная компания.
  final String activeCompanyId;

  /// Создаёт источник данных.
  SupabaseSettlementFileDataSource(this.client, this.activeCompanyId);

  static const _table = 'settlement_files';

  @override
  Future<List<SettlementFileModel>> getFiles(
    String settlementOperationId,
  ) async {
    if (activeCompanyId.isEmpty || settlementOperationId.isEmpty) {
      return [];
    }

    final response = await client
        .from(_table)
        .select()
        .eq('company_id', activeCompanyId)
        .eq('settlement_operation_id', settlementOperationId)
        .order('created_at', ascending: false);

    return (response as List)
        .map(
          (row) => SettlementFileModel.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  @override
  Future<SettlementFileModel> uploadFile({
    required String settlementOperationId,
    required File file,
    required String fileName,
    String? description,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = _buildSafeStorageFileName(fileName);
    final storagePath =
        '$activeCompanyId/$settlementOperationId/${timestamp}_$safeName';

    await client.storage.from(settlementFilesBucket).upload(
          storagePath,
          file,
          fileOptions: FileOptions(
            cacheControl: '3600',
            upsert: false,
            contentType: _contentTypeForFileName(fileName),
          ),
        );

    final userId = client.auth.currentUser?.id;
    final fileData = <String, dynamic>{
      'company_id': activeCompanyId,
      'settlement_operation_id': settlementOperationId,
      'name': fileName,
      'file_path': storagePath,
      'size': await file.length(),
      'type': _contentTypeForFileName(fileName),
      'description': description,
      if (userId != null) 'created_by': userId,
    };

    final response = await client
        .from(_table)
        .insert(fileData)
        .select()
        .single();

    return SettlementFileModel.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  @override
  Future<void> deleteFile(String fileId, String filePath) async {
    await client
        .from(_table)
        .delete()
        .eq('id', fileId)
        .eq('company_id', activeCompanyId);

    await client.storage.from(settlementFilesBucket).remove([filePath]);
  }

  @override
  Future<void> deleteAllForOperation(String settlementOperationId) async {
    if (activeCompanyId.isEmpty || settlementOperationId.isEmpty) return;

    final files = await getFiles(settlementOperationId);
    if (files.isEmpty) return;

    await client
        .from(_table)
        .delete()
        .eq('company_id', activeCompanyId)
        .eq('settlement_operation_id', settlementOperationId);

    final paths = files.map((f) => f.filePath).toList();
    await client.storage.from(settlementFilesBucket).remove(paths);
  }

  @override
  Future<List<int>> downloadFile(String filePath) async {
    return client.storage.from(settlementFilesBucket).download(filePath);
  }

  /// Безопасное имя для пути в Storage (ASCII, без пробелов).
  static String _buildSafeStorageFileName(String fileName) {
    return fileName
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '');
  }

  static String _contentTypeForFileName(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }
}
