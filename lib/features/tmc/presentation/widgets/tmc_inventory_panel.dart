import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Заглушка инвентаризации ТМЦ.
///
/// Полноценный UI сверки остатков будет в следующем этапе.
/// Таблицы БД (`tmc_inventories`, `tmc_inventory_items`) уже созданы.
class TmcInventoryPanel extends StatelessWidget {
  /// Создаёт панель инвентаризации.
  const TmcInventoryPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.checkmark_seal,
              size: 48,
              color: scheme.onSurface.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 16),
            Text(
              'Инвентаризация в разработке',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Сейчас доступны поступление, выдача, перемещение, ремонт и списание.\n'
              'Сверка остатков появится отдельным этапом.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
