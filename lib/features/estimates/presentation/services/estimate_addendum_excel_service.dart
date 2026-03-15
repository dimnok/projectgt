import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../../../../domain/entities/estimate_revision.dart';

/// Результат валидации Excel-файла LC / ДС.
class EstimateAddendumExcelValidationResult {
  /// Валиден ли файл.
  final bool isValid;

  /// Ошибки структуры.
  final List<String> errors;

  /// Предупреждения без блокировки импорта.
  final List<String> warnings;

  /// Создаёт результат валидации.
  const EstimateAddendumExcelValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });
}

/// Результат предпросмотра Excel-файла LC / ДС.
class EstimateAddendumExcelPreviewResult {
  /// Строки для короткого предпросмотра.
  final List<List<Data?>> rows;

  /// Количество строк данных.
  final int rowCount;

  /// Количество строк с заполненным идентификатором позиции.
  final int existingRowsCount;

  /// Количество новых строк без идентификатора позиции.
  final int newRowsCount;

  /// Общая сумма по файлу.
  final double totalAmount;

  /// Создаёт результат предпросмотра.
  const EstimateAddendumExcelPreviewResult({
    required this.rows,
    required this.rowCount,
    required this.existingRowsCount,
    required this.newRowsCount,
    required this.totalAmount,
  });
}

/// Сервис Excel для параллельного потока LC / ДС.
///
/// Старый импорт сметы продолжает жить отдельно, чтобы не ломать текущий flow.
class EstimateAddendumExcelService {
  /// Обязательные колонки шаблона LC / ДС.
  static const List<String> requiredColumns = [
    'ID позиции',
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

  /// Генерирует Excel-шаблон LC / ДС из текущих строк сметы.
  static Uint8List generateTemplate(List<EstimateAddendumTemplateRow> rows) {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != 'LC') {
      excel.delete(defaultSheet);
    }

    final sheet = excel['LC'];
    sheet.appendRow(requiredColumns.map(TextCellValue.new).toList());

    for (final row in rows) {
      sheet.appendRow([
        TextCellValue(row.positionId),
        TextCellValue(row.system),
        TextCellValue(row.subsystem),
        TextCellValue(row.number),
        TextCellValue(row.name),
        TextCellValue(row.article),
        TextCellValue(row.manufacturer),
        TextCellValue(row.unit),
        DoubleCellValue(row.quantity),
        DoubleCellValue(row.price),
        DoubleCellValue(row.total),
      ]);
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('Не удалось сформировать Excel-файл LC / ДС');
    }

    return Uint8List.fromList(bytes);
  }

  /// Проверяет структуру Excel-файла LC / ДС.
  static EstimateAddendumExcelValidationResult validateExcelFile(
    Uint8List bytes,
  ) {
    final errors = <String>[];
    final warnings = <String>[];

    try {
      final excel = Excel.decodeBytes(bytes);
      if (excel.tables.isEmpty) {
        return const EstimateAddendumExcelValidationResult(
          isValid: false,
          errors: ['Файл не содержит листов'],
        );
      }

      final sheet = excel.tables[excel.tables.keys.first];
      if (sheet == null || sheet.rows.isEmpty) {
        return const EstimateAddendumExcelValidationResult(
          isValid: false,
          errors: ['Лист не содержит строк'],
        );
      }

      final headers = sheet.rows.first;
      if (headers.length < requiredColumns.length) {
        errors.add(
          'В заголовке недостаточно колонок. Ожидалось: ${requiredColumns.length}, найдено: ${headers.length}',
        );
      }

      for (var i = 0; i < requiredColumns.length; i++) {
        final actual = i < headers.length
            ? headers[i]?.value?.toString().trim()
            : null;
        if (actual != requiredColumns[i]) {
          errors.add(
            'Ожидалась колонка "${requiredColumns[i]}" в позиции ${i + 1}',
          );
        }
      }

      if (errors.isNotEmpty) {
        return EstimateAddendumExcelValidationResult(
          isValid: false,
          errors: errors,
          warnings: warnings,
        );
      }

      final dataRows = sheet.rows.skip(1).toList();
      if (dataRows.isEmpty) {
        warnings.add('Файл не содержит строк данных');
      }

      for (var index = 0; index < dataRows.length; index++) {
        final row = dataRows[index];
        final rowNo = index + 2;

        if (row.length < requiredColumns.length) {
          warnings.add('Строка $rowNo содержит меньше колонок, чем требуется');
          continue;
        }

        if (_cellAsString(row, 4).isEmpty) {
          warnings.add('Строка $rowNo: не заполнено наименование');
        }
        if (_cellAsString(row, 7).isEmpty) {
          warnings.add('Строка $rowNo: не заполнена единица измерения');
        }
      }

      return EstimateAddendumExcelValidationResult(
        isValid: true,
        errors: errors,
        warnings: warnings,
      );
    } catch (error) {
      return EstimateAddendumExcelValidationResult(
        isValid: false,
        errors: ['Ошибка при обработке файла: $error'],
      );
    }
  }

  /// Готовит короткий предпросмотр файла LC / ДС.
  static EstimateAddendumExcelPreviewResult preparePreview(Uint8List bytes) {
    try {
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables[excel.tables.keys.first];
      if (sheet == null || sheet.rows.isEmpty) {
        return const EstimateAddendumExcelPreviewResult(
          rows: [],
          rowCount: 0,
          existingRowsCount: 0,
          newRowsCount: 0,
          totalAmount: 0,
        );
      }

      final rows = sheet.rows;
      final previewRows = rows.length > 10 ? rows.sublist(0, 10) : rows;
      var existingRowsCount = 0;
      var newRowsCount = 0;
      var totalAmount = 0.0;

      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        final positionId = _cellAsString(row, 0);
        if (positionId.isEmpty) {
          newRowsCount++;
        } else {
          existingRowsCount++;
        }
        totalAmount += _cellAsDouble(row, 10);
      }

      return EstimateAddendumExcelPreviewResult(
        rows: previewRows,
        rowCount: rows.length - 1,
        existingRowsCount: existingRowsCount,
        newRowsCount: newRowsCount,
        totalAmount: totalAmount,
      );
    } catch (_) {
      return const EstimateAddendumExcelPreviewResult(
        rows: [],
        rowCount: 0,
        existingRowsCount: 0,
        newRowsCount: 0,
        totalAmount: 0,
      );
    }
  }

  /// Преобразует Excel-файл LC / ДС в список строк для сохранения.
  static List<EstimateAddendumImportRow> parseImportRows(Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables[excel.tables.keys.first];
    if (sheet == null || sheet.rows.length <= 1) {
      return const [];
    }

    final result = <EstimateAddendumImportRow>[];
    final rows = sheet.rows.skip(1).toList();

    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < requiredColumns.length) continue;

      final name = _cellAsString(row, 4);
      final unit = _cellAsString(row, 7);
      if (name.isEmpty || unit.isEmpty) continue;

      final quantity = _cellAsDouble(row, 8);
      final price = _cellAsDouble(row, 9);
      final rawTotal = _cellAsDouble(row, 10);
      final total = rawTotal == 0 ? quantity * price : rawTotal;

      result.add(
        EstimateAddendumImportRow(
          positionId: _normalizeNullable(_cellAsString(row, 0)),
          rowNo: i + 1,
          system: _cellAsString(row, 1),
          subsystem: _cellAsString(row, 2),
          number: _cellAsString(row, 3),
          name: name,
          article: _cellAsString(row, 5),
          manufacturer: _cellAsString(row, 6),
          unit: unit,
          quantity: quantity,
          price: price,
          total: total,
        ),
      );
    }

    return result;
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
      return 0.0;
    }

    final value = row[index]!.value;
    if (value is DoubleCellValue) {
      return value.value;
    }
    if (value is IntCellValue) {
      return value.value.toDouble();
    }

    return double.tryParse(
          value.toString().trim().replaceAll(' ', '').replaceAll(',', '.'),
        ) ??
        0.0;
  }

  static String? _normalizeNullable(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }
}
