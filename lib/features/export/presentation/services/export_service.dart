import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_saver/file_saver.dart';
import '../../domain/entities/export_report.dart';

/// Сервис для экспорта данных в Excel.
class ExportService {
  /// Экспортирует данные в Excel файл.
  ///
  /// [data] — список отчетов для экспорта (уже агрегированные)
  /// [outputFile] — имя выходного файла
  ///
  /// Возвращает путь к созданному файлу.
  Future<String> exportToExcel(
    List<ExportReport> data,
    String outputFile, {
    List<String>? columns,
    String? sheetName,
  }) async {
    try {
      // Создаем новый Excel файл
      final excel = Excel.createExcel();
      // Имя листа: название объекта + дата выгрузки
      final exportDateStr = DateFormat('dd.MM.yyyy').format(DateTime.now());
      String baseObjectName;
      if (data.isEmpty) {
        baseObjectName = 'Отчет';
      } else {
        final objects = data.map((e) => e.objectName).toSet();
        baseObjectName = objects.length == 1 ? objects.first : 'Сводный отчет';
      }
      final computedSheetName = sheetName ?? '$baseObjectName $exportDateStr';
      // Ограничение Excel на имя листа — до 31 символа и без спецсимволов
      final sanitized = computedSheetName
          .replaceAll('\\', ' ')
          .replaceAll('/', ' ')
          .replaceAll('*', ' ')
          .replaceAll('?', ' ')
          .replaceAll('[', ' ')
          .replaceAll(']', ' ');
      final finalSheetName = sanitized.isEmpty
          ? 'Отчет'
          : (sanitized.length > 31 ? sanitized.substring(0, 31) : sanitized);

      final sheet = excel[finalSheetName];
      // Удаляем стандартный лист
      excel.delete('Sheet1');

      // Конфигурация колонок и порядок
      final columnConfig = <String, String>{
        'object': 'Объект',
        'contract': 'Договор',
        'system': 'Система',
        'subsystem': 'Подсистема',
        'section': 'Участок',
        'floor': 'Этаж',
        'position': '№ позиции',
        'work': 'Наименование работы',
        'unit': 'Ед. изм.',
        'quantity': 'Кол-во',
        'price': 'Цена за единицу',
        'total': 'Сумма',
      };
      final selectedColumns = (columns ??
          [
            'object',
            'contract',
            'system',
            'subsystem',
            'section',
            'floor',
            'position',
            'work',
            'unit',
            'quantity',
            'price',
            'total',
          ])
        ..removeWhere((k) =>
            k == 'employee' || k == 'hours' || k == 'materials' || k == 'date');

      // Стили
      final headerStyle = CellStyle(
        bold: true,
        fontSize: 12,
        fontColorHex: ExcelColor.black,
      );
      final dataStyle = CellStyle(
        fontSize: 11,
        fontColorHex: ExcelColor.black,
      );

      // Заголовки
      for (int i = 0; i < selectedColumns.length; i++) {
        final key = selectedColumns[i];
        final title = columnConfig[key] ?? key;
        final cell =
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(title);
        cell.cellStyle = headerStyle;
      }

      // Данные (уже агрегированные)
      int outRow = 1;
      for (final report in data) {
        for (int colIdx = 0; colIdx < selectedColumns.length; colIdx++) {
          final key = selectedColumns[colIdx];
          CellValue? value;

          switch (key) {
            case 'date':
              value = TextCellValue(_formatDate(report.workDate));
              break;
            case 'object':
              value = TextCellValue(report.objectName);
              break;
            case 'contract':
              value = TextCellValue(report.contractName);
              break;
            case 'system':
              value = TextCellValue(report.system);
              break;
            case 'subsystem':
              value = TextCellValue(report.subsystem);
              break;
            case 'position':
              final posNum = double.tryParse(report.positionNumber);
              value = posNum != null
                  ? DoubleCellValue(posNum)
                  : TextCellValue(report.positionNumber);
              break;
            case 'work':
              value = TextCellValue(report.workName);
              break;
            case 'section':
              value = TextCellValue(report.section);
              break;
            case 'floor':
              final floorNum = double.tryParse(report.floor);
              value = floorNum != null
                  ? DoubleCellValue(floorNum)
                  : TextCellValue(report.floor);
              break;
            case 'unit':
              value = TextCellValue(report.unit);
              break;
            case 'quantity':
              value = DoubleCellValue(report.quantity.toDouble());
              break;
            case 'price':
              value = report.price != null
                  ? DoubleCellValue(report.price!)
                  : TextCellValue('');
              break;
            case 'total':
              value = report.total != null
                  ? DoubleCellValue(report.total!)
                  : TextCellValue('');
              break;
            default:
              value = TextCellValue('');
          }

          final cell = sheet.cell(CellIndex.indexByColumnRow(
            columnIndex: colIdx,
            rowIndex: outRow,
          ));
          cell.value = value;
          cell.cellStyle = dataStyle;
        }
        outRow++;
      }

      // Автоподбор ширины по выбранным колонкам
      for (int i = 0; i < selectedColumns.length; i++) {
        sheet.setColumnAutoFit(i);
      }

      // Сохраняем файл (Web через браузер, остальные платформы — локально)
      final bytes = excel.encode();
      if (bytes == null) {
        throw Exception('Не удалось создать Excel файл');
      }

      if (kIsWeb) {
        await FileSaver.instance.saveFile(
          name: outputFile,
          bytes: Uint8List.fromList(bytes),
          mimeType: MimeType.microsoftExcel,
        );
        return outputFile;
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$outputFile');
        await file.writeAsBytes(bytes);
        return outputFile;
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Форматирует дату для отображения в Excel.
  String _formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }
}
