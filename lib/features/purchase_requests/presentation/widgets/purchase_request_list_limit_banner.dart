import 'package:flutter/material.dart';

/// Баннер: список заявок обрезан лимитом загрузки.
class PurchaseRequestListLimitBanner extends StatelessWidget {
  /// Создаёт баннер.
  const PurchaseRequestListLimitBanner({
    super.key,
    required this.limit,
  });

  /// Лимит записей в одной загрузке.
  final int limit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Показаны первые $limit заявок. Уточните поиск или фильтр.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
