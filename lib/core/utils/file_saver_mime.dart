import 'package:file_saver/file_saver.dart';

/// Возвращает [MimeType] пакета `file_saver` по расширению имени файла (без точки).
///
/// Используется при сохранении скачанных файлов через [FileSaver].
MimeType mimeTypeForFileSaverExtension(String extension) {
  switch (extension.toLowerCase()) {
    case 'pdf':
      return MimeType.pdf;
    case 'doc':
    case 'docx':
      return MimeType.microsoftWord;
    case 'xls':
    case 'xlsx':
      return MimeType.microsoftExcel;
    case 'jpg':
    case 'jpeg':
      return MimeType.jpeg;
    case 'png':
      return MimeType.png;
    default:
      return MimeType.other;
  }
}
