import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/desktop_dialog_content.dart';
import '../../../../core/widgets/gt_buttons.dart';
import '../../../../features/company/presentation/providers/company_providers.dart';
import '../../data/parsers/receipts_remote_parser.dart';
import '../../data/repositories/materials_import_repository.dart';
import '../providers/materials_providers.dart';
import '../providers/materials_pager.dart';
import '../utils/receipt_contract_match.dart';

/// Диалог предпросмотра импорта накладных с проверкой договора.
class MaterialsImportPreviewDialog extends ConsumerStatefulWidget {
  /// Создаёт диалог предпросмотра.
  const MaterialsImportPreviewDialog({
    super.key,
    required this.results,
    required this.bytesByName,
    required this.selectedContractNumber,
  });

  /// Результаты парсинга выбранных файлов.
  final List<ReceiptParseResult> results;

  /// Байты файлов по имени.
  final Map<String, Uint8List> bytesByName;

  /// Договор, выбранный на экране материалов.
  final String selectedContractNumber;

  @override
  ConsumerState<MaterialsImportPreviewDialog> createState() =>
      _MaterialsImportPreviewDialogState();
}

/// Индикатор парсинга Excel перед предпросмотром.
class MaterialsImportParsingProgressDialog extends StatelessWidget {
  /// Создаёт диалог прогресса.
  const MaterialsImportParsingProgressDialog({super.key});

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

class _MaterialsImportPreviewDialogState
    extends ConsumerState<MaterialsImportPreviewDialog> {
  bool _loading = false;
  String? _status;
  bool _checking = true;
  Map<int, bool> _existsByIdx = const {};
  late Map<int, ReceiptContractMatchStatus> _contractStatusByIdx;

  @override
  void initState() {
    super.initState();
    _contractStatusByIdx = _buildContractStatuses();
    _precheckExisting();
  }

  Map<int, ReceiptContractMatchStatus> _buildContractStatuses() {
    final map = <int, ReceiptContractMatchStatus>{};
    for (var i = 0; i < widget.results.length; i++) {
      final r = widget.results[i];
      map[i] = evaluateReceiptContractMatch(
        fileContractNumber: r.contractNumber,
        selectedContractNumber: widget.selectedContractNumber,
        hasParseError: r.error != null,
      );
    }
    return map;
  }

  List<int> get _mismatchIndices {
    return List<int>.generate(widget.results.length, (i) => i)
        .where(
          (i) => isReceiptContractMismatch(_contractStatusByIdx[i] ?? 
              ReceiptContractMatchStatus.skipped),
        )
        .toList();
  }

  /// Накладные, допустимые к импорту (договор совпадает, файл распознан).
  List<int> get _importableIndices {
    return List<int>.generate(widget.results.length, (i) => i).where((i) {
      final r = widget.results[i];
      if (r.error != null) return false;
      final rn = r.receiptNumber?.trim();
      if (rn == null || rn.isEmpty || r.receiptDate == null) return false;
      return _contractStatusByIdx[i] == ReceiptContractMatchStatus.match;
    }).toList();
  }

  List<ReceiptParseResult> get _resultsToImport {
    return _importableIndices.map((i) => widget.results[i]).toList();
  }

  Future<void> _precheckExisting() async {
    setState(() {
      _checking = true;
      _existsByIdx = const {};
    });
    try {
      final client = Supabase.instance.client;
      final activeId = ref.read(activeCompanyIdProvider);
      if (activeId == null) return;

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
        final dateStr = GtFormatters.formatDateForApi(rd);
        try {
          final ex = await client
              .from('receipts')
              .select('id')
              .eq('receipt_number', rn)
              .eq('receipt_date', dateStr)
              .eq('company_id', activeId)
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

  String _receiptSummaryLine(int index) {
    final r = widget.results[index];
    final rn = r.receiptNumber?.trim();
    final rd = r.receiptDate;
    final datePart = rd != null ? formatRuDate(rd) : '—';
    final numPart = rn != null && rn.isNotEmpty ? '№ $rn' : 'без номера';
    final fileContract = r.contractNumber?.trim();
    final contractPart = fileContract != null && fileContract.isNotEmpty
        ? '«$fileContract»'
        : 'не указан';
    return '• $numPart от $datePart — в файле: $contractPart';
  }

  Future<void> _onImportPressed() async {
    await _doImport();
  }

  Future<void> _doImport() async {
    setState(() {
      _loading = true;
      _status = null;
    });
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      final activeId = ref.read(activeCompanyIdProvider);

      if (user == null || activeId == null) {
        setState(() {
          _status = 'Ошибка: требуется авторизация и выбор компании.';
        });
        return;
      }

      final toImport = _resultsToImport;
      if (toImport.isEmpty) {
        setState(() {
          _status =
              'Импорт невозможен: ни в одном файле договор не совпадает с выбранным.';
        });
        return;
      }

      final repo = MaterialsImportRepository(client);
      final uploadedPaths = await _uploadAllReceiptFiles();
      final summary = await repo.importViaServer(
        results: toImport,
        companyId: activeId,
        importContractNumber: widget.selectedContractNumber,
      );
      await _applyFileUrlsServer(uploadedPaths, activeId);
      ref.read(materialsPagerProvider.notifier).refresh();
      ref.invalidate(materialsListProvider);

      final skippedByContract = _mismatchIndices.length;
      setState(() {
        final inserted = summary['insertedRows'] ?? 0;
        final importedReceipts = summary['importedReceipts'] ?? 0;
        final skippedReceipts = summary['skippedReceipts'] ?? 0;
        final parts = <String>[
          'Импортировано строк: $inserted',
          'накладных: $importedReceipts',
          'пропущено (дубликаты): $skippedReceipts',
        ];
        if (skippedByContract > 0) {
          parts.add(
            'не импортировано из‑за договора: $skippedByContract',
          );
        }
        _status = parts.join('. ');
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
    for (final i in _importableIndices) {
      final r = widget.results[i];
      final rn = (r.receiptNumber ?? '').trim();
      final rd = r.receiptDate;
      if (rn.isEmpty || rd == null) continue;
      final bytes = widget.bytesByName[r.fileName];
      if (bytes == null || bytes.isEmpty) continue;
      final ym = "${rd.year}-${rd.month.toString().padLeft(2, '0')}";
      final ext = _extOf(r.fileName).toLowerCase();
      const bucket = 'receipts';
      final safeContract =
          _sanitizePathSegment(widget.selectedContractNumber);
      final safeName = _sanitizePathSegment(rn);
      final path = '$safeContract/$ym/$safeName$ext';
      try {
        await client.storage.from(bucket).uploadBinary(
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

  Future<void> _applyFileUrlsServer(
    Map<int, String> uploadedPaths,
    String companyId,
  ) async {
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
      final dateStr = GtFormatters.formatDateForApi(rd);
      try {
        final res = await client.functions.invoke(
          'receipts-attach-fileurl',
          body: {
            'receiptNumber': rn,
            'receiptDate': dateStr,
            'contractNumber': widget.selectedContractNumber,
            'storagePath': storagePath,
            'companyId': companyId,
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

  int _sortRank(int index) {
    final r = widget.results[index];
    if (r.error != null) return 0;
    final contractStatus =
        _contractStatusByIdx[index] ?? ReceiptContractMatchStatus.skipped;
    if (isReceiptContractMismatch(contractStatus)) return 1;
    if (_existsByIdx[index] == true) return 3;
    return 2;
  }

  List<int> _sortedIndices() {
    final idxs = List<int>.generate(widget.results.length, (i) => i);
    idxs.sort((a, b) {
      final ra = _sortRank(a);
      final rb = _sortRank(b);
      if (ra != rb) return ra.compareTo(rb);
      final da = widget.results[a].receiptDate;
      final db = widget.results[b].receiptDate;
      if (da != null && db != null) {
        return db.compareTo(da);
      }
      return widget.results[a].fileName.compareTo(widget.results[b].fileName);
    });
    return idxs;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mismatches = _mismatchIndices;
    final importableCount = _importableIndices.length;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: DesktopDialogContent(
        title: 'Предпросмотр импорта',
        width: 920,
        footer: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GTSecondaryButton(
              onPressed: _loading ? null : () => Navigator.of(context).pop(),
              text: 'Закрыть',
            ),
            const SizedBox(width: 16),
            GTPrimaryButton(
              onPressed: _loading || importableCount == 0
                  ? null
                  : _onImportPressed,
              isLoading: _loading,
              text: importableCount == 0
                  ? 'Нет накладных для импорта'
                  : mismatches.isNotEmpty
                      ? 'Импортировать совпадающие ($importableCount)'
                      : 'Импортировать в БД',
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ImportContextBanner(
              selectedContractNumber: widget.selectedContractNumber,
            ),
            if (mismatches.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ContractMismatchWarningPanel(
                  selectedContractNumber: widget.selectedContractNumber,
                  mismatchIndices: mismatches,
                  receiptSummaryBuilder: _receiptSummaryLine,
                ),
              ),
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
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _ImportResultTile(
                  result: r,
                  alreadyImported: _existsByIdx[i] == true,
                  contractStatus: _contractStatusByIdx[i] ??
                      ReceiptContractMatchStatus.skipped,
                  selectedContractNumber: widget.selectedContractNumber,
                ),
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
}

class _ImportContextBanner extends StatelessWidget {
  const _ImportContextBanner({required this.selectedContractNumber});

  final String selectedContractNumber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        'Контекст импорта: договор «$selectedContractNumber»',
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ContractMismatchWarningPanel extends StatelessWidget {
  const _ContractMismatchWarningPanel({
    required this.selectedContractNumber,
    required this.mismatchIndices,
    required this.receiptSummaryBuilder,
  });

  final String selectedContractNumber;
  final List<int> mismatchIndices;
  final String Function(int index) receiptSummaryBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = mismatchIndices.length;
    final noun = count == 1 ? 'накладной' : 'накладных';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.amber.shade800,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Договор в $count $noun не совпадает с выбранным '
                  '«$selectedContractNumber» — эти файлы не будут импортированы',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.amber.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...mismatchIndices.map(
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                receiptSummaryBuilder(i),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.amber.shade900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportResultTile extends StatelessWidget {
  const _ImportResultTile({
    required this.result,
    required this.alreadyImported,
    required this.contractStatus,
    required this.selectedContractNumber,
  });

  final ReceiptParseResult result;
  final bool alreadyImported;
  final ReceiptContractMatchStatus contractStatus;
  final String selectedContractNumber;

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

    final contractMismatch = isReceiptContractMismatch(contractStatus);

    Color borderColor = theme.colorScheme.outline.withValues(alpha: 0.2);
    Color? backgroundColor = theme.colorScheme.surface;
    if (contractMismatch) {
      borderColor = Colors.amber.withValues(alpha: 0.55);
      backgroundColor = Colors.amber.withValues(alpha: 0.06);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
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
                const _StatusChip(
                  label: 'Уже импортирована',
                  color: Colors.blue,
                ),
              if (!alreadyImported &&
                  contractStatus == ReceiptContractMatchStatus.match)
                const _StatusChip(
                  label: 'Договор совпадает',
                  color: Colors.green,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Накладная № ${result.receiptNumber ?? '-'} от '
            '${result.receiptDate != null ? formatRuDate(result.receiptDate!) : '-'} '
            '· позиций: ${result.items.length}',
            style: theme.textTheme.bodyMedium,
          ),
          if (contractMismatch) ...[
            const SizedBox(height: 6),
            const SizedBox(height: 6),
            Text(
              contractStatus == ReceiptContractMatchStatus.missingInFile
                  ? 'В накладной не указан договор. Выбран «$selectedContractNumber».'
                  : 'Не совпадает с выбранным «$selectedContractNumber».',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.amber.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
