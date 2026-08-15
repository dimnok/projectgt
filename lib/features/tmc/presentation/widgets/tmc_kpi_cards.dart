import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_dashboard_stats.dart';
import 'package:projectgt/features/tmc/presentation/utils/tmc_ui_labels.dart';

/// Элегантная сводка ключевых метрик ТМЦ (KPI) со строгим минималистичным дизайном.
class TmcKpiCards extends StatelessWidget {
  /// Статистика модуля ТМЦ.
  final TmcDashboardStats stats;

  /// Показывать общую стоимость (требуется право view_cost).
  final bool showCost;

  /// Создаёт виджет KPI.
  const TmcKpiCards({super.key, required this.stats, this.showCost = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final primary = <_KpiMetric>[
      _KpiMetric(
        label: TmcUiLabels.kpiInStock,
        value: formatQuantity(stats.inStock),
        icon: CupertinoIcons.cube_box,
      ),
      _KpiMetric(
        label: TmcUiLabels.kpiIssued,
        value: formatQuantity(stats.issued),
        icon: CupertinoIcons.person_2,
      ),
      _KpiMetric(
        label: TmcUiLabels.kpiOnObject,
        value: formatQuantity(stats.onObject),
        icon: CupertinoIcons.building_2_fill,
      ),
    ];

    if (showCost && stats.totalCost != null) {
      primary.add(
        _KpiMetric(
          label: TmcUiLabels.kpiTotalCost,
          value: formatCurrency(stats.totalCost!),
          icon: CupertinoIcons.creditcard,
        ),
      );
    }

    final alerts = <_KpiMetric>[
      if (stats.inRepair > 0)
        _KpiMetric(
          label: TmcUiLabels.kpiInRepair,
          value: '${stats.inRepair}',
          icon: CupertinoIcons.wrench,
        ),
      if (stats.needsRepair > 0)
        _KpiMetric(
          label: TmcUiLabels.kpiNeedsRepair,
          value: '${stats.needsRepair}',
          icon: CupertinoIcons.exclamationmark_triangle,
        ),
      if (stats.lost > 0)
        _KpiMetric(
          label: TmcUiLabels.kpiLost,
          value: '${stats.lost}',
          icon: CupertinoIcons.question_circle,
        ),
      if (stats.writtenOff > 0)
        _KpiMetric(
          label: TmcUiLabels.kpiWrittenOff,
          value: '${stats.writtenOff}',
          icon: CupertinoIcons.trash,
        ),
    ];

    final metaText =
        '${stats.totalItems} ${TmcUiLabels.kpiTotalItems.toLowerCase()} · '
        '${formatQuantity(stats.totalUnits)} ${TmcUiLabels.kpiTotalUnits.toLowerCase()}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 640;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...primary.map(
                    (metric) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _MetricCard(
                        metric: metric,
                        compact: compact,
                        theme: theme,
                        scheme: scheme,
                        isDark: isDark,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: scheme.outline.withValues(
                          alpha: isDark ? 0.15 : 0.1,
                        ),
                      ),
                    ),
                    child: Text(
                      metaText,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        if (alerts.isNotEmpty) ...[
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: alerts
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _AlertBadge(
                        metric: item,
                        theme: theme,
                        scheme: scheme,
                        isDark: isDark,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }
}

class _KpiMetric {
  final String label;
  final String value;
  final IconData icon;

  const _KpiMetric({
    required this.label,
    required this.value,
    required this.icon,
  });
}

class _MetricCard extends StatelessWidget {
  final _KpiMetric metric;
  final bool compact;
  final ThemeData theme;
  final ColorScheme scheme;
  final bool isDark;

  const _MetricCard({
    required this.metric,
    required this.compact,
    required this.theme,
    required this.scheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: compact ? 110 : 135),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(
          alpha: isDark ? 0.35 : 0.25,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: scheme.outline.withValues(alpha: isDark ? 0.22 : 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                metric.icon,
                size: 12,
                color: scheme.onSurface.withValues(alpha: 0.45),
              ),
              const SizedBox(width: 5),
              Text(
                metric.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            metric.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertBadge extends StatelessWidget {
  final _KpiMetric metric;
  final ThemeData theme;
  final ColorScheme scheme;
  final bool isDark;

  const _AlertBadge({
    required this.metric,
    required this.theme,
    required this.scheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(
          alpha: isDark ? 0.25 : 0.15,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scheme.outline.withValues(alpha: isDark ? 0.3 : 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            metric.icon,
            size: 11,
            color: scheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 4),
          Text(
            '${metric.label}: ${metric.value}',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 10.5,
              color: scheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
