import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_enums.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_item.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_operation.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_unit.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_write_off.dart';

/// Экспорт реестров и отчётов ТМЦ в Excel.
class TmcExcelExportService {
  /// Создаёт сервис экспорта.
  const TmcExcelExportService();

  /// Экспорт реестра позиций.
  Uint8List exportItems(List<TmcItem> items, {bool includeCost = true}) {
    final excel = Excel.createExcel();
    final sheet = excel['ТМЦ'];
    excel.delete('Sheet1');

    final headers = <String>[
      'Наименование',
      'Категория',
      'Тип учёта',
      'Артикул',
      'Ед. изм.',
      'Количество',
      if (includeCost) 'Цена',
      if (includeCost) 'Сумма',
      'Статус',
      'Поставщик',
      'Дата поставки',
    ];
    _writeHeader(sheet, headers);

    for (var r = 0; r < items.length; r++) {
      final item = items[r];
      var c = 0;
      _cell(sheet, c++, r + 1, item.name);
      _cell(sheet, c++, r + 1, item.categoryName ?? '');
      _cell(sheet, c++, r + 1, item.accountingType.displayName);
      _cell(sheet, c++, r + 1, item.sku ?? '');
      _cell(sheet, c++, r + 1, item.unitOfMeasure);
      _cellNum(sheet, c++, r + 1, item.quantity);
      if (includeCost) {
        _cellNum(sheet, c++, r + 1, item.unitPrice);
        _cellNum(sheet, c++, r + 1, item.totalCost);
      }
      _cell(sheet, c++, r + 1, item.status.displayName);
      _cell(sheet, c++, r + 1, item.supplierName ?? '');
      _cell(sheet, c++, r + 1, _date(item.deliveryDate));
    }

    return Uint8List.fromList(excel.encode()!);
  }

  /// Экспорт единиц имущества с местонахождением.
  Uint8List exportUnits(List<TmcUnit> units, {bool includeCost = true}) {
    final excel = Excel.createExcel();
    final sheet = excel['Единицы'];
    excel.delete('Sheet1');

    final headers = <String>[
      'Инв. номер',
      'Позиция',
      'Серийный номер',
      'Статус',
      'Тип места',
      'Склад',
      'Объект',
      'Сотрудник',
      if (includeCost) 'Цена',
      'Дата приобретения',
    ];
    _writeHeader(sheet, headers);

    for (var r = 0; r < units.length; r++) {
      final u = units[r];
      var c = 0;
      _cell(sheet, c++, r + 1, u.inventoryNumber);
      _cell(sheet, c++, r + 1, u.itemName ?? '');
      _cell(sheet, c++, r + 1, u.serialNumber ?? '');
      _cell(sheet, c++, r + 1, u.status.displayName);
      _cell(sheet, c++, r + 1, u.locationType.displayName);
      _cell(sheet, c++, r + 1, u.warehouseName ?? '');
      _cell(sheet, c++, r + 1, u.objectName ?? '');
      _cell(sheet, c++, r + 1, u.employeeName ?? '');
      if (includeCost) {
        _cellNum(sheet, c++, r + 1, u.purchasePrice);
      }
      _cell(sheet, c++, r + 1, _date(u.purchaseDate));
    }

    return Uint8List.fromList(excel.encode()!);
  }

  /// Экспорт операций.
  Uint8List exportOperations(List<TmcOperation> operations) {
    final excel = Excel.createExcel();
    final sheet = excel['Операции'];
    excel.delete('Sheet1');

    final headers = [
      'Дата',
      'Тип',
      'Документ',
      'Позиции',
      'Основание',
      'Комментарий',
    ];
    _writeHeader(sheet, headers);

    for (var r = 0; r < operations.length; r++) {
      final op = operations[r];
      final lines = op.items
          .map((l) => l.itemName ?? l.inventoryNumber ?? l.itemId)
          .join('; ');
      _cell(sheet, 0, r + 1, op.operatedAt.toIso8601String());
      _cell(sheet, 1, r + 1, op.operationType.displayName);
      _cell(sheet, 2, r + 1, op.documentNumber ?? '');
      _cell(sheet, 3, r + 1, lines);
      _cell(sheet, 4, r + 1, op.basis ?? '');
      _cell(sheet, 5, r + 1, op.comment ?? '');
    }

    return Uint8List.fromList(excel.encode()!);
  }

  /// Экспорт списаний.
  Uint8List exportWriteOffs(List<TmcWriteOff> writeOffs) {
    final excel = Excel.createExcel();
    final sheet = excel['Списания'];
    excel.delete('Sheet1');

    final headers = [
      'Дата',
      'Позиция',
      'Инв. номер',
      'Причина',
      'Количество',
      'Акт',
      'Комментарий',
    ];
    _writeHeader(sheet, headers);

    for (var r = 0; r < writeOffs.length; r++) {
      final w = writeOffs[r];
      _cell(sheet, 0, r + 1, _date(w.writtenOffAt));
      _cell(sheet, 1, r + 1, w.itemName ?? '');
      _cell(sheet, 2, r + 1, w.inventoryNumber ?? '');
      _cell(sheet, 3, r + 1, w.reason.displayName);
      _cellNum(sheet, 4, r + 1, w.quantity);
      _cell(sheet, 5, r + 1, w.actNumber ?? '');
      _cell(sheet, 6, r + 1, w.comment ?? '');
    }

    return Uint8List.fromList(excel.encode()!);
  }

  void _writeHeader(Sheet sheet, List<String> headers) {
    for (var c = 0; c < headers.length; c++) {
      _cell(sheet, c, 0, headers[c]);
    }
  }

  void _cell(Sheet sheet, int col, int row, String value) {
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
        .value = TextCellValue(value);
  }

  void _cellNum(Sheet sheet, int col, int row, double value) {
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
        .value = DoubleCellValue(value);
  }

  String _date(DateTime? value) =>
      value?.toIso8601String().split('T').first ?? '';
}
