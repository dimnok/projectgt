import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:projectgt/core/utils/formatters.dart';

/// Сервис серверной генерации Excel со списком сотрудников.
///
/// Вызывает Edge Function [export-employees], получает XLSX в base64 и сохраняет
/// файл с учётом платформы (веб, десктоп, мобильные ОС).
class EmployeeServerExcelExportService {
  /// Клиент Supabase для вызова Edge Function.
  final SupabaseClient client;

  /// Создаёт [EmployeeServerExcelExportService].
  EmployeeServerExcelExportService({required this.client});

  /// Формирует файл на сервере и сохраняет его локально.
  ///
  /// [companyId] — активная компания.
  /// [statusFilter] — значение [EmployeeStatus.name] или `null`, если выбраны все статусы.
  /// [objectFilter] — JSON фильтра по объектам (поле `toExportFilterJson` тулбара таблицы).
  /// [searchQuery] — тот же запрос, что в [EmployeeState.searchQuery].
  ///
  /// Возвращает путь к файлу или `null`, если пользователь отменил сохранение (десктоп).
  Future<String?> exportEmployees({
    required String companyId,
    required Map<String, dynamic> objectFilter,
    String? statusFilter,
    String searchQuery = '',
  }) async {
    final response = await client.functions.invoke(
      'export-employees',
      body: <String, dynamic>{
        'companyId': companyId,
        'status': statusFilter,
        'objectFilter': objectFilter,
        'searchQuery': searchQuery,
      },
      headers: <String, String>{
        'Authorization':
            'Bearer ${client.auth.currentSession?.accessToken ?? ''}',
        'Content-Type': 'application/json',
      },
    );

    final data = _parseResponse(response);
    final success = data['success'] as bool? ?? false;

    if (!success) {
      throw Exception(
        data['message']?.toString() ?? 'Не удалось сформировать Excel-файл',
      );
    }

    final base64File = data['base64']?.toString();
    if (base64File == null || base64File.isEmpty) {
      throw Exception('Сервер не вернул содержимое Excel-файла');
    }

    final filename =
        data['filename']?.toString() ??
        'Сотрудники_${formatRuDate(DateTime.now())}.xlsx';

    return _saveExcelFile(base64File, filename);
  }

  Map<String, dynamic> _parseResponse(dynamic response) {
    dynamic rawData;

    if (response is Map<String, dynamic>) {
      rawData = response;
    } else {
      try {
        rawData = response.data;
      } catch (_) {
        rawData = response;
      }
    }

    if (rawData is Map<String, dynamic>) {
      return rawData;
    }

    if (rawData is Map) {
      return Map<String, dynamic>.from(rawData);
    }

    if (rawData is String) {
      return jsonDecode(rawData) as Map<String, dynamic>;
    }

    throw Exception('Неизвестный формат ответа сервера');
  }

  Future<String?> _saveExcelFile(String base64, String filename) async {
    final fileBytes = base64Decode(base64);

    if (kIsWeb) {
      return FileSaver.instance.saveFile(
        name: filename.replaceAll('.xlsx', ''),
        bytes: Uint8List.fromList(fileBytes),
        ext: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );
    }

    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      final outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Выберите место для сохранения Excel файла',
        fileName: filename,
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
      );

      if (outputFile == null) {
        return null;
      }

      final file = File(outputFile);
      await file.writeAsBytes(fileBytes);
      return outputFile;
    }

    final directory = await path_provider.getTemporaryDirectory();
    final filePath = '${directory.path}/$filename';
    final file = File(filePath);
    await file.writeAsBytes(fileBytes);

    await SharePlus.instance.share(
      ShareParams(files: [XFile(filePath)], text: 'Сотрудники: $filename'),
    );

    return filePath;
  }
}
