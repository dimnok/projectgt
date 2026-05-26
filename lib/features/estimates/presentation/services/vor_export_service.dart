import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_saver/file_saver.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import '../../../../core/utils/formatters.dart';

/// Сервис для экспорта ведомостей ВОР в Excel/PDF.
class VorExportService {
  /// Клиент Supabase.
  final SupabaseClient client;

  /// Создает экземпляр [VorExportService].
  VorExportService(this.client);

  /// Генерирует и скачивает Excel файл для конкретной ведомости ВОР.
  Future<void> exportVorToExcel(String vorId) async {
    try {
      // 1. Проверяем, есть ли уже ссылка на файл в БД
      final vorData = await client
          .from('vors')
          .select(
            'excel_url, excel_combined_url, include_combined_sheet, number, status, contracts(objects(name))',
          )
          .eq('id', vorId)
          .single();

      final String? excelUrl = vorData['excel_url'];
      final String? excelCombinedUrl = vorData['excel_combined_url'];
      final bool includeCombinedSheet = vorData['include_combined_sheet'] ?? false;
      final String vorStatus = vorData['status'] as String? ?? 'draft';
      final bool isDraft = vorStatus == 'draft';
      final String vorNumber = vorData['number'] ?? 'б/н';
      final String objectName =
          vorData['contracts']?['objects']?['name'] ?? 'Объект';
      final String dateStr = formatRuDate(DateTime.now());
      final String filename = '${objectName}_${vorNumber}_$dateStr.xlsx';
      final String combinedFilename = '${objectName}_${vorNumber}_Общая_$dateStr.xlsx';

      // Для черновика всегда пересобираем Excel из актуальных vor_items.
      if (!isDraft && excelUrl != null && excelUrl.isNotEmpty) {
        debugPrint(
          '📂 [VorExport] Файл найден в Storage, скачиваем: $excelUrl',
        );
        try {
          final bytes = await client.storage
              .from('vor_documents')
              .download(excelUrl);
          final base64File = base64Encode(bytes);
          await _saveFile(
            base64File,
            filename,
            'xlsx',
            MimeType.microsoftExcel,
          );
          
          if (includeCombinedSheet && excelCombinedUrl != null && excelCombinedUrl.isNotEmpty) {
             debugPrint(
              '📂 [VorExport] Общий файл найден в Storage, скачиваем: $excelCombinedUrl',
            );
            final combinedBytes = await client.storage
                .from('vor_documents')
                .download(excelCombinedUrl);
            final combinedBase64File = base64Encode(combinedBytes);
            await _saveFile(
              combinedBase64File,
              combinedFilename,
              'xlsx',
              MimeType.microsoftExcel,
            );
          }
          
          return;
        } catch (e) {
          debugPrint(
            '⚠️ [VorExport] Ошибка скачивания из Storage, пробуем регенерацию: $e',
          );
        }
      }

      debugPrint('⚙️ [VorExport] Запускаем генерацию Excel...');
      final response = await client.functions.invoke(
        'generate_vor_v2',
        body: {'vorId': vorId, 'forceRegenerate': isDraft},
      );

      final data = response.data;
      if (data == null) throw Exception('Пустой ответ от сервера');

      final List<dynamic>? files = data['files'];
      
      if (files != null && files.isNotEmpty) {
        // Скачиваем все файлы из ответа
        for (final fileObj in files) {
          final String? base64File = fileObj['file'];
          final String fileType = fileObj['type'] ?? 'normal';
          final String currentFilename = fileType == 'combined' 
              ? '${objectName}_${vorNumber}_Общая_$dateStr.xlsx'
              : filename;
              
          if (base64File != null && base64File.isNotEmpty) {
            await _saveFile(base64File, currentFilename, 'xlsx', MimeType.microsoftExcel);
          }
        }
      } else {
        // Резервный вариант для старых ответов
        final String? base64File = data['file'];
        if (base64File == null || base64File.isEmpty) {
          throw Exception('Ответ не содержит файл');
        }
        await _saveFile(base64File, filename, 'xlsx', MimeType.microsoftExcel);
      }
    } catch (e) {
      debugPrint('❌ [VorExport] Ошибка экспорта Excel: $e');
      rethrow;
    }
  }

  /// Генерирует файл и сохраняет его в Storage без скачивания на устройство.
  Future<void> generateAndSaveVor(String vorId) async {
    try {
      debugPrint('⚙️ [VorExport] Фоновая генерация и сохранение в Storage...');
      await client.functions.invoke('generate_vor_v2', body: {'vorId': vorId});
    } catch (e) {
      debugPrint('❌ [VorExport] Ошибка фоновой генерации: $e');
      rethrow;
    }
  }

  /// Генерирует и скачивает Excel файл со списанием материалов для конкретной ведомости ВОР.
  Future<void> exportVorMaterialsReport({
    required String vorId,
    required String companyId,
  }) async {
    try {
      debugPrint('⚙️ [VorExport] Генерация отчета по материалам...');

      // 1. Получаем инфо о ВОР для названия файла
      final vorData = await client
          .from('vors')
          .select('number, contracts(objects(name))')
          .eq('id', vorId)
          .single();

      final String vorNumber = vorData['number'] ?? 'б/н';
      final String objectName =
          vorData['contracts']?['objects']?['name'] ?? 'Объект';
      final String dateStr = formatRuDate(DateTime.now());
      final String filename =
          'Списание_материалов_${objectName}_${vorNumber}_$dateStr.xlsx';

      // 2. Вызываем Edge Function
      final response = await client.functions.invoke(
        'export-vor-materials',
        body: {'vorId': vorId, 'companyId': companyId},
      );

      final data = response.data;
      if (data == null) throw Exception('Пустой ответ от сервера');
      if (data['error'] != null) throw Exception(data['error']);

      final String? base64File = data['file'];
      if (base64File == null || base64File.isEmpty) {
        throw Exception('Ответ не содержит файл');
      }

      // 3. Сохраняем файл
      await _saveFile(base64File, filename, 'xlsx', MimeType.microsoftExcel);
    } catch (e) {
      debugPrint('❌ [VorExport] Ошибка экспорта отчета по материалам: $e');
      rethrow;
    }
  }

  /// Вспомогательный метод для сохранения файла на разных платформах.

  Future<void> _saveFile(
    String base64,
    String filename,
    String ext,
    MimeType mimeType,
  ) async {
    final fileBytes = base64Decode(base64);

    if (kIsWeb) {
      await FileSaver.instance.saveFile(
        name: filename.replaceAll('.$ext', ''),
        bytes: Uint8List.fromList(fileBytes),
        ext: ext,
        mimeType: mimeType,
      );
      return;
    }

    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      String? outputFile = await FilePicker.saveFile(
        dialogTitle: 'Выберите место для сохранения файла',
        fileName: filename,
        type: FileType.custom,
        allowedExtensions: [ext],
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsBytes(fileBytes);
      }
    } else {
      // Мобильные платформы
      final directory = await path_provider.getTemporaryDirectory();
      final filePath = '${directory.path}/$filename';
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      await SharePlus.instance.share(
        ShareParams(files: [XFile(filePath)], text: 'Ведомость ВОР: $filename'),
      );
    }
  }
}
