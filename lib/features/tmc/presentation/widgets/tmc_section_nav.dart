import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:projectgt/features/tmc/presentation/utils/tmc_ui_labels.dart';

/// Раздел модуля ТМЦ внутри основной области экрана.
enum TmcModuleSection {
  /// Реестр позиций.
  registry,

  /// Журнал операций.
  operations,

  /// Остатки по складам.
  stock,

  /// Отчёты Excel.
  reports,

  /// Инвентаризация.
  inventory,

  /// Уведомления.
  notifications,

  /// Справочники складов и категорий.
  catalogs,
}

/// Горизонтальная панель разделов ТМЦ.
class TmcSectionNavBar extends StatelessWidget {
  /// Текущий раздел.
  final TmcModuleSection selected;

  /// Переключение раздела.
  final ValueChanged<TmcModuleSection> onSelected;

  /// Показывать пункт «Справочники».
  final bool showCatalogs;

  /// Создаёт панель разделов.
  const TmcSectionNavBar({
    super.key,
    required this.selected,
    required this.onSelected,
    this.showCatalogs = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _NavPill(
            icon: CupertinoIcons.list_bullet,
            label: TmcUiLabels.registry,
            selected: selected == TmcModuleSection.registry,
            onTap: () => onSelected(TmcModuleSection.registry),
            scheme: scheme,
            theme: theme,
            isDark: isDark,
          ),
          const SizedBox(width: 6),
          _NavPill(
            icon: CupertinoIcons.doc_text,
            label: TmcUiLabels.operationsJournal,
            selected: selected == TmcModuleSection.operations,
            onTap: () => onSelected(TmcModuleSection.operations),
            scheme: scheme,
            theme: theme,
            isDark: isDark,
          ),
          const SizedBox(width: 6),
          _NavPill(
            icon: CupertinoIcons.cube_box,
            label: TmcUiLabels.stockBalances,
            selected: selected == TmcModuleSection.stock,
            onTap: () => onSelected(TmcModuleSection.stock),
            scheme: scheme,
            theme: theme,
            isDark: isDark,
          ),
          const SizedBox(width: 6),
          _NavPill(
            icon: CupertinoIcons.chart_bar,
            label: TmcUiLabels.reports,
            selected: selected == TmcModuleSection.reports,
            onTap: () => onSelected(TmcModuleSection.reports),
            scheme: scheme,
            theme: theme,
            isDark: isDark,
          ),
          const SizedBox(width: 6),
          _NavPill(
            icon: CupertinoIcons.checkmark_seal,
            label: TmcUiLabels.inventory,
            selected: selected == TmcModuleSection.inventory,
            onTap: () => onSelected(TmcModuleSection.inventory),
            scheme: scheme,
            theme: theme,
            isDark: isDark,
          ),
          const SizedBox(width: 6),
          _NavPill(
            icon: CupertinoIcons.bell,
            label: TmcUiLabels.notifications,
            selected: selected == TmcModuleSection.notifications,
            onTap: () => onSelected(TmcModuleSection.notifications),
            scheme: scheme,
            theme: theme,
            isDark: isDark,
          ),
          if (showCatalogs) ...[
            const SizedBox(width: 6),
            _NavPill(
              icon: CupertinoIcons.book,
              label: TmcUiLabels.catalogs,
              selected: selected == TmcModuleSection.catalogs,
              onTap: () => onSelected(TmcModuleSection.catalogs),
              scheme: scheme,
              theme: theme,
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }
}

class _NavPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme scheme;
  final ThemeData theme;
  final bool isDark;

  const _NavPill({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.scheme,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected
        ? scheme.onSurface
        : scheme.onSurface.withValues(alpha: 0.65);

    final bg = selected
        ? scheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.65 : 0.75)
        : Colors.transparent;

    final borderColor = selected
        ? scheme.outline.withValues(alpha: isDark ? 0.4 : 0.3)
        : scheme.outline.withValues(alpha: isDark ? 0.18 : 0.12);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        hoverColor: scheme.onSurface.withValues(alpha: 0.04),
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: fg,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
