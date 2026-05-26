import 'dart:typed_data';

import 'package:projectgt/core/utils/supabase_function_error.dart';
import 'package:projectgt/domain/entities/contract_act_ks2_preview.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Вызовы Edge Function `ks2_operations` и Storage для актов КС-2.
class ContractActKs2RemoteDataSource {
  static const String _excelBucket = 'ks2_documents';

  /// Создаёт источник.
  const ContractActKs2RemoteDataSource(this._client, this._activeCompanyId);

  final SupabaseClient _client;
  final String _activeCompanyId;

  /// Предпросмотр сохранённых строк акта.
  Future<ContractActKs2Preview> previewByAct({
    required String contractId,
    required String actId,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'ks2_operations',
        body: {
          'action': 'preview',
          'contractId': contractId,
          'companyId': _activeCompanyId,
          'actId': actId,
        },
      );

      if (response.status != 200) {
        throw _responseError(response.data, 'Не удалось загрузить строки акта');
      }

      return ContractActKs2Preview.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on FunctionException catch (e) {
      throw Exception(formatFunctionExceptionMessage(e));
    }
  }

  /// Предпросмотр состава акта по ВОР.
  Future<ContractActKs2Preview> preview({
    required String contractId,
    required String vorId,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'ks2_operations',
        body: {
          'action': 'preview',
          'contractId': contractId,
          'companyId': _activeCompanyId,
          'vorId': vorId,
        },
      );

      if (response.status != 200) {
        throw _responseError(response.data, 'Не удалось получить превью КС-2');
      }

      return ContractActKs2Preview.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on FunctionException catch (e) {
      throw Exception(formatFunctionExceptionMessage(e));
    }
  }

  /// Создаёт акт КС-2 в `contract_acts`.
  Future<String> createAct({
    required String contractId,
    required String vorId,
    required String number,
    required DateTime actDate,
    required DateTime periodFrom,
    required DateTime periodTo,
    double advanceRetention = 0,
    double warrantyRetention = 0,
    double otherRetentions = 0,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'ks2_operations',
        body: {
          'action': 'create',
          'contractId': contractId,
          'companyId': _activeCompanyId,
          'vorId': vorId,
          'actNumber': number,
          'actDate': actDate.toIso8601String(),
          'periodFrom': _dateOnly(periodFrom),
          'periodTo': _dateOnly(periodTo),
          'advanceRetention': advanceRetention,
          'warrantyRetention': warrantyRetention,
          'otherRetentions': otherRetentions,
        },
      );

      if (response.status != 200) {
        throw _responseError(response.data, 'Не удалось создать КС-2');
      }

      final data = response.data;
      if (data is! Map) {
        throw Exception('Некорректный ответ при создании акта КС-2');
      }
      final actId = data['actId']?.toString();
      if (actId == null || actId.isEmpty) {
        throw Exception('Сервер не вернул идентификатор акта');
      }
      return actId;
    } on FunctionException catch (e) {
      throw Exception(formatFunctionExceptionMessage(e));
    }
  }

  /// Загружает Excel и возвращает путь в Storage.
  Future<String> uploadExcel({
    required String actId,
    required String contractId,
    required List<int> bytes,
    required String displayFileName,
  }) async {
    final safeName = displayFileName
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '');
    final storagePath =
        '$_activeCompanyId/$contractId/$actId/${DateTime.now().millisecondsSinceEpoch}_$safeName';

    await _client.storage.from(_excelBucket).uploadBinary(
          storagePath,
          Uint8List.fromList(bytes),
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: true,
            contentType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        );

    return storagePath;
  }

  /// Скачивает файл по пути в bucket.
  Future<List<int>> downloadExcel(String storagePath) async {
    return _client.storage.from(_excelBucket).download(storagePath);
  }

  /// Удаляет файл из Storage (ошибки игнорируются).
  Future<void> removeExcelIfExists(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      await _client.storage.from(_excelBucket).remove([path]);
    } catch (_) {
      // Файл мог быть удалён вручную.
    }
  }

  static String _dateOnly(DateTime d) {
    final local = d.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Exception _responseError(Object? data, String fallback) {
    if (data is Map && data['error'] != null) {
      return Exception(data['error'].toString());
    }
    return Exception('$fallback: $data');
  }
}
