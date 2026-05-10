import 'dart:math' as math;
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:projectgt/core/utils/xlsx_excel_compatibility.dart';
import 'package:projectgt/features/contractors/presentation/services/subcontractor_rates_excel_export_service.dart';

/// Фрагмент данных из Excel по одной позиции (только непустые поля из файла).
class SubcontractorImportContribution {
  /// Создаёт описание вклада строки импорта.
  const SubcontractorImportContribution({
    this.unitPrice,
    this.contractorQuantity,
  });

  /// Расценка за ед., если в файле была заполнена колонка.
  final double? unitPrice;

  /// Объём подрядчика, если колонка была заполнена.
  final double? contractorQuantity;
}

/// Импорт расценок и объёмов подрядчика из Excel (шаблон [SubcontractorRatesExcelExportService]).
class SubcontractorRatesExcelImportService {
  SubcontractorRatesExcelImportService._();

  static final RegExp _uuidRe = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Читает лист «Расценки суба».
  ///
  /// Для каждой позиции объединяет вклад строк файла: пустая ячейка не меняет уже
  /// накопленное по этой позиции из предыдущих строк. Строка без цены и без объёма пропускается.
  static Map<String, SubcontractorImportContribution> parseImportRows(
    Uint8List bytes,
  ) {
    final excel = Excel.decodeBytes(sanitizeXlsxForExcelNumberFormats(bytes));
    final sheetName =
        excel.tables.containsKey(SubcontractorRatesExcelExportService.sheetName)
        ? SubcontractorRatesExcelExportService.sheetName
        : excel.tables.keys.first;
    final sheet = excel.tables[sheetName];
    if (sheet == null || sheet.rows.isEmpty) {
      throw Exception('Не удалось прочитать лист Excel');
    }

    final rows = sheet.rows;
    final headerCell = rows[0].isNotEmpty ? rows[0][0] : null;
    final headerText = _cellString(headerCell);
    if (headerText != 'ID позиции') {
      throw Exception(
        'Ожидается файл выгрузки расценок (лист «${SubcontractorRatesExcelExportService.sheetName}», колонка «ID позиции»)',
      );
    }

    final merged = <String, SubcontractorImportContribution>{};

    void mergeRow(String id, double? price, double? qty) {
      if (price == null && qty == null) return;
      final prev = merged[id];
      merged[id] = SubcontractorImportContribution(
        unitPrice: price ?? prev?.unitPrice,
        contractorQuantity: qty ?? prev?.contractorQuantity,
      );
    }

    for (var ri = 1; ri < rows.length; ri++) {
      final row = rows[ri];
      if (row.length < 11) continue;

      final sectionTitle = _cellString(row[2]);
      if (sectionTitle == 'Итого по разделу' ||
          sectionTitle == 'Итого по договору') {
        continue;
      }

      final idRaw = _cellString(row[0]);
      if (idRaw.isEmpty || !_uuidRe.hasMatch(idRaw)) continue;

      // Как в шаблоне экспорта: кол. «Кол-во суб», затем «Цена суб».
      final qty = _parseNonNegativeNumber(row[9], 'кол-во суб', ri + 1);
      final price = _parseNonNegativeNumber(row[10], 'цена суб', ri + 1);

      if (price == null && qty == null) continue;
      mergeRow(idRaw, price, qty);
    }

    return merged;
  }

  /// Проверяет позиции договора/объекта, подмешивает уже сохранённые поля и upsert.
  ///
  /// Пустое поле в файле не перезаписывает значение в БД. Возвращает число записей в upsert.
  static Future<int> validateAndUpsert(
    SupabaseClient client, {
    required String companyId,
    required String contractId,
    required String objectId,
    required String contractorId,
    required Map<String, SubcontractorImportContribution>
    contributionsByEstimateId,
  }) async {
    if (contributionsByEstimateId.isEmpty) {
      throw Exception(
        'В файле нет строк с заполненной расценкой или объёмом подрядчика',
      );
    }

    final ids = contributionsByEstimateId.keys.toList();
    final allowed = <String>{};

    const batchSize = 20;
    for (var i = 0; i < ids.length; i += batchSize) {
      final batch = ids.sublist(i, math.min(i + batchSize, ids.length));
      final rows = await client
          .from('estimates')
          .select('id')
          .eq('company_id', companyId)
          .eq('contract_id', contractId)
          .eq('object_id', objectId)
          .inFilter('id', batch);
      for (final row in rows as List<dynamic>) {
        final id = row['id'] as String?;
        if (id != null) allowed.add(id);
      }
    }

    final invalidCount = ids.length - allowed.length;
    if (invalidCount > 0) {
      throw Exception(
        '$invalidCount поз. не относятся к выбранному договору и объекту — проверьте файл и фильтры',
      );
    }

    final allowedList = allowed.toList();
    final existing =
        <String, ({double? unitPrice, double? contractorQuantity})>{};

    for (var i = 0; i < allowedList.length; i += batchSize) {
      final batch = allowedList.sublist(
        i,
        math.min(i + batchSize, allowedList.length),
      );
      final exRows = await client
          .from('estimate_contractor_prices')
          .select('estimate_id, unit_price, contractor_quantity')
          .eq('company_id', companyId)
          .eq('contractor_id', contractorId)
          .inFilter('estimate_id', batch);

      for (final row in exRows as List<dynamic>) {
        final eid = row['estimate_id'] as String?;
        if (eid == null) continue;
        final up = row['unit_price'];
        final cq = row['contractor_quantity'];
        existing[eid] = (
          unitPrice: up == null ? null : (up as num).toDouble(),
          contractorQuantity: cq == null ? null : (cq as num).toDouble(),
        );
      }
    }

    final payload = <Map<String, Object?>>[];
    for (final id in contributionsByEstimateId.keys) {
      if (!allowed.contains(id)) continue;
      final filePart = contributionsByEstimateId[id]!;
      final ex = existing[id];
      final unitPrice = filePart.unitPrice ?? ex?.unitPrice;
      final contractorQuantity =
          filePart.contractorQuantity ?? ex?.contractorQuantity;
      if (unitPrice == null && contractorQuantity == null) {
        continue;
      }
      payload.add({
        'company_id': companyId,
        'estimate_id': id,
        'contractor_id': contractorId,
        'unit_price': unitPrice,
        'contractor_quantity': contractorQuantity,
      });
    }

    if (payload.isEmpty) {
      throw Exception('Нечего записать: после объединения с БД нет значений');
    }

    const upsertBatch = 50;
    for (var i = 0; i < payload.length; i += upsertBatch) {
      final chunk = payload.sublist(
        i,
        math.min(i + upsertBatch, payload.length),
      );
      await client
          .from('estimate_contractor_prices')
          .upsert(chunk, onConflict: 'estimate_id,contractor_id');
    }

    return payload.length;
  }

  static String _cellString(Data? cell) {
    if (cell?.value == null) return '';
    final v = cell!.value!;
    if (v is IntCellValue) return v.value.toString();
    if (v is DoubleCellValue) {
      final d = v.value;
      if (d == d.roundToDouble()) return d.round().toString();
      return d.toString();
    }
    return v.toString().trim();
  }

  /// Число ≥ 0 или null, если ячейка пустая.
  static double? _parseNonNegativeNumber(
    Data? cell,
    String label,
    int excelRow1Based,
  ) {
    if (cell?.value == null) return null;
    final v = cell!.value!;
    double? n;
    if (v is DoubleCellValue) {
      n = v.value;
    } else if (v is IntCellValue) {
      n = v.value.toDouble();
    } else {
      final s = v
          .toString()
          .trim()
          .replaceAll(RegExp(r'\s+'), '')
          .replaceAll(',', '.');
      if (s.isEmpty) return null;
      n = double.tryParse(s);
      if (n == null) {
        throw Exception('Неверное число ($label) в строке $excelRow1Based');
      }
    }
    if (n < 0) {
      throw Exception(
        'Отрицательное значение ($label) в строке $excelRow1Based',
      );
    }
    return n;
  }
}
