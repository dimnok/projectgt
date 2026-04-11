import 'dart:io';

import 'package:file_picker/file_picker.dart';
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
    final file = selectedFile ?? await _pickPdfFile();
    if (file == null) return;
    if (!context.mounted) return;

    final filePath = file.path;
    if (filePath == null || filePath.isEmpty) {
      SnackBarUtils.showErrorOverlay(
        context,
        'Не удалось получить путь к выбранному PDF-файлу',
      );
      return;
    }

    try {
      await actions.uploadPdf(
        contractId: vor.contractId,
        vorId: vor.id,
        file: File(filePath),
        fileName: _ensurePdfExtension(file.name),
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
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );

    return result?.files.single;
  }

  static String _ensurePdfExtension(String fileName) {
    final normalized = fileName.trim();
    if (normalized.toLowerCase().endsWith('.pdf')) {
      return normalized;
    }
    return '$normalized.pdf';
  }
}
