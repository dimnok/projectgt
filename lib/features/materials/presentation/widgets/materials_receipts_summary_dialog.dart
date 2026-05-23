import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/desktop_dialog_content.dart';
import '../../../../core/widgets/mobile_atmosphere_backdrop.dart';
import '../../../../core/widgets/mobile_atmosphere_screen_header.dart';
import '../../data/models/materials_receipts_summary.dart';
import '../providers/materials_context_providers.dart';
import '../providers/materials_providers.dart';

/// Кнопка открытия сводки по накладным (шапка экрана «Материалы»).
class MaterialsReceiptsSummaryAction extends ConsumerWidget {
  /// Создаёт кнопку сводки по накладным.
  const MaterialsReceiptsSummaryAction({
    super.key,
    required this.appearance,
  });

  /// Оформление атмосферы экрана.
  final MobileAtmosphereAppearance appearance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MobileAtmosphereChromeCircleButton(
      appearance: appearance,
      tooltip: 'Сводка по накладным',
      icon: Icons.receipt_long_outlined,
      onTap: () => _openSummary(context, ref),
    );
  }

  Future<void> _openSummary(BuildContext context, WidgetRef ref) async {
    final contractNumber = ref.read(selectedContractNumberProvider);
    if (!hasMaterialsContractSelection(contractNumber)) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => MaterialsReceiptsSummaryDialog(
        contractNumber: contractNumber!.trim(),
      ),
    );
  }
}

/// Диалог со сводкой по накладным выбранного договора.
class MaterialsReceiptsSummaryDialog extends ConsumerWidget {
  /// Создаёт диалог сводки.
  const MaterialsReceiptsSummaryDialog({
    super.key,
    required this.contractNumber,
  });

  /// Номер договора для фильтрации.
  final String contractNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(
      materialsReceiptsSummaryProvider(contractNumber),
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: DesktopDialogContent(
        title: 'Накладные · договор $contractNumber',
        width: 900,
        child: summaryAsync.when(
          data: (summary) => _SummaryBody(summary: summary),
          loading: () => const SizedBox(
            height: 240,
            child: Center(child: CupertinoActivityIndicator()),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(24),
            child: SelectableText.rich(
              TextSpan(
                text: 'Не удалось загрузить сводку: ',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                children: [TextSpan(text: '$error')],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryBody extends StatelessWidget {
  const _SummaryBody({required this.summary});

  final MaterialsReceiptsSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (summary.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('Накладные по этому договору не найдены')),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SummaryHeader(summary: summary),
        const SizedBox(height: 16),
        Text(
          'Список накладных',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < summary.items.length; i++) ...[
          if (i > 0) const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              _formatReceiptLine(summary.items[i]),
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ],
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.summary});

  final MaterialsReceiptsSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Накладных: ${summary.receiptCount}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Общая сумма: ${formatCurrency(summary.grandTotal)}',
            style: theme.textTheme.titleSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatReceiptLine(MaterialsReceiptSummaryItem item) {
  final datePart = item.receiptDate != null
      ? ' от ${formatRuDate(item.receiptDate!)} г.'
      : '';
  return 'Накладная №${item.receiptNumber}$datePart '
      '(${_positionsLabel(item.positionCount)}) '
      'сумма накладной — ${formatCurrency(item.totalAmount)}';
}

String _positionsLabel(int count) {
  final mod10 = count % 10;
  final mod100 = count % 100;
  if (mod100 >= 11 && mod100 <= 14) return '$count позиций';
  if (mod10 == 1) return '$count позиция';
  if (mod10 >= 2 && mod10 <= 4) return '$count позиции';
  return '$count позиций';
}
