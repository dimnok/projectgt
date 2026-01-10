import 'dart:typed_data';
import 'package:excel/excel.dart' as xls;
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import '../widgets/materials_date_filter.dart';
import '../providers/materials_providers.dart';

/// Экспорт «Материал по М-15» за выбранный период в XLSX.
/// Кнопка в AppBar, формирующая xlsx-файл с детализацией и итогами по сметам.
class MaterialsExportAction extends ConsumerWidget {
  /// Конструктор действия экспорта в XLSX.
  const MaterialsExportAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(materialsDateRangeProvider);
    if (range == null) return const SizedBox.shrink();
    return IconButton(
      tooltip: 'Экспорт за период (XLSX)',
      icon: const Icon(Icons.download_rounded),
      onPressed: () async {
        final contract = ref.read(selectedContractNumberProvider);
        final start =
            DateTime(range.start.year, range.start.month, range.start.day);
        final end = DateTime(range.end.year, range.end.month, range.end.day);
        final client = ref.read(supabaseClientProvider);
        try {
          final activeCompanyId = ref.read(activeCompanyIdProvider);
          final rows = await client.rpc('v_materials_usage_period', params: {
            'in_contract_number': contract,
            'in_date_start': _d(start),
            'in_date_end': _d(end),
            'p_company_id': activeCompanyId,
          }) as List<dynamic>;
          if (!context.mounted) return;
          await _exportXlsx(context, rows, contract, start, end);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Ошибка экспорта: $e')),
            );
          }
        }
      },
    );
  }

  static String _d(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  /// Формирует Excel-файл и сохраняет его через FileSaver.
  Future<void> _exportXlsx(
    BuildContext context,
    List<dynamic> rows,
    String? contract,
    DateTime start,
    DateTime end,
  ) async {
    final book = xls.Excel.createExcel();
    final detail = book['Детализация'];
    book.delete('Sheet1');

    // Заголовки «Детализация»
    final headers = <String>[
      '№',
      'Наименование',
      'Ед. изм.',
      'Кол-во',
      'Цена за ед.',
      'Сумма',
      '№ накладной',
      'Дата',
      'Использовано с начала строительства',
      'Использовано',
      'Остаток',
      'Наименование по смете',
    ];
    for (int i = 0; i < headers.length; i++) {
      final cell = detail
          .cell(xls.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = xls.TextCellValue(headers[i]);
      cell.cellStyle = xls.CellStyle(bold: true);
    }

    // Строки
    int r = 1;
    final df = DateFormat('dd.MM.yyyy');
    final Map<String, _Sum> sums = {};
    for (final raw in rows) {
      final m = raw as Map<String, dynamic>;
      final date = m['receipt_date']?.toString();
      final number = m['receipt_number']?.toString() ?? '';
      final name = m['name']?.toString() ?? '';
      final unit = m['unit']?.toString() ?? '';
      final qty = _toNum(m['quantity']);
      final price = _toNum(m['price']);
      final total = _toNum(m['total']);
      final used = _toNum(m['used_period']);
      final rem = _toNum(m['remaining_end']);
      final en = m['estimate_number']?.toString() ?? '';
      final ename = m['estimate_name']?.toString() ?? '';
      final usedTotal = _toNum(m['used_total']);

      // Пропускаем строки без операций за период
      if (used == null || used <= 0) {
        continue;
      }

      final cells = <xls.CellValue>[
        xls.DoubleCellValue(r.toDouble()), // № начинается с 1
        xls.TextCellValue(name),
        xls.TextCellValue(unit),
        qty != null ? xls.DoubleCellValue(qty) : xls.TextCellValue(''),
        price != null ? xls.DoubleCellValue(price) : xls.TextCellValue(''),
        total != null ? xls.DoubleCellValue(total) : xls.TextCellValue(''),
        xls.TextCellValue(number),
        xls.TextCellValue(date != null ? df.format(DateTime.parse(date)) : ''),
        usedTotal != null
            ? xls.DoubleCellValue(usedTotal)
            : xls.TextCellValue(''),
        xls.DoubleCellValue(used),
        rem != null ? xls.DoubleCellValue(rem) : xls.TextCellValue(''),
        xls.TextCellValue(ename),
      ];
      for (int c = 0; c < cells.length; c++) {
        detail
            .cell(xls.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r))
            .value = cells[c];
      }
      r++;

      // Агрегат по смете
      final sumKey = m['estimate_id']?.toString() ?? ename;
      final s = sums.putIfAbsent(sumKey,
          () => _Sum(unit: unit, estimateNumber: en, estimateName: ename));
      s.used += used;
    }

    for (int i = 0; i < headers.length; i++) {
      detail.setColumnAutoFit(i);
    }

    // Лист «Итоги»
    final totals = book['Итоги по сметам'];
    final th = ['№ сметы', 'Смета', 'Ед. изм.', 'Использовано за период'];
    for (int i = 0; i < th.length; i++) {
      final cell = totals
          .cell(xls.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = xls.TextCellValue(th[i]);
      cell.cellStyle = xls.CellStyle(bold: true);
    }
    int tr = 1;
    for (final s in sums.values) {
      totals
          .cell(xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: tr))
          .value = xls.TextCellValue(s.estimateNumber);
      totals
          .cell(xls.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: tr))
          .value = xls.TextCellValue(s.estimateName);
      totals
          .cell(xls.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: tr))
          .value = xls.TextCellValue(s.unit);
      totals
          .cell(xls.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: tr))
          .value = xls.DoubleCellValue(s.used);
      tr++;
    }
    for (int i = 0; i < th.length; i++) {
      totals.setColumnAutoFit(i);
    }

    final bytes = book.encode();
    if (bytes == null) throw Exception('Не удалось сформировать Excel');
    final fname = _fileName(contract, start, end);
    await FileSaver.instance.saveFile(
      name: fname,
      bytes: Uint8List.fromList(bytes),
      mimeType: MimeType.microsoftExcel,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Экспортирован файл: $fname')),
      );
    }
  }

  /// Безопасное приведение динамического значения к double.
  double? _toNum(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  /// Генерирует безопасное имя файла для экспорта.
  String _fileName(String? contract, DateTime start, DateTime end) {
    // ignore: deprecated_member_use
    final cs = (contract ?? 'all').replaceAll(RegExp(r"[^A-Za-z0-9._-]+"), '_');
    final s = DateFormat('yyyyMMdd').format(start);
    final e = DateFormat('yyyyMMdd').format(end);
    return 'm15_usage_${cs}_$s-$e.xlsx';
  }
}

class _Sum {
  final String unit;
  final String estimateNumber;
  final String estimateName;
  double used = 0;
  _Sum(
      {required this.unit,
      required this.estimateNumber,
      required this.estimateName});
}
