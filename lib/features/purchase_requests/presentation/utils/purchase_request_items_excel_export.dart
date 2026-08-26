import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:projectgt/core/utils/attachment_file_save.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_item.dart';

/// Сборка Excel с позициями заявки на устройстве пользователя (без Storage).
class PurchaseRequestItemsExcelExportService {
  /// Создаёт сервис.
  const PurchaseRequestItemsExcelExportService();

  /// Имя листа с позициями.
  static const String sheetName = 'Позиции';

  /// Имя файла по номеру заявки, например `Заявка_ЗП-2026-00001.xlsx`.
  static String fileNameFor(String requestNumber) {
    final safe = requestNumber
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
    final suffix = safe.isEmpty ? 'заявка' : safe;
    return 'Заявка_$suffix.xlsx';
  }

  /// Формирует xlsx: №, наименование, количество, ед. изм., артикул.
  Uint8List exportItems(List<PurchaseRequestItem> items) {
    final excel = Excel.createExcel();
    final sheet = excel[sheetName];
    excel.delete('Sheet1');

    const headers = ['№', 'Наименование', 'Количество', 'Ед. изм.', 'Артикул'];
    for (var c = 0; c < headers.length; c++) {
      _text(sheet, c, 0, headers[c]);
    }

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final row = i + 1;
      _int(sheet, 0, row, i + 1);
      _text(sheet, 1, row, item.name);
      _num(sheet, 2, row, item.quantity);
      _text(sheet, 3, row, item.unit);
      _text(sheet, 4, row, item.article?.trim() ?? '');
    }

    return Uint8List.fromList(excel.encode()!);
  }

  void _text(Sheet sheet, int col, int row, String value) {
    sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
            .value =
        TextCellValue(value);
  }

  void _int(Sheet sheet, int col, int row, int value) {
    sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
            .value =
        IntCellValue(value);
  }

  void _num(Sheet sheet, int col, int row, double value) {
    sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
            .value =
        DoubleCellValue(value);
  }
}

/// Собирает Excel с позициями и предлагает сохранить его на устройство.
///
/// Файл на сервер не загружается.
Future<void> exportPurchaseRequestItemsToDevice({
  required BuildContext context,
  required String requestNumber,
  required List<PurchaseRequestItem> items,
}) async {
  if (items.isEmpty) {
    AppSnackBar.show(
      context: context,
      message: 'Нет позиций для выгрузки',
      kind: AppSnackBarKind.warning,
    );
    return;
  }

  try {
    const service = PurchaseRequestItemsExcelExportService();
    final bytes = service.exportItems(items);
    await saveFileBytesToUserDevice(
      fileName: PurchaseRequestItemsExcelExportService.fileNameFor(
        requestNumber,
      ),
      bytes: bytes,
    );
  } catch (error) {
    if (!context.mounted) return;
    AppSnackBar.show(
      context: context,
      message: 'Не удалось сохранить Excel: $error',
      kind: AppSnackBarKind.error,
    );
  }
}
