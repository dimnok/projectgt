import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

/// Открывает просмотр вложения: PDF на полном экране, изображение — в диалоге.
Future<void> openAttachmentFilePreview({
  required BuildContext context,
  required String fileName,
  required List<int> bytes,
  String? mimeType,
}) async {
  final lowerName = fileName.toLowerCase();
  final type = (mimeType ?? '').toLowerCase();
  final isPdf = type.contains('pdf') || lowerName.endsWith('.pdf');
  final isImage = type.startsWith('image/') ||
      lowerName.endsWith('.jpg') ||
      lowerName.endsWith('.jpeg') ||
      lowerName.endsWith('.png');

  if (isPdf) {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => Scaffold(
          appBar: AppBar(
            title: Text(
              fileName,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          body: PdfPreview(
            build: (_) async => Uint8List.fromList(bytes),
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
            allowSharing: false,
            allowPrinting: true,
            pdfFileName: fileName,
            loadingWidget: const Center(child: CupertinoActivityIndicator()),
          ),
        ),
      ),
    );
    return;
  }

  if (isImage) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900, maxHeight: 720),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        fileName,
                        style: Theme.of(ctx).textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(CupertinoIcons.xmark),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: InteractiveViewer(
                  child: Image.memory(
                    Uint8List.fromList(bytes),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return;
  }

  throw UnsupportedError('Формат файла не поддерживается для просмотра');
}
