import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:share_plus/share_plus.dart';

import '../../../../domain/entities/estimate_bulk_update.dart';

/// Excel-сервис для безопасного массового обновления строк сметы.
class EstimateBulkUpdateExcelService {
  EstimateBulkUpdateExcelService._();

  /// Название листа в Excel-файле.
  static const String sheetName = 'Обновление сметы';

  /// Обязательная шапка файла.
  static const List<String> requiredColumns = [
    'ID строки',
    'ID позиции',
    'updated_at',
    'Система',
    'Подсистема',
    '№',
    'Наименование',
    'Артикул',
    'Производитель',
    'Ед. изм.',
    'Кол-во',
    'Цена',
    'Сумма',
  ];

  /// Проверяет структуру файла обновления.
  static List<String> validate(Uint8List bytes) {
    final errors = <String>[];
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) {
      return ['Файл не содержит листов'];
    }

    final sheet = excel.tables[excel.tables.keys.first];
    if (sheet == null || sheet.rows.isEmpty) {
      return ['Лист не содержит строк'];
    }

    final headers = sheet.rows.first;
    for (var i = 0; i < requiredColumns.length; i++) {
      final actual = i < headers.length ? _cellAsString(headers, i) : '';
      if (actual != requiredColumns[i]) {
        errors.add(
          'Ожидалась колонка "${requiredColumns[i]}" в позиции ${i + 1}',
        );
      }
    }
    return errors;
  }

  /// Преобразует Excel-файл в строки для preview/apply.
  static List<EstimateBulkUpdateImportRow> parseRows(Uint8List bytes) {
    final errors = validate(bytes);
    if (errors.isNotEmpty) {
      throw Exception(errors.join('\n'));
    }

    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables[excel.tables.keys.first];
    if (sheet == null || sheet.rows.length <= 1) {
      return const [];
    }

    final result = <EstimateBulkUpdateImportRow>[];
    final rows = sheet.rows.skip(1).toList();
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < requiredColumns.length) continue;

      final name = _cellAsString(row, 6);
      final unit = _cellAsString(row, 9);
      if (name.isEmpty && unit.isEmpty) continue;

      result.add(
        EstimateBulkUpdateImportRow(
          rowNo: i + 2,
          id: _normalizeNullable(_cellAsString(row, 0)),
          positionId: _normalizeNullable(_cellAsString(row, 1)),
          updatedAt: _parseDateTime(_cellAsString(row, 2)),
          system: _cellAsString(row, 3),
          subsystem: _cellAsString(row, 4),
          number: _cellAsString(row, 5),
          name: name,
          article: _cellAsString(row, 7),
          manufacturer: _cellAsString(row, 8),
          unit: unit,
          quantity: _cellAsDouble(row, 10),
          price: _cellAsDouble(row, 11),
        ),
      );
    }
    return result;
  }

  /// Сохраняет xlsx на устройство.
  static Future<String?> saveToDevice(
    Uint8List bytes, {
    required String fileName,
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
      final outputFile = await FilePicker.saveFile(
        dialogTitle: 'Сохранение Excel для обновления сметы',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
      );
      if (outputFile == null) return null;
      await File(outputFile).writeAsBytes(bytes);
      return outputFile;
    }

    final directory = await path_provider.getTemporaryDirectory();
    final filePath = '${directory.path}/$fileName';
    await File(filePath).writeAsBytes(bytes);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath)],
        text: 'Excel для обновления сметы: $fileName',
      ),
    );
    return filePath;
  }

  static String _cellAsString(List<Data?> row, int index) {
    if (index < 0 || index >= row.length || row[index]?.value == null) {
      return '';
    }

    final value = row[index]!.value;
    if (value is DoubleCellValue) {
      final number = value.value;
      return number == number.truncate()
          ? number.toInt().toString()
          : number.toString();
    }
    if (value is IntCellValue) {
      return value.value.toString();
    }

    return value.toString().trim();
  }

  static double _cellAsDouble(List<Data?> row, int index) {
    if (index < 0 || index >= row.length || row[index]?.value == null) {
      return 0;
    }

    final value = row[index]!.value;
    if (value is DoubleCellValue) return value.value;
    if (value is IntCellValue) return value.value.toDouble();

    return double.tryParse(
          value.toString().trim().replaceAll(' ', '').replaceAll(',', '.'),
        ) ??
        0;
  }

  static DateTime? _parseDateTime(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return null;
    return DateTime.tryParse(normalized);
  }

  static String? _normalizeNullable(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }
}
