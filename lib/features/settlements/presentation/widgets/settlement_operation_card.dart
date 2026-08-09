import 'package:flutter/material.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_card_style.dart';
import 'package:projectgt/features/settlements/domain/entities/settlement_operation.dart';
import 'package:projectgt/features/settlements/presentation/utils/settlement_ui_labels.dart';

/// Карточка счёта на оплату для мобильного списка взаиморасчётов.
class SettlementOperationCard extends StatelessWidget {
  /// Создаёт карточку операции.
  const SettlementOperationCard({
    super.key,
    required this.operation,
    required this.style,
    required this.onTap,
  });

  /// Операция взаиморасчётов.
  final SettlementOperation operation;

  /// Стили карточки.
  final MobileAtmosphereCardStyle style;

  /// Тап по карточке.
  final VoidCallback onTap;

  static const double _radius = 12;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = style.scheme;
    final op = operation;
    final status = op.resolvedPaymentStatus;
    final statusColor = settlementPaymentStatusColor(theme, status);
    final typeColor = switch (op.operationType) {
      SettlementOperationType.act => scheme.primary,
      SettlementOperationType.advance => scheme.tertiary,
      SettlementOperationType.other => scheme.onSurface.withValues(alpha: 0.65),
    };

    final objectLine = op.objectName?.trim();
    final hasObject = objectLine != null && objectLine.isNotEmpty;
    final actLine = op.actNumber?.trim();
    final hasAct = actLine != null && actLine.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Semantics(
        button: true,
        label:
            'Счёт ${op.invoiceNumber}, ${settlementPaymentStatusLabel(status)}, '
            '${formatCurrency(op.invoiceTotal)}',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(_radius),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_radius),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [style.cardTop, style.cardBottom],
                ),
                border: Border.all(color: style.cardBorder),
                boxShadow: style.cardShadows,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_radius - 1),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: op.invoiceNumber,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      height: 1.2,
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' · ${formatRuDate(op.invoiceDate)}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontSize: 11,
                                      height: 1.2,
                                      color: scheme.onSurface.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _StatusPill(
                            label: settlementPaymentStatusLabel(status),
                            color: statusColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        hasObject
                            ? '${op.contractorName ?? '—'} · $objectLine'
                            : (op.contractorName ?? '—'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                _TypePill(
                                  label: settlementOperationTypeLabel(
                                    op.operationType,
                                  ),
                                  color: typeColor,
                                ),
                                if (hasAct) ...[
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      op.operationType ==
                                              SettlementOperationType.act
                                          ? actLine
                                          : 'Акт $actLine',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                        fontSize: 10,
                                        color: scheme.onSurface.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            formatCurrency(op.invoiceTotal),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              height: 1.1,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 9,
        ),
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 9,
        ),
      ),
    );
  }
}
