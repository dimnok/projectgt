import 'package:flutter/material.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_history_entry.dart';
import 'package:projectgt/features/purchase_requests/presentation/utils/purchase_request_ui_labels.dart';
import 'package:projectgt/features/purchase_requests/presentation/widgets/purchase_request_details_tokens.dart';

/// Вертикальный таймлайн истории заявки.
class PurchaseRequestHistoryTimeline extends StatelessWidget {
  /// Создаёт таймлайн истории.
  const PurchaseRequestHistoryTimeline({super.key, required this.entries});

  /// Записи истории.
  final List<PurchaseRequestHistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = PurchaseRequestDetailsTokens.mutedText(theme);

    if (entries.isEmpty) {
      return DecoratedBox(
        decoration: PurchaseRequestDetailsTokens.cardDecoration(theme),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Text(
            'История пуста',
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ),
      );
    }

    final cardBg = PurchaseRequestDetailsTokens.cardBackground(theme);
    final lineColor = PurchaseRequestDetailsTokens.borderColor(theme);

    return DecoratedBox(
      decoration: PurchaseRequestDetailsTokens.cardDecoration(theme),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          children: [
            for (var i = 0; i < entries.length; i++)
              _TimelineEntry(
                entry: entries[i],
                isLast: i == entries.length - 1,
                cardBackground: cardBg,
                lineColor: lineColor,
              ),
          ],
        ),
      ),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.entry,
    required this.isLast,
    required this.cardBackground,
    required this.lineColor,
  });

  final PurchaseRequestHistoryEntry entry;
  final bool isLast;
  final Color cardBackground;
  final Color lineColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = PurchaseRequestDetailsTokens.mutedText(theme);
    final action = PurchaseRequestUiLabels.historyActionPhrase(entry.action);
    final comment = entry.comment?.trim();
    final dotColor = theme.colorScheme.onSurface.withValues(alpha: 0.25);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: cardBackground, width: 2),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: lineColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 8 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: theme.textTheme.bodySmall?.copyWith(
                              height: 1.4,
                            ),
                            children: [
                              TextSpan(
                                text: entry.userLabel,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextSpan(
                                text: ' $action',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        formatRuDateTime(entry.createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: muted,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  if (comment != null && comment.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      comment,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: muted,
                        fontStyle: FontStyle.italic,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
