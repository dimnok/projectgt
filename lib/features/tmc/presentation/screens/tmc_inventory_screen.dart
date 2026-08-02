import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/core/common/app_router.dart';
import 'package:projectgt/features/tmc/presentation/utils/tmc_ui_labels.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';

/// Экран инвентаризации ТМЦ.
///
/// Полноценный UI сверки остатков будет в следующем этапе.
/// Таблицы БД (`tmc_inventories`, `tmc_inventory_items`) уже созданы.
class TmcInventoryScreen extends ConsumerWidget {
  /// Создаёт экран.
  const TmcInventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBarWidget(
        title: TmcUiLabels.inventory,
        leading: BackButton(onPressed: () => context.go(AppRoutes.tmc)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.checkmark_seal,
                size: 48,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.45),
              ),
              const SizedBox(height: 16),
              Text(
                'Инвентаризация в разработке',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Сейчас доступны поступление, выдача, перемещение, ремонт и списание.\n'
                'Сверка остатков появится отдельным этапом.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
