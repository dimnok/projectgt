import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:projectgt/core/utils/formatters.dart';

/// Сервис серверной генерации Excel-файла табеля.
///
/// Вызывает Supabase Edge Function, получает готовый XLSX в base64 и
/// сохраняет файл на устройство пользователя с учётом платформы.
class TimesheetExcelExportService {
  /// Клиент Supabase для вызова Edge Function.
  final SupabaseClient client;

  /// Создает экземпляр [TimesheetExcelExportService].
  TimesheetExcelExportService({required this.client});

  /// Генерирует и сохраняет Excel-файл табеля на стороне сервера.
  ///
  /// Возвращает путь к сохранённому файлу или `null`, если пользователь
  /// отменил выбор пути сохранения.
  Future<String?> exportToExcel({
    required String companyId,
    required DateTime startDate,
    required DateTime endDate,
    List<String>? objectIds,
    List<String>? positions,
  }) async {
    final response = await client.functions.invoke(
      'export-timesheet',
      body: {
        'companyId': companyId,
        'startDate': GtFormatters.formatDateForApi(startDate),
        'endDate': GtFormatters.formatDateForApi(endDate),
        'objectIds': objectIds,
        'positions': positions,
      },
      headers: {
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
        'Табель_${formatRuDate(startDate)}_${formatRuDate(endDate)}.xlsx';

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
      ShareParams(files: [XFile(filePath)], text: 'Табель: $filename'),
    );

    return filePath;
  }
}
