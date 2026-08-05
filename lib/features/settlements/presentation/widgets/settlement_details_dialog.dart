import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_confirmation_dialog.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';
import 'package:projectgt/features/settlements/domain/entities/settlement_operation.dart';
import 'package:projectgt/features/settlements/domain/entities/settlement_payment.dart';
import 'package:projectgt/features/settlements/presentation/state/settlement_state.dart';
import 'package:projectgt/features/settlements/presentation/utils/settlement_actions.dart';
import 'package:projectgt/features/settlements/presentation/utils/settlement_ui_labels.dart';
import 'package:projectgt/features/settlements/presentation/widgets/settlement_form_dialog.dart';
import 'package:projectgt/features/settlements/presentation/widgets/settlement_payment_form_dialog.dart';

/// Окно деталей счёта с историей оплат.
class SettlementDetailsDialog extends ConsumerStatefulWidget {
  /// Операция (счёт).
  final SettlementOperation operation;

  /// Предзаполненный договор (вкладка «Финансы»).
  final Contract? presetContract;

  /// Создаёт диалог.
  const SettlementDetailsDialog({
    super.key,
    required this.operation,
    this.presetContract,
  });

  /// Показать диалог / bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required SettlementOperation operation,
    Contract? presetContract,
  }) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final child = SettlementDetailsDialog(
      operation: operation,
      presetContract: presetContract,
    );
    if (isDesktop) {
      return showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: child,
        ),
      );
    }
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => child,
    );
  }

  @override
  ConsumerState<SettlementDetailsDialog> createState() =>
      _SettlementDetailsDialogState();
}

class _SettlementDetailsDialogState
    extends ConsumerState<SettlementDetailsDialog> {
  late SettlementOperation _operation;

  @override
  void initState() {
    super.initState();
    _operation = widget.operation;
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshOperation());
  }

  Future<void> _refreshOperation() async {
    final fresh = await ref
        .read(settlementRepositoryProvider)
        .getOperation(_operation.id);
    if (!mounted || fresh == null) return;
    setState(() => _operation = fresh);
  }

  Future<void> _syncAfterPaymentChange() async {
    await ref
        .read(settlementPaymentsProvider(_operation.id).notifier)
        .load(quiet: true);
    await _refreshOperation();
    syncSettlementProviders(ref, contractId: _operation.contractId);
  }

  Future<void> _openEdit() async {
    await SettlementFormDialog.show(
      context,
      operation: _operation,
      presetContract: widget.presetContract,
    );
    if (!mounted) return;
    await _refreshOperation();
    syncSettlementProviders(ref, contractId: _operation.contractId);
  }

  Future<void> _deleteInvoice() async {
    final ok = await showSettlementDeleteConfirmDialog(context, _operation);
    if (ok != true || !mounted) return;

    final notifier = widget.presetContract != null
        ? ref.read(
            contractSettlementsProvider(widget.presetContract!.id).notifier,
          )
        : ref.read(settlementListProvider.notifier);

    final success = await notifier.delete(_operation.id);
    if (!mounted) return;
    syncSettlementProviders(ref, contractId: _operation.contractId);
    if (success) {
      Navigator.of(context).pop();
    }
    AppSnackBar.show(
      context: context,
      message: success ? 'Счёт удалён' : 'Не удалось удалить',
      kind: success ? AppSnackBarKind.success : AppSnackBarKind.error,
    );
  }

  Future<void> _addPayment() async {
    final saved = await SettlementPaymentFormDialog.show(
      context,
      settlementOperationId: _operation.id,
    );
    if (saved == true) await _syncAfterPaymentChange();
  }

  Future<void> _editPayment(SettlementPayment payment) async {
    final saved = await SettlementPaymentFormDialog.show(
      context,
      settlementOperationId: _operation.id,
      payment: payment,
    );
    if (saved == true) await _syncAfterPaymentChange();
  }

  Future<void> _deletePayment(SettlementPayment payment) async {
    final ok = await GTConfirmationDialog.show(
      context: context,
      title: 'Удалить оплату?',
      message:
          'Оплата ${formatCurrency(payment.amount)} от ${formatRuDate(payment.paymentDate)} будет удалена.',
      confirmText: 'Удалить',
      type: GTConfirmationType.danger,
    );
    if (ok != true || !mounted) return;

    final success = await ref
        .read(settlementPaymentsProvider(_operation.id).notifier)
        .delete(payment.id);
    if (!mounted) return;
    if (success) {
      await _syncAfterPaymentChange();
    }
    if (!mounted) return;
    AppSnackBar.show(
      context: context,
      message: success ? 'Оплата удалена' : 'Не удалось удалить',
      kind: success ? AppSnackBarKind.success : AppSnackBarKind.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final paymentsState = ref.watch(settlementPaymentsProvider(_operation.id));
    final canUpdate =
        ref.watch(permissionServiceProvider).can('settlements', 'update');
    final canDelete =
        ref.watch(permissionServiceProvider).can('settlements', 'delete');

    final status = _operation.resolvedPaymentStatus;
    final statusColor = settlementPaymentStatusColor(theme, status);
    final totalToPay = _operation.totalToPay;
    final paidAmount = _operation.paidAmount;
    final remaining = _operation.remainingAmount;

    final title = 'Счёт ${_operation.invoiceNumber}';

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (canUpdate)
              GTTextButton(
                text: 'Редактировать',
                onPressed: _openEdit,
              ),
            if (canDelete)
              GTTextButton(
                text: 'Удалить',
                onPressed: _deleteInvoice,
              ),
          ],
        ),
        const SizedBox(height: 8),
        _SummaryStrip(
          totalToPay: totalToPay,
          paidAmount: paidAmount,
          remaining: remaining,
          statusLabel: settlementPaymentStatusLabel(status),
          statusColor: statusColor,
        ),
        const SizedBox(height: 16),
        _InfoSection(
          title: 'Реквизиты',
          children: [
            _InfoRow(label: 'Дата счёта', value: formatRuDate(_operation.invoiceDate)),
            _InfoRow(
              label: 'Тип',
              value: settlementOperationTypeLabel(_operation.operationType),
            ),
            if (_operation.actNumber != null &&
                _operation.actNumber!.isNotEmpty)
              _InfoRow(label: 'Акт', value: _operation.actNumber!),
            _InfoRow(
              label: 'Договор',
              value: _operation.contractNumber ?? '—',
            ),
            _InfoRow(
              label: 'Контрагент',
              value: _operation.contractorName ?? '—',
            ),
            _InfoRow(
              label: 'Объект',
              value: _operation.objectName ?? '—',
            ),
            _InfoRow(
              label: 'Сумма без НДС',
              value: formatCurrency(_operation.amount),
            ),
            if (_operation.vatRate != null && _operation.vatRate! > 0) ...[
              _InfoRow(
                label: 'НДС (${formatQuantity(_operation.vatRate!)}%)',
                value: formatCurrency(_operation.vatAmount),
              ),
              _InfoRow(
                label: 'Итого с НДС',
                value: formatCurrency(totalToPay),
              ),
            ] else
              _InfoRow(label: 'К оплате', value: formatCurrency(totalToPay)),
            if (_operation.note != null && _operation.note!.isNotEmpty)
              _InfoRow(label: 'Примечание', value: _operation.note!),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                'Оплаты',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (canUpdate)
              GTTextButton(
                text: 'Добавить оплату',
                onPressed: _addPayment,
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (paymentsState.isLoading && paymentsState.payments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CupertinoActivityIndicator()),
          )
        else if (paymentsState.error != null && paymentsState.payments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              paymentsState.error!,
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error),
            ),
          )
        else if (paymentsState.payments.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outline.withValues(alpha: 0.22)),
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
            ),
            child: Text(
              'Оплат по этому счёту пока нет',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          )
        else
          _PaymentsTable(
            payments: paymentsState.payments,
            canUpdate: canUpdate,
            onEdit: _editPayment,
            onDelete: _deletePayment,
          ),
      ],
    );

    final footer = GTPrimaryButton(
      text: 'Закрыть',
      onPressed: () => Navigator.of(context).pop(),
    );

    if (isDesktop) {
      return DesktopDialogContent(
        title: title,
        width: 960,
        footer: footer,
        child: content,
      );
    }

    return MobileBottomSheetContent(
      title: title,
      footer: footer,
      child: content,
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  final double totalToPay;
  final double paidAmount;
  final double remaining;
  final String statusLabel;
  final Color statusColor;

  const _SummaryStrip({
    required this.totalToPay,
    required this.paidAmount,
    required this.remaining,
    required this.statusLabel,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasDebt = remaining > SettlementOperation.amountEpsilon;
    final hasOverpay = remaining < -SettlementOperation.amountEpsilon;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.22)),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              label: 'К оплате',
              value: formatCurrency(totalToPay),
            ),
          ),
          _SummaryDivider(scheme: scheme),
          Expanded(
            child: _SummaryItem(
              label: 'Оплачено',
              value: formatCurrency(paidAmount),
            ),
          ),
          _SummaryDivider(scheme: scheme),
          Expanded(
            child: _SummaryItem(
              label: 'Остаток',
              value: formatCurrency(remaining),
              tone: hasDebt
                  ? scheme.error
                  : hasOverpay
                      ? settlementPaymentStatusColor(
                          theme,
                          SettlementPaymentStatus.overpaid,
                        )
                      : null,
              emphasize: hasDebt || hasOverpay,
            ),
          ),
          _SummaryDivider(scheme: scheme),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Статус',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? tone;
  final bool emphasize;

  const _SummaryItem({
    required this.label,
    required this.value,
    this.tone,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: emphasize ? FontWeight.w800 : FontWeight.w700,
            color: tone,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  final ColorScheme scheme;

  const _SummaryDivider({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: scheme.outline.withValues(alpha: 0.18),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentsTable extends StatelessWidget {
  final List<SettlementPayment> payments;
  final bool canUpdate;
  final void Function(SettlementPayment payment) onEdit;
  final void Function(SettlementPayment payment) onDelete;

  static const _hPad = 12.0;

  const _PaymentsTable({
    required this.payments,
    required this.canUpdate,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final headerStyle = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: scheme.onSurface.withValues(alpha: 0.6),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: _hPad),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: _PaymentTableRowLayout(
              canUpdate: canUpdate,
              isHeader: true,
              date: Text('Дата', style: headerStyle),
              amount: Text(
                'Сумма',
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: headerStyle,
              ),
              note: Text(
                'Примечание',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: headerStyle,
              ),
            ),
          ),
          for (var i = 0; i < payments.length; i++)
            _PaymentRow(
              payment: payments[i],
              index: i,
              canUpdate: canUpdate,
              onEdit: () => onEdit(payments[i]),
              onDelete: () => onDelete(payments[i]),
            ),
        ],
      ),
    );
  }
}

/// Единая сетка колонок таблицы оплат (заголовок и строки).
class _PaymentTableRowLayout extends StatelessWidget {
  final Widget date;
  final Widget amount;
  final Widget note;
  final Widget? actions;
  final bool canUpdate;
  final bool isHeader;

  static const dateWidth = 96.0;
  static const amountWidth = 148.0;
  static const colGap = 16.0;
  static const actionsWidth = 72.0;

  const _PaymentTableRowLayout({
    required this.date,
    required this.amount,
    required this.note,
    required this.canUpdate,
    this.actions,
    this.isHeader = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          isHeader ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        SizedBox(width: dateWidth, child: date),
        const SizedBox(width: colGap),
        SizedBox(width: amountWidth, child: amount),
        const SizedBox(width: colGap),
        Expanded(child: note),
        if (canUpdate)
          SizedBox(
            width: actionsWidth,
            child: actions ?? const SizedBox.shrink(),
          ),
      ],
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final SettlementPayment payment;
  final int index;
  final bool canUpdate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PaymentRow({
    required this.payment,
    required this.index,
    required this.canUpdate,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final striped = index.isEven;
    final hasNote = payment.note != null && payment.note!.trim().isNotEmpty;

    return Material(
      color: striped
          ? scheme.onSurface.withValues(alpha: 0.03)
          : Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.symmetric(
          horizontal: _PaymentsTable._hPad,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: scheme.outline.withValues(alpha: 0.1)),
          ),
        ),
        child: _PaymentTableRowLayout(
          canUpdate: canUpdate,
          date: Text(
            formatRuDate(payment.paymentDate),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
          ),
          amount: Text(
            formatCurrency(payment.amount),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          note: Text(
            hasNote ? payment.note! : '—',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              height: 1.25,
              color: hasNote
                  ? null
                  : scheme.onSurface.withValues(alpha: 0.35),
            ),
          ),
          actions: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Редактировать',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: onEdit,
                icon: Icon(
                  CupertinoIcons.pencil,
                  size: 16,
                  color: scheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              IconButton(
                tooltip: 'Удалить',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: onDelete,
                icon: Icon(
                  CupertinoIcons.delete,
                  size: 16,
                  color: scheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
