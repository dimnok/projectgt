import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/adaptive_dialog.dart';
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
  }) =>
      showAdaptiveModal<void>(
        context,
        builder: (_) => SettlementDetailsDialog(
          operation: operation,
          presetContract: presetContract,
        ),
      );

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

  Future<void> _refreshOperationFromProviders() async {
    final fresh = findSettlementOperationInProviders(
      ref,
      operationId: _operation.id,
      contractId: _operation.contractId,
    );
    if (!mounted || fresh == null) return;
    setState(() => _operation = fresh);
  }

  Future<void> _syncAfterPaymentChange() async {
    await syncSettlementProviders(ref, contractId: _operation.contractId);
    if (!mounted) return;
    await _refreshOperationFromProviders();
  }

  Future<void> _openEdit() async {
    await SettlementFormDialog.show(
      context,
      operation: _operation,
      presetContract: widget.presetContract,
    );
    if (!mounted) return;
    await _refreshOperationFromProviders();
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
    if (success) {
      await syncSettlementProviders(ref, contractId: _operation.contractId);
      if (!mounted) return;
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
    if (payment.isFromBankStatement) {
      AppSnackBar.show(
        context: context,
        message:
            'Оплата из банковской выписки. Измените или удалите транзакцию в модуле ДДС.',
        kind: AppSnackBarKind.info,
      );
      return;
    }
    final saved = await SettlementPaymentFormDialog.show(
      context,
      settlementOperationId: _operation.id,
      payment: payment,
    );
    if (saved == true) await _syncAfterPaymentChange();
  }

  Future<void> _deletePayment(SettlementPayment payment) async {
    if (payment.isFromBankStatement) {
      AppSnackBar.show(
        context: context,
        message:
            'Оплата из банковской выписки. Удалите транзакцию в модуле ДДС — оплата по счёту снимется автоматически.',
        kind: AppSnackBarKind.info,
      );
      return;
    }
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
        if (canUpdate || canDelete)
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 4,
            runSpacing: 4,
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
        if (canUpdate || canDelete) const SizedBox(height: 8),
        _SummaryStrip(
          compact: !isDesktop,
          totalToPay: totalToPay,
          paidAmount: paidAmount,
          remaining: remaining,
          statusLabel: settlementPaymentStatusLabel(status),
          statusColor: statusColor,
        ),
        const SizedBox(height: 16),
        _InfoSection(
          compact: !isDesktop,
          title: 'Реквизиты',
          children: [
            _InfoRow(
              compact: !isDesktop,
              label: 'Дата счёта',
              value: formatRuDate(_operation.invoiceDate),
            ),
            _InfoRow(
              compact: !isDesktop,
              label: 'Тип',
              value: settlementOperationTypeLabel(_operation.operationType),
            ),
            if (_operation.actNumber != null &&
                _operation.actNumber!.isNotEmpty)
              _InfoRow(
                compact: !isDesktop,
                label: 'Акт',
                value: _operation.actNumber!,
              ),
            _InfoRow(
              compact: !isDesktop,
              label: 'Договор',
              value: _operation.contractNumber ?? '—',
            ),
            _InfoRow(
              compact: !isDesktop,
              label: 'Контрагент',
              value: _operation.contractorName ?? '—',
            ),
            _InfoRow(
              compact: !isDesktop,
              label: 'Объект',
              value: _operation.objectName ?? '—',
            ),
            _InfoRow(
              compact: !isDesktop,
              label: 'Сумма без НДС',
              value: formatCurrency(_operation.amount),
            ),
            if (_operation.vatRate != null && _operation.vatRate! > 0) ...[
              _InfoRow(
                compact: !isDesktop,
                label: 'НДС (${formatQuantity(_operation.vatRate!)}%)',
                value: formatCurrency(_operation.vatAmount),
              ),
              _InfoRow(
                compact: !isDesktop,
                label: 'Итого с НДС',
                value: formatCurrency(totalToPay),
              ),
            ] else
              _InfoRow(
                compact: !isDesktop,
                label: 'К оплате',
                value: formatCurrency(totalToPay),
              ),
            if (_operation.note != null && _operation.note!.isNotEmpty)
              _InfoRow(
                compact: !isDesktop,
                label: 'Примечание',
                value: _operation.note!,
                multiline: true,
              ),
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
        else if (isDesktop)
          _PaymentsTable(
            payments: paymentsState.payments,
            canUpdate: canUpdate,
            onEdit: _editPayment,
            onDelete: _deletePayment,
          )
        else
          _PaymentsMobileList(
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
      scrollable: true,
      child: content,
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  final bool compact;
  final double totalToPay;
  final double paidAmount;
  final double remaining;
  final String statusLabel;
  final Color statusColor;

  const _SummaryStrip({
    this.compact = false,
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
    final remainingTone = hasDebt
        ? scheme.error
        : hasOverpay
            ? settlementPaymentStatusColor(
                theme,
                SettlementPaymentStatus.overpaid,
              )
            : null;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.22)),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      ),
      child: compact
          ? Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _SummaryItem(
                        compact: true,
                        label: 'К оплате',
                        value: formatCurrency(totalToPay),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryItem(
                        compact: true,
                        label: 'Оплачено',
                        value: formatCurrency(paidAmount),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Divider(
                    height: 1,
                    color: scheme.outline.withValues(alpha: 0.18),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryItem(
                        compact: true,
                        label: 'Остаток',
                        value: formatCurrency(remaining),
                        tone: remainingTone,
                        emphasize: hasDebt || hasOverpay,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryStatusItem(
                        compact: true,
                        statusLabel: statusLabel,
                        statusColor: statusColor,
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
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
                    tone: remainingTone,
                    emphasize: hasDebt || hasOverpay,
                  ),
                ),
                _SummaryDivider(scheme: scheme),
                Expanded(
                  child: _SummaryStatusItem(
                    statusLabel: statusLabel,
                    statusColor: statusColor,
                  ),
                ),
              ],
            ),
    );
  }
}

class _SummaryStatusItem extends StatelessWidget {
  final bool compact;
  final String statusLabel;
  final Color statusColor;

  const _SummaryStatusItem({
    this.compact = false,
    required this.statusLabel,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment:
          compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          'Статус',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: compact ? 10 : null,
            color: scheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            statusLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final bool compact;
  final String label;
  final String value;
  final Color? tone;
  final bool emphasize;

  const _SummaryItem({
    this.compact = false,
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
      crossAxisAlignment:
          compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: compact ? 10 : null,
            color: scheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: theme.textTheme.titleSmall?.copyWith(
            fontSize: compact ? 12 : null,
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
  final bool compact;
  final String title;
  final List<Widget> children;

  const _InfoSection({
    this.compact = false,
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
  final bool compact;
  final String label;
  final String value;
  final bool multiline;

  const _InfoRow({
    this.compact = false,
    required this.label,
    required this.value,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurface.withValues(alpha: 0.55),
    );
    final valueStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      height: multiline ? 1.35 : null,
    );

    if (compact) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label, style: labelStyle),
            const SizedBox(height: 2),
            Text(
              value,
              style: valueStyle,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: labelStyle),
          ),
          Expanded(
            child: Text(
              value,
              style: valueStyle,
            ),
          ),
        ],
      ),
    );
  }
}

/// Карточный список оплат для мобильного bottom sheet.
class _PaymentsMobileList extends StatelessWidget {
  final List<SettlementPayment> payments;
  final bool canUpdate;
  final void Function(SettlementPayment payment) onEdit;
  final void Function(SettlementPayment payment) onDelete;

  const _PaymentsMobileList({
    required this.payments,
    required this.canUpdate,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < payments.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _PaymentMobileCard(
            payment: payments[i],
            canUpdate: canUpdate,
            onEdit: () => onEdit(payments[i]),
            onDelete: () => onDelete(payments[i]),
          ),
        ],
      ],
    );
  }
}

class _PaymentMobileCard extends StatelessWidget {
  final SettlementPayment payment;
  final bool canUpdate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PaymentMobileCard({
    required this.payment,
    required this.canUpdate,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasNote = payment.note != null && payment.note!.trim().isNotEmpty;
    final isFromBank = payment.isFromBankStatement;
    final noteText = isFromBank
        ? 'Из выписки${hasNote ? ': ${payment.note}' : ''}'
        : (hasNote ? payment.note! : '—');

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.22)),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  formatRuDate(payment.paymentDate),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                formatCurrency(payment.amount),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            noteText,
            style: theme.textTheme.bodySmall?.copyWith(
              height: 1.3,
              color: isFromBank
                  ? scheme.primary
                  : (hasNote
                      ? scheme.onSurface.withValues(alpha: 0.75)
                      : scheme.onSurface.withValues(alpha: 0.35)),
            ),
          ),
          if (canUpdate && !isFromBank) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GTTextButton(
                  text: 'Изменить',
                  onPressed: onEdit,
                ),
                GTTextButton(
                  text: 'Удалить',
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
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
    final isFromBank = payment.isFromBankStatement;

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
            isFromBank
                ? 'Из выписки${hasNote ? ': ${payment.note}' : ''}'
                : (hasNote ? payment.note! : '—'),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              height: 1.25,
              color: isFromBank
                  ? scheme.primary
                  : (hasNote
                      ? null
                      : scheme.onSurface.withValues(alpha: 0.35)),
            ),
          ),
          actions: canUpdate && !isFromBank
              ? Row(
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
          )
              : null,
        ),
      ),
    );
  }
}
