import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_saver/file_saver.dart';
import '../../domain/entities/export_report.dart';

/// Внутренняя модель для агрегированных записей второго листа.
class _AggregatedEntry {
  final String objectName;
  final String contractName;
  final String system;
  final String subsystem;
  final String positionNumber;
  final String workName;

  /// Единица измерения, если во всех позициях совпадает. Иначе null.
  String? unitConsistent;

  /// Сумма количеств.
  double quantitySum;

  /// Цена, если во всех позициях совпадает и не null. Иначе null.
  double? priceConsistent;

  /// Накопленная итоговая сумма, если у исходных строк она присутствует.
  double? totalSum;

  _AggregatedEntry({
    required this.objectName,
    required this.contractName,
    required this.system,
    required this.subsystem,
    required this.positionNumber,
    required this.workName,
    required this.quantitySum,
    required this.priceConsistent,
    required this.unitConsistent,
    required this.totalSum,
  });
}

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
  Future<String> exportToExcel(List<ExportReport> data, String outputFile,
      {List<String>? columns,
      bool aggregate = false,
      String? sheetName}) async {
    try {
      logger.i('Начинаем экспорт ${data.length} записей в Excel');

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
      // Ограничение Excel на имя листа — до 31 символа и без спецсимволов \\ / * ? [ ]
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
        'date': 'Дата смены',
        'object': 'Объект',
        'contract': 'Договор',
        'system': 'Система',
        'subsystem': 'Подсистема',
        'position': '№ позиции',
        'work': 'Наименование работы',
        'section': 'Секция',
        'floor': 'Этаж',
        'unit': 'Единица измерения',
        'quantity': 'Количество',
        'price': 'Цена за единицу',
        'total': 'Итоговая сумма',
        'employee': 'Сотрудник',
        'hours': 'Часы',
        'materials': 'Материалы',
      };
      final selectedColumns = columns ??
          [
            'date',
            'object',
            'contract',
            'system',
            'subsystem',
            'position',
            'work',
            'section',
            'floor',
            'unit',
            'quantity',
            'price',
            'total',
            'employee',
            'hours',
            'materials',
          ];

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

      // Подготовка источника строк: агрегированные или детальные
      final Map<String, _AggregatedEntry> aggregated = {};
      if (aggregate) {
        for (final report in data) {
          final key = [
            report.objectName,
            report.contractName,
            report.system,
            report.subsystem,
            report.positionNumber,
            report.workName,
          ].join('||');

          if (!aggregated.containsKey(key)) {
            aggregated[key] = _AggregatedEntry(
              objectName: report.objectName,
              contractName: report.contractName,
              system: report.system,
              subsystem: report.subsystem,
              positionNumber: report.positionNumber,
              workName: report.workName,
              unitConsistent: report.unit,
              quantitySum: report.quantity.toDouble(),
              priceConsistent: report.price,
              totalSum: report.total?.toDouble(),
            );
          } else {
            final current = aggregated[key]!;
            current.quantitySum += report.quantity.toDouble();
            if (current.priceConsistent != null && report.price != null) {
              if (current.priceConsistent != report.price) {
                current.priceConsistent = null;
              }
            } else {
              current.priceConsistent = null;
            }
            if (current.unitConsistent != null && report.unit.isNotEmpty) {
              if (current.unitConsistent != report.unit) {
                current.unitConsistent = null;
              }
            } else if (report.unit.isEmpty) {
              current.unitConsistent = null;
            }
            if (report.total != null) {
              current.totalSum =
                  (current.totalSum ?? 0) + report.total!.toDouble();
            }
          }
        }
      }

      final Iterable<dynamic> rowsSource =
          aggregate ? aggregated.values.cast<dynamic>() : data.cast<dynamic>();

      // Заголовки
      for (int i = 0; i < selectedColumns.length; i++) {
        final key = selectedColumns[i];
        final title = columnConfig[key] ?? key;
        final cell =
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(title);
        cell.cellStyle = headerStyle;
      }

      // Данные
      int outRow = 1;
      for (final rowItem in rowsSource) {
        for (int colIdx = 0; colIdx < selectedColumns.length; colIdx++) {
          final key = selectedColumns[colIdx];
          CellValue? value;
          if (aggregate) {
            final entry = rowItem as _AggregatedEntry;
            switch (key) {
              case 'date':
                value = TextCellValue('');
                break;
              case 'object':
                value = TextCellValue(entry.objectName);
                break;
              case 'contract':
                value = TextCellValue(entry.contractName);
                break;
              case 'system':
                value = TextCellValue(entry.system);
                break;
              case 'subsystem':
                value = TextCellValue(entry.subsystem);
                break;
              case 'position':
                value = TextCellValue(entry.positionNumber);
                break;
              case 'work':
                value = TextCellValue(entry.workName);
                break;
              case 'section':
              case 'floor':
              case 'employee':
              case 'hours':
              case 'materials':
                value = TextCellValue('');
                break;
              case 'unit':
                value = TextCellValue(entry.unitConsistent ?? '');
                break;
              case 'quantity':
                value = DoubleCellValue(entry.quantitySum);
                break;
              case 'price':
                value = entry.priceConsistent != null
                    ? DoubleCellValue(entry.priceConsistent!)
                    : TextCellValue('');
                break;
              case 'total':
                final double? consistentPrice = entry.priceConsistent;
                final double? computedTotal = consistentPrice != null
                    ? (entry.quantitySum * consistentPrice)
                    : entry.totalSum;
                value = computedTotal != null
                    ? DoubleCellValue(computedTotal)
                    : TextCellValue('');
                break;
              default:
                value = TextCellValue('');
            }
          } else {
            final report = rowItem as ExportReport;
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
                value = TextCellValue(report.positionNumber);
                break;
              case 'work':
                value = TextCellValue(report.workName);
                break;
              case 'section':
                value = TextCellValue(report.section);
                break;
              case 'floor':
                value = TextCellValue(report.floor);
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
              case 'employee':
                value = TextCellValue(report.employeeName ?? '');
                break;
              case 'hours':
                value = report.hours != null
                    ? DoubleCellValue(report.hours!.toDouble())
                    : TextCellValue('');
                break;
              case 'materials':
                value = TextCellValue(report.materials ?? '');
                break;
              default:
                value = TextCellValue('');
            }
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
        logger.i('Файл сохранен через браузер: $outputFile');
        return outputFile;
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$outputFile');
        await file.writeAsBytes(bytes);
        logger.i('Файл успешно сохранен: $outputFile');
        return outputFile;
      }
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
