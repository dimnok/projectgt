import 'package:flutter/material.dart';
import 'package:projectgt/features/purchase_requests/presentation/utils/purchase_request_module_utils.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_status.dart';
import 'package:projectgt/features/purchase_requests/presentation/widgets/purchase_request_details_tokens.dart';

/// Сводка по заявке: статус, сумма, количество позиций, комментарий.
class PurchaseRequestDetailsSummary extends StatelessWidget {
  /// Создаёт блок сводки.
  const PurchaseRequestDetailsSummary({
    super.key,
    required this.request,
    required this.statusColor,
    this.itemsCount,
  });

  /// Заявка.
  final PurchaseRequest request;

  /// Цвет статуса.
  final Color statusColor;

  /// Количество позиций (если уже загружено).
  final int? itemsCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final useColumn =
                constraints.maxWidth < PurchaseRequestDetailsTokens.kpiRowBreakpoint;

            final statusCard = _KpiCard(
              theme: theme,
              accentColor: statusColor,
              label: 'Статус',
              value: request.status.displayName,
              emphasized: true,
              trailing: _StatusDot(color: statusColor),
            );
            final sumCard = _KpiCard(
              theme: theme,
              label: 'Сумма',
              value: formatPurchaseRequestAmount(request.totalAmount),
              emphasized: request.totalAmount > 0,
              icon: Icons.payments_outlined,
            );
            final countCard = _KpiCard(
              theme: theme,
              label: 'Позиций',
              value: itemsCount != null ? '$itemsCount' : '—',
              icon: Icons.inventory_2_outlined,
            );

            if (useColumn) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  statusCard,
                  const SizedBox(height: PurchaseRequestDetailsTokens.kpiGap),
                  sumCard,
                  const SizedBox(height: PurchaseRequestDetailsTokens.kpiGap),
                  countCard,
                ],
              );
            }

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 5, child: statusCard),
                  const SizedBox(width: PurchaseRequestDetailsTokens.kpiGap),
                  Expanded(flex: 4, child: sumCard),
                  const SizedBox(width: PurchaseRequestDetailsTokens.kpiGap),
                  Expanded(flex: 3, child: countCard),
                ],
              ),
            );
          },
        ),
        if (request.status == PurchaseRequestStatus.revision) ...[
          const SizedBox(height: 12),
          _CalloutBanner(
            icon: Icons.edit_note_outlined,
            color: theme.colorScheme.tertiary,
            text: 'Возвращено на доработку',
          ),
        ],
        if (request.comment != null && request.comment!.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          _CommentBlock(comment: request.comment!.trim()),
        ],
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.theme,
    required this.label,
    required this.value,
    this.accentColor,
    this.emphasized = false,
    this.icon,
    this.trailing,
  });

  final ThemeData theme;
  final String label;
  final String value;
  final Color? accentColor;
  final bool emphasized;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final muted = PurchaseRequestDetailsTokens.mutedText(theme);

    return DecoratedBox(
      decoration: PurchaseRequestDetailsTokens.cardDecoration(theme),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(PurchaseRequestDetailsTokens.cardRadius),
        child: Row(
          children: [
            if (accentColor != null) Container(width: 4, color: accentColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 14, color: muted),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            label.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: muted,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.6,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        if (trailing != null) trailing!,
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight:
                            emphasized ? FontWeight.w800 : FontWeight.w700,
                        fontSize: emphasized ? 20 : 18,
                        height: 1.1,
                        color: accentColor ?? theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _CalloutBanner extends StatelessWidget {
  const _CalloutBanner({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius:
            BorderRadius.circular(PurchaseRequestDetailsTokens.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentBlock extends StatelessWidget {
  const _CommentBlock({required this.comment});

  final String comment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = PurchaseRequestDetailsTokens.mutedText(theme);

    return DecoratedBox(
      decoration: PurchaseRequestDetailsTokens.cardDecoration(theme),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.chat_bubble_outline, size: 18, color: muted),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Комментарий',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: muted,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
