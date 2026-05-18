import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';

import 'package:projectgt/core/utils/file_saver_mime.dart';

/// Сохраняет [bytes] на устройстве пользователя под именем [fileName].
///
/// Веб — через [FileSaver]; macOS, Windows, Linux — системный диалог
/// «Сохранить как» ([getSaveLocation]); остальные платформы — снова [FileSaver].
Future<void> saveFileBytesToUserDevice({
  required String fileName,
  required List<int> bytes,
}) async {
  final extension = fileName.split('.').last;
  final nameWithoutExtension = fileName.replaceAll('.$extension', '');

  if (kIsWeb) {
    await FileSaver.instance.saveFile(
      name: nameWithoutExtension,
      bytes: Uint8List.fromList(bytes),
      ext: extension,
      mimeType: mimeTypeForFileSaverExtension(extension),
    );
    return;
  }

  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    final FileSaveLocation? result = await getSaveLocation(
      suggestedName: fileName,
      acceptedTypeGroups: [
        XTypeGroup(
          label: extension.toUpperCase(),
          extensions: [extension],
        ),
      ],
    );

    if (result != null) {
      final localFile = File(result.path);
      await localFile.writeAsBytes(bytes);
    }
    return;
  }

  await FileSaver.instance.saveFile(
    name: nameWithoutExtension,
    bytes: Uint8List.fromList(bytes),
    ext: extension,
    mimeType: mimeTypeForFileSaverExtension(extension),
  );
}
