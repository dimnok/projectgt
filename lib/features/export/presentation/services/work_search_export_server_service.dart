import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../../core/utils/formatters.dart';
import 'package:file_saver/file_saver.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:file_picker/file_picker.dart';
import 'dart:io';

/// Сервис экспорта результатов поиска на сервер
class WorkSearchExportServerService {
  /// Клиент Supabase
  final SupabaseClient client;

  /// Конструктор
  WorkSearchExportServerService({required this.client});

  /// Загружает ВСЕ результаты поиска (без пагинации) с сервера
  Future<List<Map<String, dynamic>>> loadAllSearchResults({
    required String objectId,
    required String objectName,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? systemFilters,
    List<String>? sectionFilters,
    List<String>? floorFilters,
  }) async {
    try {
      final response = await client.functions.invoke(
        'export-work-search-all',
        body: {
          'objectId': objectId,
          'searchQuery': searchQuery,
          'startDate': startDate != null
              ? GtFormatters.formatDateForApi(startDate)
              : null,
          'endDate': endDate != null
              ? GtFormatters.formatDateForApi(endDate)
              : null,
          'systemFilters': systemFilters,
          'sectionFilters': sectionFilters,
          'floorFilters': floorFilters,
        },
        headers: {
          'Authorization':
              'Bearer ${client.auth.currentSession?.accessToken ?? ''}',
          'Content-Type': 'application/json',
        },
      );

      // Парсим ответ
      late final Map<String, dynamic> data;

      try {
        dynamic responseData;
        if (response is Map) {
          responseData = response;
        } else {
          try {
            responseData = response.data;
          } catch (e) {
            responseData = response.toString();
          }
        }

        if (responseData is String) {
          data = jsonDecode(responseData) as Map<String, dynamic>;
        } else if (responseData is Map) {
          data = Map<String, dynamic>.from(responseData);
        } else {
          throw Exception(
            'Неизвестный формат ответа: ${responseData.runtimeType}',
          );
        }
      } catch (e) {
        throw Exception('Ошибка парсинга ответа: $e');
      }

      final success = data['success'] as bool?;

      if (success != true) {
        final errMsg = data['message'] ?? 'Ошибка загрузки данных';
        throw Exception(errMsg);
      }

      final results =
          (data['results'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      return results;
    } on FunctionException catch (e) {
      throw Exception('Ошибка вызова функции: $e');
    } catch (e) {
      throw Exception('Ошибка загрузки данных: $e');
    }
  }

  /// Экспортирует результаты поиска в формате ПТО
  Future<ExportResult> exportToPTO({
    required List<Map<String, dynamic>> results,
    required String objectName,
    required String contractName,
  }) async {
    try {
      final response = await client.functions.invoke(
        'export-work-search-pto',
        body: {
          'results': results,
          'exportType': 'pto',
          'objectName': objectName,
          'contractName': contractName,
        },
        headers: {
          'Authorization':
              'Bearer ${client.auth.currentSession?.accessToken ?? ''}',
          'Content-Type': 'application/json',
        },
      );

      // Парсим ответ
      late final Map<String, dynamic> data;

      try {
        dynamic responseData;
        if (response is Map) {
          responseData = response;
        } else {
          try {
            responseData = response.data;
          } catch (e) {
            responseData = response.toString();
          }
        }

        if (responseData is String) {
          data = jsonDecode(responseData) as Map<String, dynamic>;
        } else if (responseData is Map) {
          data = Map<String, dynamic>.from(responseData);
        } else {
          throw Exception(
            'Неизвестный формат ответа: ${responseData.runtimeType}',
          );
        }
      } catch (e) {
        throw Exception('Ошибка парсинга ответа: $e');
      }

      final success = data['success'] as bool?;

      if (success != true) {
        final errMsg = data['message'] ?? 'Ошибка экспорта на сервере';
        throw Exception(errMsg);
      }

      final filename = data['filename'] as String? ?? 'export.xlsx';
      final rowsCount = data['rows'] as int? ?? results.length;
      final message = data['message'] as String? ?? 'Экспорт успешен';

      // Получаем base64 файл
      String? base64 = data['base64'] as String?;
      String? filePath;

      if (base64 != null && base64.isNotEmpty) {
        filePath = await _saveExcelFile(base64, filename);
      }

      return ExportResult(
        success: true,
        filename: filename,
        rowsCount: rowsCount,
        message: message,
        filePath: filePath,
      );
    } on FunctionException catch (e) {
      throw Exception('Ошибка вызова функции: $e');
    } catch (e) {
      throw Exception('Ошибка экспорта: $e');
    }
  }

  /// Экспортирует данные ФОТ за указанный период
  Future<ExportResult> exportPayroll({
    required int year,
    required int month,
    required String companyId,
  }) async {
    try {
      final response = await client.functions.invoke(
        'export-payroll',
        body: {
          'year': year,
          'month': month,
          'companyId': companyId,
        },
        headers: {
          'Authorization':
              'Bearer ${client.auth.currentSession?.accessToken ?? ''}',
          'Content-Type': 'application/json',
        },
      );

      // Парсим ответ
      late final Map<String, dynamic> data;

      try {
        dynamic responseData;
        if (response is Map) {
          responseData = response;
        } else {
          try {
            responseData = response.data;
          } catch (e) {
            responseData = response.toString();
          }
        }

        if (responseData is String) {
          data = jsonDecode(responseData) as Map<String, dynamic>;
        } else if (responseData is Map) {
          data = Map<String, dynamic>.from(responseData);
        } else {
          throw Exception(
            'Неизвестный формат ответа: ${responseData.runtimeType}',
          );
        }
      } catch (e) {
        throw Exception('Ошибка парсинга ответа: $e');
      }

      final success = data['success'] as bool?;

      if (success != true) {
        final errMsg = data['message'] ?? 'Ошибка экспорта на сервере';
        throw Exception(errMsg);
      }

      final filename = data['filename'] as String? ?? 'payroll_export.xlsx';
      final rowsCount = data['rows'] as int? ?? 0;
      final message = data['message'] as String? ?? 'Экспорт успешен';

      // Получаем base64 файл
      String? base64 = data['base64'] as String?;
      String? filePath;

      if (base64 != null && base64.isNotEmpty) {
        filePath = await _saveExcelFile(base64, filename);
      }

      return ExportResult(
        success: true,
        filename: filename,
        rowsCount: rowsCount,
        message: message,
        filePath: filePath,
      );
    } on FunctionException catch (e) {
      throw Exception('Ошибка вызова функции: $e');
    } catch (e) {
      throw Exception('Ошибка экспорта: $e');
    }
  }

  /// Сохраняет Excel файл из base64
  Future<String> _saveExcelFile(String base64, String filename) async {
    try {
      // Декодируем base64 в bytes
      final fileBytes = base64Decode(base64);

      if (kIsWeb) {
        // На Web используем FileSaver
        return await FileSaver.instance.saveFile(
          name: filename.replaceAll('.xlsx', ''),
          bytes: Uint8List.fromList(fileBytes),
          ext: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );
      } else if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        // На Desktop (macOS, Windows, Linux) даем выбрать папку и имя
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Выберите место для сохранения Excel файла',
          fileName: filename,
          type: FileType.custom,
          allowedExtensions: ['xlsx'],
        );

        if (outputFile == null) {
          return 'cancelled';
        }

        final file = File(outputFile);
        await file.writeAsBytes(fileBytes);
        return outputFile;
      } else {
        // На мобильных платформах (iOS, Android)
        final directory = await path_provider.getTemporaryDirectory();
        final filePath = '${directory.path}/$filename';
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);

        await SharePlus.instance.share(
          ShareParams(files: [XFile(filePath)], text: 'Экспорт: $filename'),
        );

        return filePath;
      }
    } catch (e) {
      throw Exception('Ошибка сохранения файла: $e');
    }
  }
}

/// Результат экспорта
class ExportResult {
  /// Успешность экспорта
  final bool success;

  /// Имя файла
  final String filename;

  /// Количество строк в итоговом файле
  final int rowsCount;

  /// Сообщение
  final String message;

  /// Путь к сохраненному файлу (если base64 был передан)
  final String? filePath;

  /// Конструктор
  ExportResult({
    required this.success,
    required this.filename,
    required this.rowsCount,
    required this.message,
    this.filePath,
  });
}
