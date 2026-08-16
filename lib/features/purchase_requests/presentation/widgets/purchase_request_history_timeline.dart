import 'package:flutter/material.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_history_entry.dart';
import 'package:projectgt/features/purchase_requests/presentation/utils/purchase_request_ui_labels.dart';

/// Компактный список истории заявки — одна строка на действие.
///
/// Порядок данных: **кто → что → когда** (ФИО, действие, дата справа).
class PurchaseRequestHistoryTimeline extends StatelessWidget {
  /// Создаёт список истории.
  const PurchaseRequestHistoryTimeline({super.key, required this.entries});

  /// Записи истории.
  final List<PurchaseRequestHistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.outline.withValues(alpha: 0.12);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.5);

    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        alignment: Alignment.centerLeft,
        child: Text(
          'История пуста',
          style: theme.textTheme.labelSmall?.copyWith(color: muted),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: _HistoryLine(entry: entries[i]),
            ),
            if (i < entries.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                color: borderColor,
              ),
          ],
        ],
      ),
    );
  }
}

class _HistoryLine extends StatelessWidget {
  const _HistoryLine({required this.entry});

  final PurchaseRequestHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.5);
    final action = PurchaseRequestUiLabels.historyActionPhrase(entry.action);
    final comment = entry.comment?.trim();
    final baseStyle = theme.textTheme.labelSmall?.copyWith(height: 1.35);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              style: baseStyle,
              children: [
                TextSpan(
                  text: entry.userLabel,
                  style: baseStyle?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.88),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: ' $action',
                  style: baseStyle?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
                if (comment != null && comment.isNotEmpty)
                  TextSpan(
                    text: ' — $comment',
                    style: baseStyle?.copyWith(
                      color: muted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          formatRuDateTime(entry.createdAt),
          style: theme.textTheme.labelSmall?.copyWith(
            color: muted,
            height: 1.35,
          ),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }
}
