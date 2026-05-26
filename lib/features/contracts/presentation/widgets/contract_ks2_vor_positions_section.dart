import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/domain/entities/contract_act_ks2_preview.dart';
import 'package:projectgt/domain/entities/vor.dart';
import 'package:projectgt/core/utils/supabase_function_error.dart';
import 'package:projectgt/features/contracts/presentation/providers/contract_act_ks2_providers.dart';
import 'package:projectgt/features/contracts/presentation/widgets/contract_act_ks2_summary_scope.dart';
import 'package:projectgt/features/contracts/presentation/widgets/ks2_act_lines_table.dart';

/// Таблица позиций КС-2 по выбранной утверждённой ВОР (данные превью `ks2_operations`).
///
/// Используется в форме «Акт КС-2» в модуле «Договоры»; не тянет провайдеры модуля «Сметы».
class ContractKs2VorPositionsSection extends ConsumerStatefulWidget {
  /// Создаёт секцию таблицы по ВОР.
  const ContractKs2VorPositionsSection({
    super.key,
    required this.contractId,
    this.onPreviewUpdated,
  });

  /// Идентификатор договора.
  final String contractId;

  /// Вызывается после загрузки или сброса превью (для пересчёта удержаний в шапке).
  final VoidCallback? onPreviewUpdated;

  @override
  ConsumerState<ContractKs2VorPositionsSection> createState() =>
      ContractKs2VorPositionsSectionState();
}

/// Состояние [ContractKs2VorPositionsSection] (для [GlobalKey] при выгрузке Excel).
class ContractKs2VorPositionsSectionState
    extends ConsumerState<ContractKs2VorPositionsSection> {
  Vor? _selectedVor;
  ContractActKs2Preview? _preview;
  bool _loading = false;
  String? _error;

  /// Выбранная утверждённая ВОР (`null`, если не выбрана).
  String? get selectedVorId => _selectedVor?.id;

  /// Сумма строк превью по выбранной ВОР (без НДС), если превью загружено.
  double? get previewLineTotal => _preview?.totalAmount;

  Future<void> _loadPreview(String vorId) async {
    setState(() {
      _loading = true;
      _error = null;
      _preview = null;
    });
    try {
      final repo = ref.read(contractActRepositoryProvider);
      final data = await repo.previewKs2(
        contractId: widget.contractId,
        vorId: vorId,
      );
      if (!mounted) return;
      setState(() {
        _preview = data;
        _loading = false;
      });
      widget.onPreviewUpdated?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = formatInvokeErrorMessage(e);
        _loading = false;
        _preview = null;
      });
      widget.onPreviewUpdated?.call();
    }
  }

  void _onVorChanged(Vor? vor) {
    setState(() {
      _selectedVor = vor;
      _preview = null;
      _error = null;
    });
    widget.onPreviewUpdated?.call();
    if (vor != null) {
      unawaited(_loadPreview(vor.id));
    }
  }

  List<Ks2ActLineRow> _rowsFromPreview(ContractActKs2Preview preview) {
    final rows = <Ks2ActLineRow>[];
    var index = 0;
    for (final c in preview.candidates) {
      final m = Map<String, dynamic>.from(c as Map);
      final sectionTitle = '${m['sectionTitle'] ?? ''}'.trim();
      final estimateNumber = '${m['estimateNumber'] ?? ''}'.trim();
      rows.add(
        Ks2ActLineRow(
          rowKey: 'preview_${index++}',
          sectionTitle: sectionTitle,
          estimateNumber: estimateNumber.isEmpty ? '—' : estimateNumber,
          name: ks2ActLineDisplayName((m['name'] ?? '—').toString()),
          unit: (m['unit'] ?? '—').toString(),
          quantity: (m['quantity'] as num?)?.toDouble() ?? 0,
          price: (m['price'] as num?)?.toDouble() ?? 0,
          amount: (m['amount'] as num?)?.toDouble() ?? 0,
        ),
      );
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final vorsAsync = ref.watch(
      contractActApprovedVorsProvider(widget.contractId),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: vorsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Text(
              'Не удалось загрузить ВОР: $e',
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error),
            ),
            data: (approved) {
              if (_selectedVor != null &&
                  !approved.any((v) => v.id == _selectedVor!.id)) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  setState(() {
                    _selectedVor = null;
                    _preview = null;
                  });
                });
              }
              if (approved.isEmpty) {
                return Text(
                  'Нет утверждённых ВОР без сохранённого акта КС-2 по этому договору.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.7),
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: GTDropdown<Vor>(
                          items: approved,
                          itemDisplayBuilder: (v) =>
                              'ВОР №${v.number} (${formatRuDate(v.startDate)} — ${formatRuDate(v.endDate)})',
                          labelText: 'Ведомость ВОР',
                          hintText: 'Выберите ВОР',
                          selectedItem: _selectedVor,
                          onSelectionChanged: _onVorChanged,
                          prefixIcon: CupertinoIcons.doc_text,
                          allowClear: true,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Tooltip(
                          message:
                              'Первый акт — объёмы по смете ВОР. Следующие — период и перенос '
                              'превышения в пределах лимита сметы.',
                          child: Icon(
                            CupertinoIcons.info_circle,
                            size: 18,
                            color: scheme.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_loading) ...[
                    const SizedBox(height: 16),
                    const Center(child: CircularProgressIndicator()),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.error,
                      ),
                    ),
                  ],
                  if (!_loading && _preview != null) ...[
                    const SizedBox(height: 12),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final lineTotal = _preview!.totalAmount;
                          final summaryScope =
                              ContractActKs2SummaryScope.maybeOf(context);
                          final financialFooter =
                              summaryScope?.footerFromLineTotal(lineTotal);
                          return Ks2ActLinesTable(
                            rows: _rowsFromPreview(_preview!),
                            totalAmount: financialFooter?.amount ?? lineTotal,
                            financialFooter: financialFooter,
                            emptyMessage:
                            'Нет строк для акта (лимит сметы исчерпан, превышение без '
                            'переноса или нет привязки к смете).',
                          );
                        },
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
