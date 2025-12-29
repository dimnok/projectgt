import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

/// Краткая модель позиции из приходного документа, возвращаемая парсером.
/// Используется для предпросмотра данных, распознанных из Excel.
class ReceiptItemPreview {
  /// Наименование материала или товара.
  final String? name;

  /// Единица измерения (например, шт, м, кг).
  final String? unit;

  /// Количество.
  final num? quantity;

  /// Цена за единицу.
  final num? price;

  /// Сумма по позиции (количество × цена).
  final num? total;

  /// Номер приходного документа/чека (общий для позиций).
  final String? receiptNumber;

  /// Дата документа/чека.
  final DateTime? receiptDate;

  /// Номер договора, если указан.
  final String? contractNumber;

  /// Создаёт элемент предпросмотра позиции приходного документа.
  const ReceiptItemPreview({
    this.name,
    this.unit,
    this.quantity,
    this.price,
    this.total,
    this.receiptNumber,
    this.receiptDate,
    this.contractNumber,
  });
}

/// Результат парсинга файла приходного документа на стороне Edge Function.
/// Содержит метаданные файла/листа, общие поля документа и список позиций.
class ReceiptParseResult {
  /// Имя исходного файла, переданного на парсинг.
  final String fileName;

  /// Текст ошибки, если парсинг не удался.
  final String? error;

  /// Имя листа, по которому выполнен парсинг.
  final String? sheet;

  /// Номер приходного документа/чека.
  final String? receiptNumber;

  /// Дата документа.
  final DateTime? receiptDate;

  /// Номер договора, если распознан.
  final String? contractNumber;

  /// Список распознанных позиций.
  final List<ReceiptItemPreview> items;

  /// Создаёт объект результата парсинга приходного документа.
  const ReceiptParseResult({
    required this.fileName,
    this.error,
    this.sheet,
    this.receiptNumber,
    this.receiptDate,
    this.contractNumber,
    this.items = const [],
  });
}

/// Парсер приходных документов, использующий Supabase Edge Function `excel_parse`.
/// Поддерживаются форматы файлов: `.xls` и `.xlsx`.
class ReceiptsRemoteParser {
  /// Загружает JSON-маппинг для парсинга из ассета [assetPath].
  /// Если ассет отсутствует/невалиден — возвращает минимальный маппинг по умолчанию.
  static Future<Map<String, dynamic>> loadMappingJson(
      {String assetPath = 'assets/templates/receipts/mapping.json'}) async {
    final logger = Logger();
    try {
      final s = await rootBundle.loadString(assetPath);
      final m = jsonDecode(s) as Map<String, dynamic>;
      if (m.isNotEmpty) return m;
    } catch (e) {
      logger.w('Не удалось загрузить маппинг из ассета $assetPath: $e. Используем fallback.');
    }
    // Fallback маппинг, синхронизированный с актуальным mapping.json (E11 для договора и т.д.)
    return <String, dynamic>{
      'sheet': 'Лист_1',
      'headerRow': 16,
      'dataStartRow': 17,
      'globals': {
        'receiptDateCell': {'ref': 'E9', 'dateFormat': 'dd.MM.yyyy'},
        'receiptNumberCell': {'ref': 'J2'},
        'contractNumberCell': {'ref': 'E11'},
      },
      'stopAtEmptyIn': ['E'],
      'columns': {
        'name': 'E',
        'unit': 'M',
        'quantity': 'Q',
        'price': 'U',
        'total': 'Z',
      },
      'numbers': {'decimal': ',', 'thousands': ' '},
      'skipRowsIfCellContains': ['ИТОГО', 'ВСЕГО'],
    };
  }

  /// Парсит байты Excel-файла удалённо через Edge Function `excel_parse`
  /// (поддерживает `.xls` и `.xlsx`). Возвращает структурированный результат.
  ///
  /// Аргументы:
  /// - [bytes] — содержимое файла `Uint8List` (будет кодировано в Base64);
  /// - [fileName] — имя файла для логирования и отчётности в результате.
  static Future<ReceiptParseResult> parseBytes({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final mapping = await loadMappingJson();
      final payload = {
        'file': base64Encode(bytes),
        'mapping': mapping,
      };
      final res = await Supabase.instance.client.functions.invoke(
        'excel_parse',
        body: payload,
        headers: {'Content-Type': 'application/json'},
      );
      if (res.data is Map) {
        final map = res.data as Map;
        if (map['error'] is String) {
          return ReceiptParseResult(
              fileName: fileName, error: map['error'] as String);
        }
        final items = <ReceiptItemPreview>[];
        for (final it in (map['items'] as List? ?? const [])) {
          final m = (it as Map);
          items.add(ReceiptItemPreview(
            name: m['name']?.toString(),
            unit: m['unit']?.toString(),
            quantity: (m['quantity'] is num)
                ? m['quantity'] as num
                : num.tryParse(m['quantity']?.toString() ?? ''),
            price: (m['price'] is num)
                ? m['price'] as num
                : num.tryParse(m['price']?.toString() ?? ''),
            total: (m['total'] is num)
                ? m['total'] as num
                : num.tryParse(m['total']?.toString() ?? ''),
            receiptNumber: map['receiptNumber']?.toString(),
            receiptDate: map['receiptDate'] != null
                ? DateTime.tryParse(map['receiptDate'].toString())
                : null,
            contractNumber: map['contractNumber']?.toString(),
          ));
        }
        return ReceiptParseResult(
          fileName: fileName,
          sheet: map['sheet']?.toString(),
          receiptNumber: map['receiptNumber']?.toString(),
          receiptDate: map['receiptDate'] != null
              ? DateTime.tryParse(map['receiptDate'].toString())
              : null,
          contractNumber: map['contractNumber']?.toString(),
          items: items,
        );
      }
      return ReceiptParseResult(
          fileName: fileName, error: 'Неверный ответ сервера');
    } catch (e) {
      return ReceiptParseResult(fileName: fileName, error: e.toString());
    }
  }
}
