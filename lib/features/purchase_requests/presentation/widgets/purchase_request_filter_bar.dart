import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:projectgt/features/fot/presentation/widgets/payroll_toolbar_metrics.dart';
import 'package:projectgt/features/purchase_requests/domain/entities/purchase_request_status.dart';

/// Раскладка полосы фильтров реестра заявок.
enum PurchaseRequestFilterBarLayout {
  /// Горизонтальные chip-сегменты (мобильный).
  horizontalChips,

  /// Вертикальные плитки (сайдбар desktop).
  verticalSidebar,
}

/// Общая полоса фильтров реестра заявок.
class PurchaseRequestFilterBar extends StatelessWidget {
  /// Создаёт полосу фильтров.
  const PurchaseRequestFilterBar({
    super.key,
    required this.filter,
    required this.onChanged,
    this.layout = PurchaseRequestFilterBarLayout.horizontalChips,
    this.padding,
    this.spacing = 8,
  });

  /// Мобильная горизонтальная полоса.
  factory PurchaseRequestFilterBar.mobile({
    Key? key,
    required PurchaseRequestListFilter filter,
    required ValueChanged<PurchaseRequestListFilter> onChanged,
  }) {
    return PurchaseRequestFilterBar(
      key: key,
      filter: filter,
      onChanged: onChanged,
      layout: PurchaseRequestFilterBarLayout.horizontalChips,
    );
  }

  /// Десктопный сайдбар.
  factory PurchaseRequestFilterBar.desktopSidebar({
    Key? key,
    required PurchaseRequestListFilter filter,
    required ValueChanged<PurchaseRequestListFilter> onChanged,
  }) {
    return PurchaseRequestFilterBar(
      key: key,
      filter: filter,
      onChanged: onChanged,
      layout: PurchaseRequestFilterBarLayout.verticalSidebar,
      padding: EdgeInsets.zero,
    );
  }

  /// Текущий фильтр.
  final PurchaseRequestListFilter filter;

  /// Обработчик смены фильтра.
  final ValueChanged<PurchaseRequestListFilter> onChanged;

  /// Раскладка.
  final PurchaseRequestFilterBarLayout layout;

  /// Внешний отступ.
  final EdgeInsetsGeometry? padding;

  /// Зазор между пунктами.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final items = PurchaseRequestListFilter.values.map((f) {
      return _PurchaseRequestFilterOption(
        label: f.label,
        selected: f == filter,
        layout: layout,
        onTap: () => onChanged(f),
      );
    }).toList();

    return switch (layout) {
      PurchaseRequestFilterBarLayout.horizontalChips => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) SizedBox(width: spacing),
                items[i],
              ],
            ],
          ),
        ),
      PurchaseRequestFilterBarLayout.verticalSidebar => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) SizedBox(height: spacing),
              items[i],
            ],
          ],
        ),
    };
  }
}

class _PurchaseRequestFilterOption extends StatelessWidget {
  const _PurchaseRequestFilterOption({
    required this.label,
    required this.selected,
    required this.layout,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final PurchaseRequestFilterBarLayout layout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return switch (layout) {
      PurchaseRequestFilterBarLayout.horizontalChips =>
        PayrollToolbarSegmentChip(
          label: label,
          selected: selected,
          onTap: onTap,
        ),
      PurchaseRequestFilterBarLayout.verticalSidebar => _SidebarFilterTile(
          label: label,
          selected: selected,
          onTap: onTap,
        ),
    };
  }
}

class _SidebarFilterTile extends StatelessWidget {
  const _SidebarFilterTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? Colors.grey[800] : Colors.grey[100])
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? (isDark ? Colors.white24 : Colors.black12)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? CupertinoIcons.checkmark_circle_fill
                    : CupertinoIcons.circle,
                size: 18,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (selected)
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
