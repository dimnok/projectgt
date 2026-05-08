import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:projectgt/core/utils/formatters.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Экспорт Excel для заполнения **расценок подрядчика** (серверная генерация, Edge Function).
///
/// [columnHeaders] и имя листа совпадают с ответом `export-subcontractor-rates` (импорт позже).
class SubcontractorRatesExcelExportService {
  SubcontractorRatesExcelExportService._();

  /// Лист в файле с сервера (`export-subcontractor-rates`).
  static const String sheetName = 'Расценки суба';

  /// Соответствует шапке и колонкам в Edge Function; на листе есть строки-группы по смете.
  static const List<String> columnHeaders = [
    'ID позиции',
    '№',
    'Наименование',
    'Артикул',
    'Производитель',
    'Ед. изм.',
    'Кол-во',
    'Цена',
    'Сумма',
    'Кол-во суб',
    'Цена суб',
    'Сумма суб',
  ];

  /// Запрашивает xlsx у Edge Function [exportSubcontractorRatesFunctionName] и сохраняет/отправляет на устройство.
  static Future<String?> requestServerExportAndSaveToDevice(
    SupabaseClient client, {
    required String companyId,
    required String contractId,
    required String objectId,
    String? contractorId,
    List<String> estimateIds = const <String>[],
  }) async {
    final response = await client.functions.invoke(
      'export-subcontractor-rates',
      body: {
        'companyId': companyId,
        'contractId': contractId,
        'objectId': objectId,
        if (contractorId != null && contractorId.isNotEmpty)
          'contractorId': contractorId,
        if (estimateIds.isNotEmpty) 'estimateIds': estimateIds,
      },
      headers: {
        'Authorization':
            'Bearer ${client.auth.currentSession?.accessToken ?? ''}',
        'Content-Type': 'application/json',
      },
    );

    final data = response.data;
    if (data is! Map) {
      throw Exception('Некорректный ответ сервера');
    }
    final err = data['error'];
    if (err != null) {
      throw Exception(err.toString());
    }
    final base64File = data['file'] as String?;
    if (base64File == null || base64File.isEmpty) {
      throw Exception('Ответ не содержит файл');
    }
    final filename =
        data['filename'] as String? ??
        buildFileName(contractNumberLabel: 'договор');
    final fileBytes = base64Decode(base64File);
    return saveToDevice(
      Uint8List.fromList(fileBytes),
      fileName: filename,
      dialogTitle: 'Сохранение Excel для расценок',
      shareText: 'Расценки подрядчика: $filename',
    );
  }

  /// Запрашивает xlsx выполнения подрядчика и сохраняет/отправляет на устройство.
  static Future<String?> requestServerExecutionExportAndSaveToDevice(
    SupabaseClient client, {
    required String companyId,
    required String contractId,
    required String objectId,
    required String contractorId,
    List<String> estimateIds = const <String>[],
  }) async {
    final response = await client.functions.invoke(
      'export-subcontractor-rates',
      body: {
        'exportMode': 'execution',
        'companyId': companyId,
        'contractId': contractId,
        'objectId': objectId,
        'contractorId': contractorId,
        if (estimateIds.isNotEmpty) 'estimateIds': estimateIds,
      },
      headers: {
        'Authorization':
            'Bearer ${client.auth.currentSession?.accessToken ?? ''}',
        'Content-Type': 'application/json',
      },
    );

    final data = response.data;
    if (data is! Map) {
      throw Exception('Некорректный ответ сервера');
    }
    final err = data['error'];
    if (err != null) {
      throw Exception(err.toString());
    }
    final base64File = data['file'] as String?;
    if (base64File == null || base64File.isEmpty) {
      throw Exception('Ответ не содержит файл');
    }
    final filename =
        data['filename'] as String? ??
        buildExecutionFileName(contractNumberLabel: 'договор');
    final fileBytes = base64Decode(base64File);
    return saveToDevice(
      Uint8List.fromList(fileBytes),
      fileName: filename,
      dialogTitle: 'Сохранение Excel выполнения',
      shareText: 'Выполнение подрядчика: $filename',
    );
  }

  /// Сохранение уже готовых байт (тот же сценарий, что и для других xlsx-экспортов).
  static Future<String?> saveToDevice(
    Uint8List bytes, {
    required String fileName,
    String dialogTitle = 'Сохранение Excel',
    String? shareText,
  }) async {
    if (kIsWeb) {
      return FileSaver.instance.saveFile(
        name: fileName.replaceAll('.xlsx', ''),
        bytes: bytes,
        ext: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );
    }

    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      final outputFile = await FilePicker.platform.saveFile(
        dialogTitle: dialogTitle,
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
      );
      if (outputFile == null) return null;
      final file = File(outputFile);
      await file.writeAsBytes(bytes);
      return outputFile;
    }

    final directory = await path_provider.getTemporaryDirectory();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(files: [XFile(filePath)], text: shareText ?? fileName),
    );
    return filePath;
  }

  /// Локальное имя файла, если сервер не вернул [filename].
  static String buildFileName({required String contractNumberLabel}) {
    final safe = contractNumberLabel
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    final basis = safe.isEmpty ? 'договор' : safe;
    return 'Расценки_суба_${basis}_${formatRuDate(DateTime.now())}.xlsx';
  }

  /// Локальное имя файла выполнения, если сервер не вернул [filename].
  static String buildExecutionFileName({required String contractNumberLabel}) {
    final safe = contractNumberLabel
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    final basis = safe.isEmpty ? 'договор' : safe;
    return 'Выполнение_суба_${basis}_${formatRuDate(DateTime.now())}.xlsx';
  }
}
