import 'package:flutter/material.dart';
import 'package:projectgt/core/widgets/attachment_file_preview.dart';

/// Открывает просмотр подписанного скана заявления.
Future<void> openEmployeeApplicationScanPreview({
  required BuildContext context,
  required String fileName,
  required String contentType,
  required List<int> bytes,
}) {
  return openAttachmentFilePreview(
    context: context,
    fileName: fileName,
    mimeType: contentType,
    bytes: bytes,
  );
}
