import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

// Импорты для мобильных платформ
import 'dart:io' as io;
import 'package:path_provider/path_provider.dart' as path_provider;

// Для Web
import 'package:universal_html/html.dart' as html;

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
          'startDate': startDate?.toIso8601String().split('T')[0],
          'endDate': endDate?.toIso8601String().split('T')[0],
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
              'Неизвестный формат ответа: ${responseData.runtimeType}');
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
        // FunctionResponse имеет свойство .data
        dynamic responseData;
        if (response is Map) {
          responseData = response;
        } else {
          // Пытаемся получить .data из FunctionResponse
          try {
            responseData = response.data;
          } catch (e) {
            responseData = response.toString();
          }
        }

        // Парсим данные
        if (responseData is String) {
          data = jsonDecode(responseData) as Map<String, dynamic>;
        } else if (responseData is Map) {
          data = Map<String, dynamic>.from(responseData);
        } else {
          throw Exception(
              'Неизвестный формат ответа: ${responseData.runtimeType}');
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

  /// Сохраняет Excel файл из base64
  Future<String> _saveExcelFile(String base64, String filename) async {
    try {
      // Декодируем base64 в bytes
      final fileBytes = base64Decode(base64);

      // Проверяем платформу
      if (kIsWeb) {
        // На Web - просто скачиваем
        await _downloadFileOnWeb(fileBytes, filename);
        return 'downloaded';
      } else {
        // На мобильных - сохраняем локально
        final directory =
            await path_provider.getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$filename';

        // Сохраняем файл
        final file = io.File(filePath);
        await file.writeAsBytes(fileBytes);

        return filePath;
      }
    } catch (e) {
      throw Exception('Ошибка сохранения файла: $e');
    }
  }

  /// Скачивает файл на Web
  Future<void> _downloadFileOnWeb(List<int> fileBytes, String filename) async {
    try {
      // Создаём Blob и скачиваем файл
      final blob = html.Blob(
        [Uint8List.fromList(fileBytes)],
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      final url = html.Url.createObjectUrlFromBlob(blob);

      html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();

      html.Url.revokeObjectUrl(url);
    } catch (e) {
      throw Exception('Ошибка скачивания файла: $e');
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
