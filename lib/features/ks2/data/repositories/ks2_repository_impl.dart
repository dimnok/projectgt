import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projectgt/core/utils/supabase_function_error.dart';
import 'package:projectgt/features/ks2/domain/repositories/ks2_repository.dart';
import 'package:projectgt/domain/entities/ks2_act.dart';
import 'package:projectgt/data/models/ks2_act_model.dart';

/// Реализация репозитория для работы с актами КС-2 через Supabase.
class Ks2RepositoryImpl implements Ks2Repository {
  static const String _excelBucket = 'ks2_documents';

  final SupabaseClient _supabase;
  final String _activeCompanyId;

  /// Создает экземпляр репозитория.
  Ks2RepositoryImpl(this._supabase, this._activeCompanyId);

  @override
  Future<List<Ks2Act>> getActs(String contractId) async {
    final response = await _supabase
        .from('ks2_acts')
        .select('*, vors(number)')
        .eq('contract_id', contractId)
        .eq('company_id', _activeCompanyId)
        .order('date', ascending: false);

    return (response as List).map((raw) {
      final row = Map<String, dynamic>.from(raw as Map<String, dynamic>);
      final nested = row.remove('vors');
      String? vorNumber;
      if (nested is Map<String, dynamic> && nested['number'] != null) {
        vorNumber = nested['number'].toString();
      }
      final model = Ks2ActModel.fromJson(row);
      return model.toDomain().copyWith(vorNumber: vorNumber);
    }).toList();
  }

  @override
  Future<Ks2PreviewData> previewAct({
    required String contractId,
    required String vorId,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'ks2_operations',
        body: {
          'action': 'preview',
          'contractId': contractId,
          'companyId': _activeCompanyId,
          'vorId': vorId,
        },
      );

      if (response.status != 200) {
        final d = response.data;
        if (d is Map && d['error'] != null) {
          throw Exception(d['error'].toString());
        }
        throw Exception('Не удалось получить превью КС-2: ${response.data}');
      }

      return Ks2PreviewData.fromJson(response.data as Map<String, dynamic>);
    } on FunctionException catch (e) {
      throw Exception(formatFunctionExceptionMessage(e));
    }
  }

  @override
  Future<String> createAct({
    required String contractId,
    required String vorId,
    required String number,
    required DateTime date,
  }) async {
    final response = await _supabase.functions.invoke(
      'ks2_operations',
      body: {
        'action': 'create',
        'contractId': contractId,
        'companyId': _activeCompanyId,
        'vorId': vorId,
        'actNumber': number,
        'actDate': date.toIso8601String(),
      },
    );

    if (response.status != 200) {
      final d = response.data;
      if (d is Map && d['error'] != null) {
        throw Exception(d['error'].toString());
      }
      throw Exception('Не удалось создать КС-2: ${response.data}');
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
  }

  @override
  Future<void> attachActExcelFile({
    required String actId,
    required List<int> bytes,
    required String displayFileName,
  }) async {
    final actRow = await _supabase
        .from('ks2_acts')
        .select('contract_id, excel_path')
        .eq('id', actId)
        .eq('company_id', _activeCompanyId)
        .maybeSingle();

    if (actRow == null) {
      throw Exception('Акт КС-2 не найден');
    }

    final contractId = actRow['contract_id'] as String;
    final previousPath = actRow['excel_path'] as String?;

    final safeName = displayFileName
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '');
    final storagePath =
        '$_activeCompanyId/$contractId/$actId/${DateTime.now().millisecondsSinceEpoch}_$safeName';

    await _supabase.storage.from(_excelBucket).uploadBinary(
          storagePath,
          Uint8List.fromList(bytes),
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: true,
            contentType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        );

    await _supabase
        .from('ks2_acts')
        .update({'excel_path': storagePath})
        .eq('id', actId)
        .eq('company_id', _activeCompanyId);

    if (previousPath != null &&
        previousPath.isNotEmpty &&
        previousPath != storagePath) {
      try {
        await _supabase.storage.from(_excelBucket).remove([previousPath]);
      } catch (_) {
        // Старый файл мог быть удалён вручную — не блокируем сохранение.
      }
    }
  }

  @override
  Future<List<int>> downloadActExcel(String actId) async {
    final actRow = await _supabase
        .from('ks2_acts')
        .select('excel_path')
        .eq('id', actId)
        .eq('company_id', _activeCompanyId)
        .maybeSingle();

    if (actRow == null) {
      throw Exception('Акт КС-2 не найден');
    }
    final path = actRow['excel_path'] as String?;
    if (path == null || path.isEmpty) {
      throw Exception('Файл акта ещё не сохранён');
    }

    return await _supabase.storage.from(_excelBucket).download(path);
  }

  @override
  Future<void> deleteAct(String actId) async {
    final actRow = await _supabase
        .from('ks2_acts')
        .select('excel_path')
        .eq('id', actId)
        .eq('company_id', _activeCompanyId)
        .maybeSingle();

    final excelPath = actRow?['excel_path'] as String?;

    await _supabase
        .from('work_items')
        .update({'ks2_id': null})
        .eq('ks2_id', actId)
        .eq('company_id', _activeCompanyId);

    await _supabase
        .from('ks2_acts')
        .delete()
        .eq('id', actId)
        .eq('company_id', _activeCompanyId);

    if (excelPath != null && excelPath.isNotEmpty) {
      try {
        await _supabase.storage.from(_excelBucket).remove([excelPath]);
      } catch (_) {
        // Игнорируем ошибку удаления файла после удаления записи.
      }
    }
  }
}
