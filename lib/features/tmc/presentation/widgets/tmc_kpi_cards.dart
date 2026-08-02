import 'package:flutter/material.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_dashboard_stats.dart';
import 'package:projectgt/features/tmc/presentation/utils/tmc_ui_labels.dart';

/// KPI-карточки дашборда ТМЦ.
class TmcKpiCards extends StatelessWidget {
  /// Статистика.
  final TmcDashboardStats stats;

  /// Показывать стоимость (право view_cost).
  final bool showCost;

  /// Создаёт виджет.
  const TmcKpiCards({
    super.key,
    required this.stats,
    this.showCost = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final items = <_KpiItem>[
      _KpiItem(TmcUiLabels.kpiTotalItems, '${stats.totalItems}'),
      _KpiItem(TmcUiLabels.kpiTotalUnits, formatQuantity(stats.totalUnits)),
      _KpiItem(TmcUiLabels.kpiInStock, formatQuantity(stats.inStock)),
      _KpiItem(TmcUiLabels.kpiOnObject, formatQuantity(stats.onObject)),
      _KpiItem(TmcUiLabels.kpiIssued, formatQuantity(stats.issued)),
      _KpiItem(TmcUiLabels.kpiInRepair, '${stats.inRepair}'),
      _KpiItem(TmcUiLabels.kpiNeedsRepair, '${stats.needsRepair}'),
      _KpiItem(TmcUiLabels.kpiLost, '${stats.lost}'),
      _KpiItem(TmcUiLabels.kpiWrittenOff, '${stats.writtenOff}'),
    ];

    if (showCost && stats.totalCost != null) {
      items.add(
        _KpiItem(TmcUiLabels.kpiTotalCost, formatCurrency(stats.totalCost!)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossCount = width >= 1200 ? 5 : width >= 800 ? 4 : width >= 560 ? 3 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.4,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: scheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _KpiItem {
  final String label;
  final String value;

  const _KpiItem(this.label, this.value);
}
