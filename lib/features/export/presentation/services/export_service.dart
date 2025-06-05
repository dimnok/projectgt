import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/export_report.dart';

/// Сервис для экспорта данных в Excel.
class ExportService {
  /// Логгер для отслеживания операций экспорта.
  static final Logger logger = Logger();

  /// Экспортирует данные в Excel файл.
  ///
  /// [data] — список отчетов для экспорта
  /// [outputFile] — имя выходного файла
  ///
  /// Возвращает путь к созданному файлу.
  Future<String> exportToExcel(List<ExportReport> data, String outputFile) async {
    try {
      logger.i('Начинаем экспорт ${data.length} записей в Excel');

      // Создаем новый Excel файл
      final excel = Excel.createExcel();
      final sheet = excel['Отчет по работам'];

      // Удаляем стандартный лист
      excel.delete('Sheet1');

      // Заголовки колонок
      final headers = [
        'Дата смены',
        'Объект',
        'Договор',
        'Система',
        'Подсистема',
        'Наименование работы',
        'Секция',
        'Этаж',
        'Единица измерения',
        'Количество',
        'Цена за единицу',
        'Итоговая сумма',
        'Сотрудник',
        'Часы',
        'Материалы',
      ];

      // Стиль для заголовков
      final headerStyle = CellStyle(
        bold: true,
        fontSize: 12,
        fontColorHex: ExcelColor.black,
      );

      // Стиль для данных
      final dataStyle = CellStyle(
        fontSize: 11,
        fontColorHex: ExcelColor.black,
      );

      // Добавляем заголовки
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      // Добавляем данные
      for (int rowIndex = 0; rowIndex < data.length; rowIndex++) {
        final report = data[rowIndex];
        final actualRowIndex = rowIndex + 1; // +1 для заголовков

        final rowData = [
          TextCellValue(_formatDate(report.workDate)),
          TextCellValue(report.objectName),
          TextCellValue(report.contractName),
          TextCellValue(report.system),
          TextCellValue(report.subsystem),
          TextCellValue(report.workName),
          TextCellValue(report.section),
          TextCellValue(report.floor),
          TextCellValue(report.unit),
          DoubleCellValue(report.quantity.toDouble()),
          report.price != null ? DoubleCellValue(report.price!) : TextCellValue(''),
          report.total != null ? DoubleCellValue(report.total!) : TextCellValue(''),
          TextCellValue(report.employeeName ?? ''),
          report.hours != null ? DoubleCellValue(report.hours!.toDouble()) : TextCellValue(''),
          TextCellValue(report.materials ?? ''),
        ];

        for (int colIndex = 0; colIndex < rowData.length; colIndex++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(
            columnIndex: colIndex,
            rowIndex: actualRowIndex,
          ));
          cell.value = rowData[colIndex];
          cell.cellStyle = dataStyle;
        }
      }

      // Автоподбор ширины колонок
      for (int i = 0; i < headers.length; i++) {
        sheet.setColumnAutoFit(i);
      }

      // Сохраняем файл
      final bytes = excel.encode();
      if (bytes == null) {
        throw Exception('Не удалось создать Excel файл');
      }

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$outputFile');
      await file.writeAsBytes(bytes);
      logger.i('Файл успешно сохранен: $outputFile');
      return outputFile;
    } catch (e, stackTrace) {
      logger.e('Ошибка при экспорте в Excel', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Форматирует дату для отображения в Excel.
  String _formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }
} 