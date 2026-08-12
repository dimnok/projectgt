import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/snackbar_utils.dart';
import '../../../../domain/entities/vor.dart';
import '../providers/estimate_providers.dart';

/// Утилиты для загрузки и просмотра подписанного PDF-файла ВОР.
class VorPdfActions {
  /// Открывает уже загруженный PDF-файл ВОР во внешнем приложении.
  static Future<void> openPdf({
    required BuildContext context,
    required Vor vor,
    required VorActions actions,
  }) async {
    if (vor.pdfUrl == null || vor.pdfUrl!.isEmpty) {
      SnackBarUtils.showWarningOverlay(context, 'PDF-файл еще не загружен');
      return;
    }

    try {
      final signedUrl = await actions.getVorPdfViewUrl(vor.id);
      if (!context.mounted) return;

      final opened = await launchUrl(
        Uri.parse(signedUrl),
        mode: LaunchMode.externalApplication,
      );

      if (!opened && context.mounted) {
        SnackBarUtils.showErrorOverlay(context, 'Не удалось открыть PDF-файл');
      }
    } catch (error) {
      if (!context.mounted) return;
      SnackBarUtils.showErrorOverlay(
        context,
        'Ошибка при открытии PDF: $error',
      );
    }
  }

  /// Загружает PDF-файл для подписанной ВОР.
  static Future<void> uploadPdf({
    required BuildContext context,
    required Vor vor,
    required VorActions actions,
    PlatformFile? selectedFile,
  }) async {
    final platformFile = selectedFile ?? await _pickPdfFile();
    if (platformFile == null) return;
    if (!context.mounted) return;

    final bytes = await _readPdfBytes(platformFile);
    if (!context.mounted) return;
    if (bytes == null) {
      SnackBarUtils.showErrorOverlay(
        context,
        'Не удалось прочитать выбранный PDF-файл',
      );
      return;
    }

    try {
      await actions.uploadPdf(
        contractId: vor.contractId,
        vorId: vor.id,
        bytes: bytes,
        fileName: _ensurePdfExtension(platformFile.name),
      );

      if (!context.mounted) return;
      SnackBarUtils.showSuccessOverlay(context, 'PDF-файл успешно загружен');
    } catch (error) {
      if (!context.mounted) return;
      SnackBarUtils.showErrorOverlay(
        context,
        'Ошибка при загрузке PDF: $error',
      );
    }
  }

  static Future<PlatformFile?> _pickPdfFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
      withData: kIsWeb,
    );

    return result?.files.single;
  }

  static Future<Uint8List?> _readPdfBytes(PlatformFile file) async {
    if (file.bytes != null) {
      return file.bytes;
    }

    if (!kIsWeb && file.path != null && file.path!.isNotEmpty) {
      return File(file.path!).readAsBytes();
    }

    return null;
  }

  static String _ensurePdfExtension(String fileName) {
    final normalized = fileName.trim();
    if (normalized.toLowerCase().endsWith('.pdf')) {
      return normalized;
    }
    return '$normalized.pdf';
  }
}
