import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/domain/entities/contract_act.dart';
import 'package:projectgt/domain/entities/contract_act_payment_status.dart';
import 'package:projectgt/domain/entities/contract_act_workflow_status.dart';
import 'package:projectgt/features/contracts/presentation/utils/contract_act_ui_labels.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';

/// Строка акта в списке: визуально согласована со строками раздела «Документы договора».
///
/// Полоса с иконкой слева, скругление 12, обводка и подсветка при наведении.
/// В одной строке с названием: статус согласования, номер, даты; справа сумма (акт + НДС)
/// и статус оплаты.
/// Итого к оплате с удержаниями — в [ContractAct.totalToPay], не в отображаемой сумме.
///
/// [onEdit] и [onDelete] — действия в конце строки (как у файлов документов); если оба
/// `null`, колонка кнопок не показывается.
class ContractActRowCard extends StatefulWidget {
  /// Акт для отображения.
  final ContractAct act;

  /// Открыть форму редактирования акта.
  final VoidCallback? onEdit;

  /// Удалить акт (после подтверждения — на стороне вызывающего).
  final VoidCallback? onDelete;

  /// Скачать сохранённый файл акта (например, Excel КС-2).
  final VoidCallback? onDownload;

  /// Подпись статуса согласования (например, акт КС-2 вместо реестра).
  final String? workflowStatusLabel;

  /// Цвет подписи статуса согласования; если `null` — из [ContractAct.workflowStatus].
  final Color? workflowStatusColor;

  /// Подпись статуса оплаты; если `null` — из [ContractAct.paymentStatus].
  final String? paymentStatusLabel;

  /// Цвет подписи оплаты; если `null` — из [ContractAct.paymentStatus].
  final Color? paymentStatusColor;

  /// Создаёт строку акта.
  const ContractActRowCard({
    super.key,
    required this.act,
    this.onEdit,
    this.onDelete,
    this.onDownload,
    this.workflowStatusLabel,
    this.workflowStatusColor,
    this.paymentStatusLabel,
    this.paymentStatusColor,
  });

  @override
  State<ContractActRowCard> createState() => _ContractActRowCardState();
}

class _ContractActRowCardState extends State<ContractActRowCard> {
  bool _hover = false;

  static Color _stripeBackground(ColorScheme scheme) =>
      scheme.primary.withValues(alpha: 0.08);

  static Color _iconColor(ColorScheme scheme) =>
      scheme.primary.withValues(alpha: 0.78);

  Color _rowBackground(ColorScheme scheme, Brightness brightness) {
    final base = scheme.surface;
    final isDark = brightness == Brightness.dark;
    if (_hover) {
      return Color.alphaBlend(
        scheme.onSurface.withValues(alpha: isDark ? 0.14 : 0.05),
        base,
      );
    }
    return base;
  }

  static Color _workflowColor(ThemeData theme, ContractActWorkflowStatus s) {
    final dark = theme.brightness == Brightness.dark;
    return switch (s) {
      ContractActWorkflowStatus.signed => theme.colorScheme.primary,
      // tertiary в тёмной теме часто даёт «грязный» коричневый с низким контрастом на surface.
      ContractActWorkflowStatus.approved => dark
          ? const Color(0xFF80D8FF)
          : const Color(0xFF006978),
      ContractActWorkflowStatus.pendingApproval =>
        theme.colorScheme.onSurfaceVariant,
    };
  }

  static Color _paymentColor(ThemeData theme, ContractActPaymentStatus s) {
    final dark = theme.brightness == Brightness.dark;
    return switch (s) {
      ContractActPaymentStatus.paid =>
        dark ? const Color(0xFF69F0AE) : const Color(0xFF1B5E20),
      ContractActPaymentStatus.partial =>
        dark ? const Color(0xFFFFB74D) : const Color(0xFFE65100),
      ContractActPaymentStatus.unpaid =>
        theme.colorScheme.onSurface.withValues(alpha: 0.5),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final act = widget.act;
    final hasCustomTitle = act.title.trim().isNotEmpty;
    final titleText = hasCustomTitle ? act.title.trim() : 'Акт № ${act.number}';
    final workflowLabel = widget.workflowStatusLabel ??
        contractActWorkflowStatusLabel(act.workflowStatus);
    final workflowColor = widget.workflowStatusColor ??
        _workflowColor(theme, act.workflowStatus);
    final paymentLabel = widget.paymentStatusLabel ??
        contractActPaymentStatusLabel(act.paymentStatus);
    final paymentColor = widget.paymentStatusColor ??
        _paymentColor(theme, act.paymentStatus);
    final tailMeta = hasCustomTitle
        ? ' · № ${act.number} · ${formatRuDate(act.actDate)} · ${formatRuDate(act.periodFrom)}—${formatRuDate(act.periodTo)}'
        : ' · ${formatRuDate(act.actDate)} · ${formatRuDate(act.periodFrom)}—${formatRuDate(act.periodTo)}';
    final mutedMetaStyle = TextStyle(
      fontWeight: FontWeight.w500,
      color: scheme.onSurface.withValues(alpha: 0.52),
    );
    final note = act.note?.trim();
    final hasNote = note != null && note.isNotEmpty;
    // Сумма на карточке: сумма акта + НДС (без удержаний).
    final amountWithVat = act.amount + act.vatAmount;

    final borderColor = scheme.outline.withValues(alpha: 0.1);
    final bg = _rowBackground(scheme, theme.brightness);

    final row = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 48,
              color: _stripeBackground(scheme),
              child: Center(
                child: Icon(
                  contractActRowIcon(),
                  color: _iconColor(scheme),
                  size: 22,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              style: theme.textTheme.titleSmall?.copyWith(
                                height: 1.2,
                              ),
                              children: [
                                TextSpan(
                                  text: titleText,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(text: ' · ', style: mutedMetaStyle),
                                TextSpan(
                                  text: workflowLabel,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: workflowColor,
                                  ),
                                ),
                                TextSpan(text: tailMeta, style: mutedMetaStyle),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatCurrency(amountWithVat),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.5),
                                height: 1.2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              paymentLabel,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: paymentColor,
                                fontWeight: FontWeight.w600,
                                height: 1.15,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (hasNote) ...[
                      const SizedBox(height: 4),
                      Text(
                        note,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.65),
                          height: 1.25,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (widget.onEdit != null ||
                widget.onDelete != null ||
                widget.onDownload != null)
              Padding(
                padding: const EdgeInsets.only(right: 4, left: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.onDownload != null)
                      CupertinoButton(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.all(6),
                        onPressed: widget.onDownload,
                        child: Semantics(
                          label: 'Скачать файл акта',
                          button: true,
                          child: Icon(
                            CupertinoIcons.arrow_down_doc,
                            size: 18,
                            color: scheme.onSurface.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    if (widget.onEdit != null)
                      PermissionGuard(
                        module: 'contracts',
                        permission: 'update',
                        child: CupertinoButton(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.all(6),
                          onPressed: widget.onEdit,
                          child: Semantics(
                            label: 'Редактировать акт',
                            button: true,
                            child: Icon(
                              CupertinoIcons.pencil,
                              size: 18,
                              color: scheme.onSurface.withValues(alpha: 0.75),
                            ),
                          ),
                        ),
                      ),
                    if (widget.onDelete != null)
                      PermissionGuard(
                        module: 'contracts',
                        permission: 'delete',
                        child: CupertinoButton(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.all(6),
                          onPressed: widget.onDelete,
                          child: Semantics(
                            label: 'Удалить акт',
                            button: true,
                            child: Icon(
                              CupertinoIcons.trash,
                              size: 18,
                              color: scheme.error.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );

    return Semantics(
      label:
          '$titleText · $workflowLabel$tailMeta, ${formatCurrency(amountWithVat)}, $paymentLabel',
      container: true,
      child: MouseRegion(
        hitTestBehavior: HitTestBehavior.opaque,
        onEnter: (_) {
          if (!_hover) setState(() => _hover = true);
        },
        onExit: (_) {
          if (_hover) setState(() => _hover = false);
        },
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: row,
        ),
      ),
    );
  }
}
