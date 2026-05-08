import 'dart:convert' show utf8;
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// Первый id пользовательского числового формата в OOXML: встроенные 0–163, кастомные с 164+.
const int kExcelFirstCustomNumFmtId = 164;

/// Предобработка `.xlsx` перед [Excel.decodeBytes] из пакета [excel]: исправляет типичные
/// случаи, когда в `xl/styles.xml` в секции custom [numFmts] оказываются встроенные
/// `numFmtId` (меньше 164) — библиотека тогда бросает
/// `Exception: custom numFmtId starts at 164 but found a value of ...`.
///
/// Для снятых id обновляются `numFmt`/`numFmts` и сбрасываются ссылки [xf@numFmtId] на `0` (General).
///
/// Возвращает [bytes] без изменений, если [xl/styles.xml] нет, правок нет, либо пересборка zip не удалась.
Uint8List sanitizeXlsxForExcelNumberFormats(Uint8List bytes) {
  final archive = ZipDecoder().decodeBytes(bytes);
  final out = Archive();
  var archiveChanged = false;

  for (final file in archive.files) {
    if (!file.isFile) {
      out.addFile(file);
      continue;
    }
    if (file.name != 'xl/styles.xml') {
      out.addFile(file);
      continue;
    }

    var stylesChanged = false;
    final raw = file.content;
    final list = raw is Uint8List
        ? raw
        : Uint8List.fromList(raw as List<int>);
    final source = utf8.decode(list);
    final doc = XmlDocument.parse(source);
    final removed = <int>{};

    for (final node in doc.findAllElements('numFmt')) {
      final id = int.tryParse(node.getAttribute('numFmtId') ?? '');
      if (id == null) continue;
      if (id < kExcelFirstCustomNumFmtId) {
        removed.add(id);
        node.remove();
        stylesChanged = true;
      }
    }

    if (removed.isNotEmpty) {
      for (final numFmts in doc.findAllElements('numFmts').toList()) {
        if (numFmts.findElements('numFmt').isEmpty) {
          numFmts.remove();
        } else {
          final n = numFmts.findElements('numFmt').length;
          numFmts.setAttribute('count', '$n');
        }
      }
      for (final xf in doc.findAllElements('xf')) {
        final a = xf.getAttribute('numFmtId');
        final n = int.tryParse(a ?? '');
        if (n != null && removed.contains(n)) {
          xf.setAttribute('numFmtId', '0');
        }
      }
    }

    if (stylesChanged) {
      archiveChanged = true;
      final newBytes = utf8.encode(doc.toXmlString(pretty: false));
      out.addFile(ArchiveFile('xl/styles.xml', newBytes.length, newBytes));
    } else {
      out.addFile(file);
    }
  }

  if (!archiveChanged) {
    return bytes;
  }
  final encoded = ZipEncoder().encode(out);
  if (encoded == null) {
    return bytes;
  }
  return Uint8List.fromList(encoded);
}
