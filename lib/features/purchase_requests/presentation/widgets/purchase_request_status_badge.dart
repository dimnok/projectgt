import 'package:flutter/material.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_status.dart';
import 'package:projectgt/features/purchase_requests/presentation/utils/purchase_request_ui_labels.dart';

/// Бейдж статуса заявки для списков и карточек.
class PurchaseRequestStatusBadge extends StatelessWidget {
  /// Создаёт бейдж статуса.
  const PurchaseRequestStatusBadge({
    super.key,
    required this.status,
  });

  /// Статус заявки.
  final PurchaseRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = PurchaseRequestUiLabels.statusColor(theme, status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '● ${status.displayName}',
        style: theme.textTheme.labelSmall?.copyWith(
          color: statusColor,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
