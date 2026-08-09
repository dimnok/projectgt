import 'package:flutter/material.dart';
import 'package:projectgt/features/settlements/presentation/utils/settlements_filter_options.dart';
import 'package:projectgt/features/settlements/presentation/widgets/settlements_toolbar_metrics.dart';

/// Плотный выпадающий фильтр по сущности в панели взаиморасчётов.
///
/// Визуально согласован с [TimesheetObjectsBarDropdown] (высота 34, [MenuAnchor]).
/// Одиночный выбор: контрагент, объект или договор.
class SettlementsOptionBarDropdown extends StatelessWidget {
  /// Создаёт выпадающий фильтр.
  const SettlementsOptionBarDropdown({
    super.key,
    required this.options,
    required this.selectedId,
    required this.onChanged,
    required this.icon,
    required this.tooltip,
    required this.headerTitle,
    required this.allLabel,
    required this.emptyPlaceholder,
  });

  /// Доступные опции.
  final List<SettlementsFilterOption> options;

  /// Выбранный идентификатор; `null` — без фильтра.
  final String? selectedId;

  /// Колбэк смены выбора.
  final ValueChanged<String?> onChanged;

  /// Иконка на триггере.
  final IconData icon;

  /// Подсказка триггера.
  final String tooltip;

  /// Заголовок секции в меню (например, «КОНТРАГЕНТЫ»).
  final String headerTitle;

  /// Подпись пункта «все».
  final String allLabel;

  /// Подпись триггера при пустом списке опций.
  final String emptyPlaceholder;

  static String _triggerLabel({
    required String? selectedId,
    required List<SettlementsFilterOption> options,
    required String allLabel,
  }) {
    if (selectedId == null) return allLabel;
    return SettlementsFilterOptionsBuilder.labelForId(options, selectedId) ??
        selectedId;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final label = _triggerLabel(
      selectedId: selectedId,
      options: options,
      allLabel: allLabel,
    );
    final isActive = selectedId != null;
    final textStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: SettlementsToolbarMetrics.fontSize,
      height: 1.2,
      color: isActive ? scheme.primary : scheme.onSurface,
    );
    final borderColor = isActive
        ? SettlementsToolbarMetrics.activeBorder(scheme)
        : SettlementsToolbarMetrics.trackBorder(scheme);
    final fill = isActive
        ? SettlementsToolbarMetrics.activeFill(scheme)
        : SettlementsToolbarMetrics.trackFill(scheme);
    final iconColor = isActive
        ? scheme.primary
        : scheme.onSurface.withValues(alpha: 0.55);

    if (options.isEmpty) {
      return Tooltip(
        message: 'Нет данных для фильтра',
        child: Container(
          height: SettlementsToolbarMetrics.height,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SettlementsToolbarMetrics.radius),
            border: Border.all(color: SettlementsToolbarMetrics.trackBorder(scheme)),
            color: SettlementsToolbarMetrics.trackFill(scheme),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: SettlementsToolbarMetrics.iconSize, color: iconColor),
              const SizedBox(width: 6),
              Text(
                emptyPlaceholder,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyle?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(scheme.surface),
        elevation: const WidgetStatePropertyAll(6),
        shadowColor: WidgetStatePropertyAll(
          scheme.shadow.withValues(alpha: 0.18),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: borderColor),
          ),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
      ),
      menuChildren: [
        _SettlementsOptionFilterMenu(
          key: ValueKey(options.map((e) => e.id).join('\x1e')),
          width: SettlementsToolbarMetrics.entityMenuWidth,
          maxScrollHeight: SettlementsToolbarMetrics.menuMaxHeight,
          headerTitle: headerTitle,
          allLabel: allLabel,
          options: options,
          selectedId: selectedId,
          onPick: onChanged,
        ),
      ],
      builder: (context, menuController, _) {
        return Tooltip(
          message: tooltip,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(SettlementsToolbarMetrics.radius),
            child: InkWell(
              borderRadius: BorderRadius.circular(SettlementsToolbarMetrics.radius),
              onTap: () {
                if (menuController.isOpen) {
                  menuController.close();
                } else {
                  menuController.open();
                }
              },
              child: Ink(
                height: SettlementsToolbarMetrics.height,
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(SettlementsToolbarMetrics.radius),
                  border: Border.all(
                    color: borderColor,
                    width: isActive ? 1.25 : 1,
                  ),
                  color: fill,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: SettlementsToolbarMetrics.iconSize, color: iconColor),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 168),
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textStyle,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        menuController.isOpen
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 20,
                        color: iconColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SettlementsOptionFilterMenu extends StatelessWidget {
  const _SettlementsOptionFilterMenu({
    super.key,
    required this.width,
    required this.maxScrollHeight,
    required this.headerTitle,
    required this.allLabel,
    required this.options,
    required this.selectedId,
    required this.onPick,
  });

  final double width;
  final double maxScrollHeight;
  final String headerTitle;
  final String allLabel;
  final List<SettlementsFilterOption> options;
  final String? selectedId;
  final ValueChanged<String?> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final headerStyle = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 11,
      letterSpacing: 0.4,
      height: 1.1,
      color: scheme.onSurface.withValues(alpha: 0.65),
    );
    final rowTextStyle = theme.textTheme.bodyMedium?.copyWith(
      fontSize: 13.5,
      height: 1.15,
      color: scheme.onSurface,
    );

    Widget selectableRow({
      required String semanticLabel,
      required bool selected,
      required String label,
      required VoidCallback onTap,
    }) {
      return Semantics(
        button: true,
        selected: selected,
        label: semanticLabel,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 22,
                    child: selected
                        ? Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: scheme.primary,
                          )
                        : null,
                  ),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: rowTextStyle?.copyWith(
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
            child: Text(headerTitle, style: headerStyle),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxScrollHeight),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  selectableRow(
                    semanticLabel: allLabel,
                    selected: selectedId == null,
                    label: allLabel,
                    onTap: () {
                      if (selectedId != null) onPick(null);
                    },
                  ),
                  for (final option in options)
                    selectableRow(
                      semanticLabel: option.label,
                      selected: selectedId == option.id,
                      label: option.label,
                      onTap: () => onPick(option.id),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
