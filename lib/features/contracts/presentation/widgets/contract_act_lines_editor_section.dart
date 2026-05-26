import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/widgets/gt_confirmation_dialog.dart';
import 'package:projectgt/domain/entities/contract_act_line.dart';
import 'package:projectgt/features/contracts/presentation/providers/contract_act_providers.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_act_ks2_summary_scope.dart';
import 'package:projectgt/features/contracts/presentation/widgets/ks2_act_lines_table.dart';

/// Таблица строк сохранённого акта КС-2 (`contract_act_lines`) с правкой количества.
class ContractActLinesEditorSection extends ConsumerStatefulWidget {
  /// Создаёт секцию редактора строк акта.
  const ContractActLinesEditorSection({
    super.key,
    required this.actId,
    this.editable = true,
  });

  /// Идентификатор акта.
  final String actId;

  /// Разрешить редактирование количества.
  final bool editable;

  @override
  ConsumerState<ContractActLinesEditorSection> createState() =>
      ContractActLinesEditorSectionState();
}

/// Состояние [ContractActLinesEditorSection] (для [GlobalKey] при сохранении).
class ContractActLinesEditorSectionState
    extends ConsumerState<ContractActLinesEditorSection> {
  final Map<String, TextEditingController> _qtyControllers = {};
  final Map<String, ContractActLine> _linesById = {};
  final Map<String, double> _baselineQtyById = {};
  final Set<String> _deletedLineIds = {};
  final Set<String> _invalidQtyIds = {};
  final Set<String> _modifiedQtyIds = {};
  bool _controllersReady = false;
  Timer? _qtyRebuildDebounce;

  @override
  void dispose() {
    _qtyRebuildDebounce?.cancel();
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    _qtyControllers.clear();
    _linesById.clear();
    _baselineQtyById.clear();
    _deletedLineIds.clear();
    _invalidQtyIds.clear();
    _modifiedQtyIds.clear();
    _controllersReady = false;
  }

  void _ensureControllers(List<ContractActLine> lines) {
    if (_controllersReady) return;
    for (final line in lines) {
      _linesById[line.id] = line;
      _baselineQtyById[line.id] = line.quantity;
      _qtyControllers[line.id] = TextEditingController(
        text: Ks2ActLinesTable.formatQtyInput(line.quantity),
      );
    }
    _controllersReady = true;
  }

  /// Количество по каждой строке для сохранения в БД.
  ///
  /// Бросает [FormatException], если в ячейке не число.
  /// Идентификаторы строк, отмеченных на удаление (применятся по кнопке «Сохранить»).
  Set<String> buildDeletedLineIds() => Set<String>.from(_deletedLineIds);

  /// Количество по каждой видимой строке для сохранения в БД.
  ///
  /// Бросает [FormatException], если в ячейке не число.
  Map<String, double> buildQuantitiesByLineId() {
    final result = <String, double>{};
    for (final entry in _qtyControllers.entries) {
      if (_deletedLineIds.contains(entry.key)) continue;
      final parsed = Ks2ActLinesTable.parseQty(entry.value.text);
      if (parsed == null) {
        final line = _linesById[entry.key];
        final label = line?.name ?? entry.key;
        throw FormatException('Укажите количество: $label');
      }
      result[entry.key] = parsed;
    }
    return result;
  }

  List<ContractActLine> _visibleLines(List<ContractActLine> lines) {
    return lines.where((l) => !_deletedLineIds.contains(l.id)).toList();
  }

  Future<void> _confirmDeleteLine(BuildContext context, Ks2ActLineRow row) async {
    final line = _linesById[row.rowKey];
    if (line == null) return;

    final confirmed = await GTConfirmationDialog.show(
      context: context,
      title: 'Удалить строку из акта?',
      message:
          'Позиция исчезнет из акта после сохранения. Excel нужно будет сформировать заново.',
      emphasisText: line.name,
      detail: line.sectionTitle.trim().isEmpty ? null : line.sectionTitle,
      confirmText: 'Удалить',
      cancelText: 'Отмена',
      type: GTConfirmationType.danger,
    );
    if (confirmed == true && mounted) {
      setState(() => _deletedLineIds.add(line.id));
    }
  }

  void _recomputeRowFlags() {
    _invalidQtyIds.clear();
    _modifiedQtyIds.clear();
    for (final entry in _qtyControllers.entries) {
      if (_deletedLineIds.contains(entry.key)) continue;
      final parsed = Ks2ActLinesTable.parseQty(entry.value.text);
      if (parsed == null) {
        _invalidQtyIds.add(entry.key);
        continue;
      }
      final baseline = _baselineQtyById[entry.key];
      if (baseline != null && (parsed - baseline).abs() > 1e-9) {
        _modifiedQtyIds.add(entry.key);
      }
    }
  }

  void _onQtyChanged() {
    _recomputeRowFlags();
    _qtyRebuildDebounce?.cancel();
    _qtyRebuildDebounce = Timer(const Duration(milliseconds: 120), () {
      if (mounted) setState(() {});
    });
  }

  void _onQtyBlur(Ks2ActLineRow row) {
    _recomputeRowFlags();
    setState(() {});
  }

  double _computeTotalAmount() {
    var sum = 0.0;
    for (final entry in _qtyControllers.entries) {
      if (_deletedLineIds.contains(entry.key)) continue;
      final line = _linesById[entry.key];
      if (line == null) continue;
      final q = Ks2ActLinesTable.parseQty(entry.value.text) ?? line.quantity;
      sum += q * line.price;
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final linesAsync = ref.watch(contractActLinesProvider(widget.actId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: linesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text(
              'Не удалось загрузить строки акта: $e',
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error),
            ),
            data: (lines) {
              if (lines.isEmpty) {
                return Text(
                  'В акте нет строк — создайте акт заново или заполните строки в БД.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.7),
                  ),
                );
              }
              _ensureControllers(lines);
              final visible = _visibleLines(lines);
              if (visible.isEmpty) {
                return Text(
                  _deletedLineIds.isEmpty
                      ? 'В акте нет строк.'
                      : 'Все строки отмечены на удаление — нажмите «Сохранить» или '
                          'перезагрузите форму.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.7),
                  ),
                );
              }

              final tableRows =
                  visible.map(ks2ActLineRowFromContractActLine).toList();

              final lineTotal = _computeTotalAmount();
              final summaryScope = ContractActKs2SummaryScope.maybeOf(context);
              final financialFooter =
                  summaryScope?.footerFromLineTotal(lineTotal);

              return Ks2ActLinesTable(
                rows: tableRows,
                totalAmount: financialFooter?.amount ?? lineTotal,
                financialFooter: financialFooter,
                edit: widget.editable
                    ? Ks2ActLinesTableEditConfig(
                        qtyControllers: _qtyControllers,
                        onQtyChanged: _onQtyChanged,
                        onQtyBlur: _onQtyBlur,
                        onDelete: (row) => _confirmDeleteLine(context, row),
                        invalidRowKeys: _invalidQtyIds,
                        modifiedRowKeys: _modifiedQtyIds,
                      )
                    : null,
                emptyMessage: 'В акте нет строк.',
              );
            },
          ),
        ),
      ],
    );
  }
}
