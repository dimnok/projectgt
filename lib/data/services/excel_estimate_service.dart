import 'package:excel/excel.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io' as io;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/foundation.dart' show debugPrint;

/// Результат валидации Excel-файла сметы.
class ExcelValidationResult {
  /// Валиден ли файл.
  final bool isValid;
  /// Список ошибок.
  final List<String> errors;
  /// Список предупреждений.
  final List<String> warnings;
  /// Создаёт результат валидации.
  const ExcelValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });
}

/// Результат предпросмотра Excel-файла сметы.
class ExcelPreviewResult {
  /// Все строки файла.
  final List<List<Data?>> rows;
  /// Количество строк.
  final int rowCount;
  /// Количество валидных строк.
  final int validRowCount;
  /// Общая сумма.
  final double totalAmount;
  /// Создаёт результат предпросмотра.
  const ExcelPreviewResult({
    required this.rows,
    required this.rowCount,
    required this.validRowCount,
    required this.totalAmount,
  });
}

/// Сервис для работы с Excel-шаблонами смет.
class ExcelEstimateService {
  /// Путь к шаблону Excel в assets.
  static const String templateAssetPath = 'assets/templates/estimate_template.xlsx';
  /// Путь к тестовому текстовому файлу в assets.
  static const String testTextFile = 'assets/templates/test.txt';
  /// Список обязательных колонок в Excel-файле сметы.
  static const List<String> requiredColumns = [
    'Система', 'Подсистема', '№', 'Наименование', 'Артикул', 
    'Производитель', 'Ед. изм.', 'Кол-во', 'Цена', 'Сумма'
  ];

  /// Загружает шаблон Excel из assets.
  ///
  /// Возвращает содержимое шаблона как [Uint8List].
  static Future<Uint8List> loadTemplateFromAssets() async {
    try {
      // Загружаем шаблон из assets
      ByteData data = await rootBundle.load(templateAssetPath);
      debugPrint('Шаблон Excel загружен, размер: ${data.lengthInBytes} байт');
      return data.buffer.asUint8List();
    } catch (e) {
      debugPrint('Ошибка загрузки шаблона Excel: $e');
      throw Exception('Не удалось загрузить шаблон сметы: $e');
    }
  }

  /// Загружает шаблон Excel из файловой системы.
  ///
  /// Копирует файл из assets во временное хранилище и читает его.
  static Future<Uint8List> loadTemplateFromFileSystem() async {
    if (kIsWeb) {
      // Для веб используем стандартный метод
      return loadTemplateFromAssets();
    }
    
    try {
      // Получаем директорию для временных файлов
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/template.xlsx';
      final tempFile = io.File(tempPath);
      
      // Копируем файл из assets во временное хранилище
      final ByteData data = await rootBundle.load(templateAssetPath);
      final bytes = data.buffer.asUint8List();
      await tempFile.writeAsBytes(bytes);
      
      debugPrint('Файл скопирован во временную директорию: $tempPath');
      
      // Читаем файл
      final fileBytes = await tempFile.readAsBytes();
      debugPrint('Файл прочитан из временной директории, размер: ${fileBytes.length} байт');
      
      return fileBytes;
    } catch (e) {
      debugPrint('Ошибка при чтении шаблона из файловой системы: $e');
      return generateTemplate();
    }
  }

  /// Генерирует Excel-файл-шаблон для импорта смет.
  ///
  /// Возвращает байтовое представление Excel-файла с заголовками для импорта.
  static Uint8List generateTemplate() {
    final excel = Excel.createExcel();
    final sheet = excel['Смета'];
    sheet.appendRow([
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
    ]);
    // Добавляем пример строки:
    sheet.appendRow(['Система 1', 'Подсистема 1', 1, 'Товар', 'A-123', 'ООО Рога', 'шт', 10, 100.0, 1000.0]);
    final bytes = excel.encode()!;
    return Uint8List.fromList(bytes);
  }
  
  /// Валидирует Excel-файл на соответствие структуре шаблона сметы.
  ///
  /// [bytes] — байтовое представление Excel-файла.
  /// Возвращает результат валидации с информацией о статусе, ошибках и предупреждениях.
  static ExcelValidationResult validateExcelFile(Uint8List bytes) {
    final errors = <String>[];
    final warnings = <String>[];
    
    try {
      final excel = Excel.decodeBytes(bytes);
      if (excel.tables.isEmpty) {
        errors.add('Файл не содержит листов');
        return ExcelValidationResult(isValid: false, errors: errors);
      }
      
      final sheet = excel.tables[excel.tables.keys.first]!;
      if (sheet.rows.isEmpty) {
        errors.add('Лист не содержит строк');
        return ExcelValidationResult(isValid: false, errors: errors);
      }
      
      final headers = sheet.rows.first;
      if (headers.length < requiredColumns.length) {
        errors.add('В заголовке недостаточно колонок. Ожидалось: ${requiredColumns.length}, найдено: ${headers.length}');
      }
      
      // Проверяем заголовки
      for (int i = 0; i < requiredColumns.length; i++) {
        if (i >= headers.length || headers[i]?.value.toString().trim() != requiredColumns[i]) {
          errors.add('Ожидалась колонка "${requiredColumns[i]}" в позиции ${i + 1}');
        }
      }
      
      // Проверяем содержимое строк (если заголовки правильные)
      if (errors.isEmpty && sheet.rows.length > 1) {
        final dataRows = sheet.rows.skip(1).toList();
        int emptySystemCount = 0;
        int emptySubsystemCount = 0;
        int emptyNumberCount = 0;
        int emptyNameCount = 0;
        int emptyUnitCount = 0;
        
        for (int rowIndex = 0; rowIndex < dataRows.length; rowIndex++) {
          final row = dataRows[rowIndex];
          
          // Проверяем обязательные поля
          if (row.length < 10) {
            warnings.add('Строка ${rowIndex + 2} содержит меньше колонок, чем требуется (${row.length}/10)');
            continue;
          }
          
          if (row[0]?.value == null || row[0]!.value.toString().trim().isEmpty) emptySystemCount++;
          if (row[1]?.value == null || row[1]!.value.toString().trim().isEmpty) emptySubsystemCount++;
          if (row[2]?.value == null) emptyNumberCount++;
          if (row[3]?.value == null || row[3]!.value.toString().trim().isEmpty) emptyNameCount++;
          if (row[6]?.value == null || row[6]!.value.toString().trim().isEmpty) emptyUnitCount++;
        }
        
        if (emptySystemCount > 0) warnings.add('$emptySystemCount строк без указания системы');
        if (emptySubsystemCount > 0) warnings.add('$emptySubsystemCount строк без указания подсистемы');
        if (emptyNumberCount > 0) warnings.add('$emptyNumberCount строк без порядкового номера');
        if (emptyNameCount > 0) warnings.add('$emptyNameCount строк без наименования');
        if (emptyUnitCount > 0) warnings.add('$emptyUnitCount строк без единицы измерения');
      }
      
      return ExcelValidationResult(
        isValid: errors.isEmpty,
        errors: errors,
        warnings: warnings,
      );
    } catch (e) {
      errors.add('Ошибка при обработке файла: $e');
      return ExcelValidationResult(isValid: false, errors: errors);
    }
  }
  
  /// Подготавливает предпросмотр данных из Excel-файла.
  ///
  /// [bytes] — байтовое представление Excel-файла.
  /// Возвращает структуру с данными для предпросмотра.
  static ExcelPreviewResult preparePreview(Uint8List bytes) {
    try {
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables[excel.tables.keys.first]!;
      final rows = sheet.rows;
      
      if (rows.length <= 1) {
        return ExcelPreviewResult(
          rows: rows,
          rowCount: rows.length - 1,
          validRowCount: 0,
          totalAmount: 0,
        );
      }
      
      // Получаем только первые 10 строк для предпросмотра (заголовок + 9 строк данных)
      final previewRows = rows.length > 10 ? rows.sublist(0, 10) : rows;
      
      // Предварительно обрабатываем данные для корректного отображения
      // Это особенно важно для номеров, которые теперь имеют строковый тип
      for (int i = 0; i < previewRows.length; i++) {
        final row = previewRows[i];
        
        // Пропускаем заголовок
        if (i == 0) continue;
        
        // Обрабатываем ячейку с номером (индекс 2)
        if (row.length > 2 && row[2] != null) {
          final rawValue = row[2]!.value;
          
          // Если номер числовой, преобразуем его правильно
          if (rawValue is num) {
            // Если целое число - убираем десятичную часть
            if (rawValue == rawValue.truncate()) {
              // Важно - здесь мы модифицируем ячейку напрямую
              row[2]!.value = rawValue.toInt().toString();
            } else {
              // Если число с десятичной частью, сохраняем формат
              row[2]!.value = rawValue.toString();
            }
          }
        }
      }
      
      int validRowCount = 0;
      double totalAmount = 0;
      
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 10) continue;
        
        bool isValid = true;
        if (row[0]?.value == null || row[0]!.value.toString().trim().isEmpty) isValid = false;
        if (row[1]?.value == null || row[1]!.value.toString().trim().isEmpty) isValid = false;
        if (row[3]?.value == null || row[3]!.value.toString().trim().isEmpty) isValid = false;
        if (row[6]?.value == null || row[6]!.value.toString().trim().isEmpty) isValid = false;
        
        if (isValid) {
          validRowCount++;
          // Суммируем общую стоимость
          final totalCell = row[9]?.value;
          if (totalCell != null) {
            if (totalCell is num) {
              totalAmount += totalCell.toDouble();
            } else {
              String totalStr = totalCell.toString().replaceAll(RegExp(r'\s+'), '').replaceAll(',', '.');
              totalAmount += double.tryParse(totalStr) ?? 0;
            }
          }
        }
      }
      
      return ExcelPreviewResult(
        rows: previewRows,
        rowCount: rows.length - 1,
        validRowCount: validRowCount,
        totalAmount: totalAmount,
      );
    } catch (e) {
      debugPrint('Ошибка при подготовке предпросмотра Excel: $e');
      return const ExcelPreviewResult(
        rows: [],
        rowCount: 0,
        validRowCount: 0,
        totalAmount: 0,
      );
    }
  }
  
  /// Преобразует строку из Excel в EstimateModel.
  ///
  /// [row] — строка данных из Excel.
  /// [objectId] — идентификатор объекта.
  /// [contractId] — идентификатор договора.
  /// [estimateTitle] — название сметы.
  /// Возвращает объект EstimateModel или null, если строка недействительна.
  static dynamic rowToEstimateModel(
    List<Data?> row, 
    String? objectId, 
    String? contractId, 
    String estimateTitle
  ) {
    try {
      if (row.length < 10) return null;
      
      // Проверка обязательных полей
      if (row[0]?.value == null || row[0]!.value.toString().trim().isEmpty) return null;
      if (row[1]?.value == null || row[1]!.value.toString().trim().isEmpty) return null;
      if (row[3]?.value == null || row[3]!.value.toString().trim().isEmpty) return null;
      if (row[6]?.value == null || row[6]!.value.toString().trim().isEmpty) return null;
      
      // Получаем и форматируем номер как строку
      String number = '';
      if (row[2]?.value != null) {
        final rawValue = row[2]!.value;
        if (rawValue is num) {
          // Если это целое число, убираем десятичную часть
          if (rawValue == rawValue.truncate()) {
            number = rawValue.toInt().toString();
          } else {
            // Если число с десятичной частью, сохраняем как есть
            number = rawValue.toString();
          }
        } else {
          // Любой другой тип (строка или другое) преобразуем в строку
          number = rawValue.toString().trim();
        }
      }
      
      final priceStr = row[8]?.value?.toString() ?? '0';
      final totalStr = row[9]?.value?.toString() ?? '0';
      
      String clean(String value) => value.replaceAll(RegExp(r'\s+'), '').replaceAll(',', '.');
      final cleanPrice = clean(priceStr);
      final cleanTotal = clean(totalStr);
      
      // Преобразуем строки в числа для quantity, price и total
      double quantity = 0;
      if (row[7]?.value != null) {
        if (row[7]!.value is num) {
          quantity = (row[7]!.value as num).toDouble();
        } else {
          final rawStr = row[7]!.value.toString().trim();
          quantity = double.tryParse(clean(rawStr)) ?? 0;
        }
      }
      
      // Здесь вернем Map с данными для создания EstimateModel
      return {
        'system': row[0]?.value.toString() ?? '',
        'subsystem': row[1]?.value.toString() ?? '',
        'number': number,
        'name': row[3]?.value.toString() ?? '',
        'article': row[4]?.value.toString() ?? '',
        'manufacturer': row[5]?.value.toString() ?? '',
        'unit': row[6]?.value.toString() ?? '',
        'quantity': quantity,
        'price': double.tryParse(cleanPrice) ?? 0,
        'total': double.tryParse(cleanTotal) ?? 0,
        'objectId': objectId,
        'contractId': contractId,
        'estimateTitle': estimateTitle,
      };
    } catch (e) {
      debugPrint('Ошибка при обработке строки Excel: $e');
      return null;
    }
  }

  /// Тестирует загрузку обычного текстового файла из ассетов.
  ///
  /// Возвращает содержимое файла как строку.
  static Future<String> testAssetLoading() async {
    try {
      final String text = await rootBundle.loadString(testTextFile);
      debugPrint('Успешно загружен тестовый файл: $text');
      return text;
    } catch (e) {
      debugPrint('Ошибка загрузки тестового файла: $e');
      return 'Ошибка: $e';
    }
  }
} 