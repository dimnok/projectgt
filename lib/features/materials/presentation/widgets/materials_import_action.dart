import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/desktop_dialog_content.dart';
import '../../../../core/widgets/gt_buttons.dart';
import '../../data/parsers/receipts_remote_parser.dart';
import '../../data/repositories/materials_import_repository.dart';
import '../providers/materials_providers.dart';
import '../providers/materials_pager.dart';

/// Кнопка импорта накладных в AppBar.
///
/// По нажатию открывается диалог выбора файлов с поддержкой множественного выбора.
/// На данном этапе логика ограничена выбором файлов и базовой валидацией формата.
/// Поддерживаемые форматы: .xlsx (рекомендуется). Файлы .xls отмечаются предупреждением.
class MaterialsImportAction extends StatelessWidget {
  /// Конструктор действия импорта накладных.
  const MaterialsImportAction({super.key});

  /// Парсит выбранный файл через удалённый парсер и приводит результат к UI-формату.
  Future<ReceiptParseResult> _parseFile(PlatformFile f) async {
    final name = f.name;
    final bytes = f.bytes;
    if (bytes == null) {
      return ReceiptParseResult(fileName: name, error: 'Нет данных файла');
    }
    // Парсим на сервере как .xls/.xlsx — функция поддерживает оба формата
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
  Future<void> _pickFiles(BuildContext context) async {
    final logger = Logger();
    FilePickerResult? result;

    try {
      result = await FilePicker.platform.pickFiles(
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

    // Проверяем context перед использованием
    if (!context.mounted) return;

    // Показать диалог прогресса до начала тяжёлой подготовки (парсинг/сбор данных)
    // Диалог закроется автоматически после завершения парсинга
    // Не ждём результата showDialog — он вернётся только при закрытии
    // Показываем минималистичный индикатор, соответствующий стилю приложения
    // Безопасность: диалог не закрывается пользователем (barrierDismissible: false)
    // и блокирует непреднамеренные действия пока идёт подготовка предпросмотра.
    // Важно: используем rootNavigator, чтобы гарантированно закрыть верхний диалог
    // перед открытием окна предпросмотра.
    // ignore: discarded_futures
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _ParsingProgressDialog(),
    );

    // Дать кадру отрисоваться, чтобы индикатор сразу появился
    await Future<void>.delayed(const Duration(milliseconds: 16));

    final futures = <Future<ReceiptParseResult>>[];
    final Map<String, Uint8List> bytesByName = <String, Uint8List>{};
    for (final f in result.files) {
      futures.add(_parseFile(f));
      final b = f.bytes;
      if (b != null && b.isNotEmpty) {
        // Избегаем лишнего копирования, используем исходные байты
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
        return _ImportPreviewDialog(results: results, bytesByName: bytesByName);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Импорт из Excel',
      icon: const Icon(Icons.file_upload_outlined),
      onPressed: () => _pickFiles(context),
    );
  }
}

class _ImportPreviewDialog extends ConsumerStatefulWidget {
  final List<ReceiptParseResult> results;
  final Map<String, Uint8List> bytesByName;
  const _ImportPreviewDialog({
    required this.results,
    required this.bytesByName,
  });

  @override
  ConsumerState<_ImportPreviewDialog> createState() =>
      _ImportPreviewDialogState();
}

/// Немодальный диалог прогресса парсинга выбранных Excel-файлов.
class _ParsingProgressDialog extends StatelessWidget {
  const _ParsingProgressDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Подготовка предпросмотра…'),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text('Парсим файлы Excel', style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ImportPreviewDialogState extends ConsumerState<_ImportPreviewDialog> {
  bool _loading = false;
  String? _status;
  bool _checking = true;
  Map<int, bool> _existsByIdx = const {};

  @override
  void initState() {
    super.initState();
    _precheckExisting();
  }

  Future<void> _precheckExisting() async {
    setState(() {
      _checking = true;
      _existsByIdx = const {};
    });
    try {
      final client = Supabase.instance.client;
      final map = <int, bool>{};
      for (int i = 0; i < widget.results.length; i++) {
        final r = widget.results[i];
        if (r.error != null) {
          map[i] = false;
          continue;
        }
        final rn = r.receiptNumber?.trim();
        final rd = r.receiptDate;
        if (rn == null || rn.isEmpty || rd == null) {
          map[i] = false;
          continue;
        }
        final dateStr = rd.toIso8601String().split('T').first;
        try {
          final ex = await client
              .from('receipts')
              .select('id')
              .eq('receipt_number', rn)
              .eq('receipt_date', dateStr)
              .limit(1);
          map[i] = ex.isNotEmpty;
        } catch (_) {
          map[i] = false;
        }
      }
      setState(() {
        _existsByIdx = map;
      });
    } finally {
      setState(() {
        _checking = false;
      });
    }
  }

  Future<void> _doImport() async {
    setState(() {
      _loading = true;
      _status = null;
    });
    try {
      // Проверка авторизации — Storage требует authenticated
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _status = 'Ошибка: требуется авторизация для загрузки файлов.';
        });
        return;
      }
      final repo = MaterialsImportRepository(Supabase.instance.client);
      // 1) Загрузка файлов накладных в Storage
      final uploadedPaths = await _uploadAllReceiptFiles();
      // 2) Импорт строк в БД
      final summary = await repo.importViaServer(widget.results);
      // 3) Проставление file_url через Edge Function (service role)
      await _applyFileUrlsServer(uploadedPaths);
      // 4) Обновляем таблицу материалов (пагинатор)
      ref.read(materialsPagerProvider.notifier).refresh();
      ref.invalidate(materialsListProvider);
      setState(() {
        final inserted = summary['insertedRows'] ?? 0;
        final importedReceipts = summary['importedReceipts'] ?? 0;
        final skippedReceipts = summary['skippedReceipts'] ?? 0;
        _status =
            'Импортировано строк: $inserted. Импортировано накладных: $importedReceipts. Пропущено накладных: $skippedReceipts';
      });
    } catch (e) {
      setState(() {
        _status = 'Ошибка импорта: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<Map<int, String>> _uploadAllReceiptFiles() async {
    final client = Supabase.instance.client;
    final Map<int, String> paths = <int, String>{};
    final List<String> errors = <String>[];
    for (int i = 0; i < widget.results.length; i++) {
      final r = widget.results[i];
      if (r.error != null) continue;
      final rn = (r.receiptNumber ?? '').trim();
      final rd = r.receiptDate;
      if (rn.isEmpty || rd == null) continue;
      final bytes = widget.bytesByName[r.fileName];
      if (bytes == null || bytes.isEmpty) continue;
      final cn = (r.contractNumber ?? '').trim();
      final ym = "${rd.year}-${rd.month.toString().padLeft(2, '0')}";
      final ext = _extOf(r.fileName).toLowerCase();
      const bucket = 'receipts';
      final safeContract = _sanitizePathSegment(cn.isNotEmpty ? cn : 'unknown');
      // В path указываем путь внутри бакета, без префикса имени бакета
      final safeName = _sanitizePathSegment(rn);
      final path = '$safeContract/$ym/$safeName$ext';
      try {
        await client.storage
            .from(bucket)
            .uploadBinary(
              path,
              bytes,
              fileOptions: FileOptions(
                upsert: true,
                contentType: _contentTypeOf(ext),
              ),
            );
        paths[i] = path;
      } catch (e) {
        errors.add('Не удалось загрузить файл ${r.fileName} (№$rn): $e');
      }
    }
    if (errors.isNotEmpty) {
      setState(() {
        _status = ([_status, ...errors]).whereType<String>().join('\n');
      });
    }
    return paths;
  }

  Future<void> _applyFileUrlsServer(Map<int, String> uploadedPaths) async {
    if (uploadedPaths.isEmpty) return;
    final client = Supabase.instance.client;
    final List<String> errors = <String>[];
    for (final entry in uploadedPaths.entries) {
      final idx = entry.key;
      final storagePath = entry.value;
      final r = widget.results[idx];
      final rn = (r.receiptNumber ?? '').trim();
      final rd = r.receiptDate;
      if (rn.isEmpty || rd == null) continue;
      final dateStr = rd.toIso8601String().split('T').first;
      final cn = (r.contractNumber ?? '').trim();
      try {
        final res = await client.functions.invoke(
          'receipts-attach-fileurl',
          body: {
            'receiptNumber': rn,
            'receiptDate': dateStr,
            'contractNumber': cn.isNotEmpty ? cn : null,
            'storagePath': storagePath,
          },
        );
        if (res.data is Map && res.data['error'] != null) {
          errors.add(
            'Не удалось проставить file_url для №$rn: ${res.data['error']}',
          );
        }
      } catch (e) {
        errors.add('Не удалось проставить file_url для №$rn: $e');
      }
    }
    if (errors.isNotEmpty) {
      setState(() {
        _status = ([_status, ...errors]).whereType<String>().join('\n');
      });
    }
  }

  String _extOf(String fileName) {
    final i = fileName.lastIndexOf('.');
    if (i <= 0 || i == fileName.length - 1) return '';
    return fileName.substring(i).toLowerCase();
  }

  String _sanitizePathSegment(String s) {
    // Разрешаем латиницу/цифры/точку/тире/нижнее подчёркивание, остальное → _
    // ignore: deprecated_member_use
    return s.replaceAll(RegExp(r"[^A-Za-z0-9._-]+"), '_');
  }

  String _contentTypeOf(String ext) {
    switch (ext) {
      case '.xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case '.xls':
        return 'application/vnd.ms-excel';
      case '.pdf':
        return 'application/pdf';
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: DesktopDialogContent(
        title: 'Предпросмотр импорта',
        width: 720,
        footer: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GTSecondaryButton(
              onPressed: _loading ? null : () => Navigator.of(context).pop(),
              text: 'Закрыть',
            ),
            const SizedBox(width: 16),
            GTPrimaryButton(
              onPressed: _loading ? null : _doImport,
              isLoading: _loading,
              text: 'Импортировать в БД',
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_checking)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Проверка существующих накладных...'),
                  ],
                ),
              ),
            ..._sortedIndices().map((i) {
              final r = widget.results[i];
              final already = _existsByIdx[i] == true;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _ResultTile(result: r, alreadyImported: already),
              );
            }),
            if (_status != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_status!, style: theme.textTheme.bodySmall),
              ),
          ],
        ),
      ),
    );
  }

  List<int> _sortedIndices() {
    final idxs = List<int>.generate(widget.results.length, (i) => i);
    idxs.sort((a, b) {
      final ea = _existsByIdx[a] == true ? 1 : 0;
      final eb = _existsByIdx[b] == true ? 1 : 0;
      if (ea != eb) {
        return ea.compareTo(eb); // новые выше, уже импортированные ниже
      }
      final da = widget.results[a].receiptDate;
      final db = widget.results[b].receiptDate;
      if (da != null && db != null) {
        return db.compareTo(da); // по дате, новые сверху
      }
      return widget.results[a].fileName.compareTo(widget.results[b].fileName);
    });
    return idxs;
  }
}

class _ResultTile extends StatelessWidget {
  final ReceiptParseResult result;
  final bool alreadyImported;
  const _ResultTile({required this.result, this.alreadyImported = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (result.error != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.error.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.error.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.fileName, style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(
              result.error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(result.fileName, style: theme.textTheme.titleSmall),
              ),
              if (alreadyImported)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    'Уже импортирована',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.blue,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Накладная № ${result.receiptNumber ?? '-'} от '
            '${result.receiptDate != null ? formatRuDate(result.receiptDate!) : '-'} '
            'года. Кол-во позиций - ${result.items.length}',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
