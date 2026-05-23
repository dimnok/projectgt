import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:logger/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/mobile_atmosphere_backdrop.dart';
import '../../../../core/widgets/mobile_atmosphere_screen_header.dart';
import '../../data/parsers/receipts_remote_parser.dart';
import '../providers/materials_context_providers.dart';
import '../providers/materials_providers.dart';
import 'materials_import_preview_dialog.dart';

/// Кнопка импорта накладных (стиль «хрома» экрана материалов).
///
/// По нажатию открывается диалог выбора файлов с поддержкой множественного выбора.
/// Поддерживаемые форматы: .xlsx (рекомендуется). Файлы .xls отмечаются предупреждением.
class MaterialsImportAction extends ConsumerWidget {
  /// Создаёт кнопку импорта накладных.
  const MaterialsImportAction({
    super.key,
    required this.appearance,
  });

  /// Оформление атмосферы экрана.
  final MobileAtmosphereAppearance appearance;

  /// Парсит выбранный файл через удалённый парсер и приводит результат к UI-формату.
  Future<ReceiptParseResult> _parseFile(PlatformFile f) async {
    final name = f.name;
    final bytes = f.bytes;
    if (bytes == null) {
      return ReceiptParseResult(fileName: name, error: 'Нет данных файла');
    }
    final res = await ReceiptsRemoteParser.parseBytes(
      bytes: Uint8List.fromList(bytes),
      fileName: name,
    );
    return _cleanResult(res);
  }

  /// Фильтрует мусорные строки из результата парсинга (шапки/итоги/индексы).
  ReceiptParseResult _cleanResult(ReceiptParseResult r) {
    if (r.error != null) return r;
    final skipTokens = ['итого', 'всего'];
    bool isHeaderLike(ReceiptItemPreview it) {
      final s = '${it.name ?? ''} ${it.unit ?? ''}'.toLowerCase();
      return s.contains('наимен') ||
          s.contains('ед. изм') ||
          s.contains('материальные ценности') ||
          s.contains('наиме-') ||
          s.contains('наименований');
    }

    bool isNumericIndexRow(ReceiptItemPreview it) {
      final rowStr =
          '${it.name ?? ''} ${it.unit ?? ''} ${it.quantity ?? ''} ${it.price ?? ''} ${it.total ?? ''}'
              .trim();
      if (rowStr.isEmpty) return false;
      final numTokens =
          // ignore: deprecated_member_use
          RegExp(r'[0-9]+(?:[.,][0-9]+)?').allMatches(rowStr).length;
      // ignore: deprecated_member_use
      final hasLetters = RegExp(r'[A-Za-zА-Яа-я]').hasMatch(rowStr);
      return !hasLetters && numTokens >= 3;
    }

    final cleaned = r.items.where((it) {
      final rowStr =
          '${it.name ?? ''} ${it.unit ?? ''} ${it.quantity ?? ''} ${it.price ?? ''} ${it.total ?? ''}'
              .toLowerCase();
      if (skipTokens.any((t) => rowStr.contains(t))) return false;
      if (isHeaderLike(it)) return false;
      if (isNumericIndexRow(it)) return false;
      final hasAnyNumeric =
          (it.quantity != null) || (it.price != null) || (it.total != null);
      final hasName = (it.name != null && it.name!.trim().isNotEmpty);
      return hasAnyNumeric || hasName;
    }).toList();
    return ReceiptParseResult(
      fileName: r.fileName,
      sheet: r.sheet,
      receiptNumber: r.receiptNumber,
      receiptDate: r.receiptDate,
      contractNumber: r.contractNumber,
      items: cleaned,
    );
  }

  /// Открывает диалог выбора файлов и запускает предпросмотр импорта.
  Future<void> _pickFiles(BuildContext context, WidgetRef ref) async {
    final selectedContract = ref.read(selectedContractNumberProvider)?.trim();
    if (!hasMaterialsContractSelection(selectedContract)) {
      AppSnackBar.show(
        context: context,
        message: 'Сначала выберите объект и договор',
        kind: AppSnackBarKind.warning,
      );
      return;
    }

    final logger = Logger();
    FilePickerResult? result;

    try {
      result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: const ['xlsx', 'xls'],
        withData: true,
      );
    } on PlatformException catch (e) {
      logger.e('Ошибка при выборе файлов (PlatformException): $e');
      if (context.mounted) {
        AppSnackBar.show(
          context: context,
          message: 'Ошибка доступа к файлам. Проверьте права приложения.',
          kind: AppSnackBarKind.error,
        );
      }
      return;
    } catch (e) {
      logger.e('Неизвестная ошибка при выборе файлов: $e');
      if (context.mounted) {
        AppSnackBar.show(
          context: context,
          message: 'Произошла ошибка при выборе файлов.',
          kind: AppSnackBarKind.error,
        );
      }
      return;
    }

    if (result == null || result.files.isEmpty) return;
    if (!context.mounted) return;

    // ignore: discarded_futures
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const MaterialsImportParsingProgressDialog(),
    );

    await Future<void>.delayed(const Duration(milliseconds: 16));

    final futures = <Future<ReceiptParseResult>>[];
    final Map<String, Uint8List> bytesByName = <String, Uint8List>{};
    for (final f in result.files) {
      futures.add(_parseFile(f));
      final b = f.bytes;
      if (b != null && b.isNotEmpty) {
        bytesByName[f.name] = b;
      }
    }

    List<ReceiptParseResult> results = const [];
    try {
      results = await Future.wait(futures);
    } finally {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (context) {
        return MaterialsImportPreviewDialog(
          results: results,
          bytesByName: bytesByName,
          selectedContractNumber: selectedContract!,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MobileAtmosphereChromeCircleButton(
      appearance: appearance,
      tooltip: 'Импорт из Excel',
      icon: Icons.file_upload_outlined,
      iconColor: appearance.scheme.primary,
      onTap: () => _pickFiles(context, ref),
    );
  }
}
