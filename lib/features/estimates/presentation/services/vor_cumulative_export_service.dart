import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_saver/file_saver.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import '../../../../core/utils/formatters.dart';

/// Сервис для генерации накопительного Excel отчета по всем ВОР договора.
class VorCumulativeExportService {
  /// Клиент Supabase.
  final SupabaseClient client;

  /// Создает экземпляр [VorCumulativeExportService].
  VorCumulativeExportService(this.client);

  /// Генерирует и скачивает накопительный Excel файл для договора.
  Future<void> exportCumulativeVorToExcel({
    required String contractId,
    required String companyId,
  }) async {
    try {
      debugPrint('⚙️ [CumulativeExport] Генерация накопительного отчета...');

      // 1. Вызываем Edge Function
      final response = await client.functions.invoke(
        'export-cumulative-vor',
        body: {'contractId': contractId, 'companyId': companyId},
      );

      final data = response.data;
      if (data == null) throw Exception('Пустой ответ от сервера');
      if (data['error'] != null) throw Exception(data['error']);

      final String? base64File = data['file'];
      if (base64File == null || base64File.isEmpty) {
        throw Exception('Ответ не содержит файл');
      }

      final String filename = data['filename'] ??
          'Накопительная_ВОР_${formatRuDate(DateTime.now())}.xlsx';

      // 2. Сохраняем файл
      await _saveFile(base64File, filename, 'xlsx', MimeType.microsoftExcel);
    } catch (e) {
      debugPrint('❌ [CumulativeExport] Ошибка экспорта: $e');
      rethrow;
    }
  }

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
      String? outputFile = await FilePicker.platform.saveFile(
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
      final directory = await path_provider.getTemporaryDirectory();
      final filePath = '${directory.path}/$filename';
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          text: 'Накопительная ВОР: $filename',
        ),
      );
    }
  }
}
