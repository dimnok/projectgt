import 'dart:io';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:share_plus/share_plus.dart';
import 'package:projectgt/features/profile/presentation/widgets/content_constrained_box.dart';

/// Экран предпросмотра PDF документа.
class PdfPreviewScreen extends StatelessWidget {
  /// Название файла (без расширения).
  final String fileName;

  /// Функция генерации PDF.
  final Future<Uint8List> Function(PdfPageFormat format) buildPdf;

  /// Создаёт экран предпросмотра.
  const PdfPreviewScreen({
    super.key,
    required this.fileName,
    required this.buildPdf,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: 'Предпросмотр',
        showThemeSwitch: false,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Web: Печать и Сохранить
          if (kIsWeb) ...[
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _printPdf,
              child: const Icon(CupertinoIcons.printer),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _savePdfWeb(context),
              child: const Icon(CupertinoIcons.arrow_down_doc),
            ),
          ]
          // Mobile: Только Поделиться
          else
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _sharePdf(context),
              child: const Icon(CupertinoIcons.share),
            ),
        ],
      ),
      body: ContentConstrainedBox(
        maxWidth: 1024,
        child: PdfPreview(
          build: buildPdf,
          canChangeOrientation: false,
          canChangePageFormat: false,
          canDebug: false,
          allowSharing: false,
          allowPrinting: false, // Мы используем свою кнопку печати
          pdfFileName: '$fileName.pdf',
          useActions: false, // Скрываем встроенный тулбар полностью
          loadingWidget: const Center(child: CupertinoActivityIndicator()),
          scrollViewDecoration: const BoxDecoration(
            color: Color(0xFFF5F5F5),
          ),
        ),
      ),
    );
  }

  Future<void> _printPdf() async {
    await Printing.layoutPdf(
      onLayout: buildPdf,
      name: fileName,
    );
  }

  /// Сохранение файла в Web с использованием file_saver.
  Future<void> _savePdfWeb(BuildContext context) async {
    try {
      final bytes = await buildPdf(PdfPageFormat.a4);

      // Используем FileSaver для скачивания файла в браузере
      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: bytes,
        ext: 'pdf',
        mimeType: MimeType.pdf,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при сохранении: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _sharePdf(BuildContext context) async {
    try {
      // Генерируем PDF
      final bytes = await buildPdf(PdfPageFormat.a4);

      final fullFileName = '$fileName.pdf';
      XFile fileToShare;

      if (kIsWeb) {
        // В вебе share_plus работает не везде как ожидается "Скачать",
        // поэтому для кнопки "Сохранить" мы используем _savePdfWeb.
        // Но если мы тут, значит это фолбек или если кто-то вызвал _sharePdf в вебе.
        fileToShare = XFile.fromData(
          bytes,
          name: fullFileName,
          mimeType: 'application/pdf',
        );
      } else {
        final output = await getTemporaryDirectory();
        final file = File('${output.path}/$fullFileName');
        await file.writeAsBytes(bytes);
        fileToShare = XFile(file.path);
      }

      if (context.mounted) {
        // Получаем координаты кнопки для iPad
        final box = context.findRenderObject() as RenderBox?;
        Rect? shareOrigin;
        if (box != null) {
          final size = box.size;
          shareOrigin = Rect.fromLTWH(size.width - 60, 0, 60, 60);
        }

        await SharePlus.instance.share(
          ShareParams(
            files: [fileToShare],
            text: fileName,
            sharePositionOrigin: shareOrigin,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
