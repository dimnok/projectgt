import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/timesheet_position_filter.dart';
import '../providers/timesheet_filters_providers.dart';

/// Плотный выпадающий фильтр по должностям в строке над сеткой табеля.
///
/// Визуально согласован с [TimesheetObjectsBarDropdown] (высота 34, MenuAnchor).
/// Только UI: экспорт Excel фильтр не применяет.
class TimesheetPositionsBarDropdown extends ConsumerWidget {
  /// Создаёт выпадающий фильтр должностей для панели табеля.
  const TimesheetPositionsBarDropdown({super.key});

  static const double _triggerHeight = 34;
  static const double _triggerRadius = 18;
  static const double _menuMaxHeight = 220;
  static const double _menuWidth = 220;

  static String _triggerLabel(
    Set<String> selected,
    List<TimesheetPositionFilterOption> options,
  ) {
    if (selected.isEmpty) return 'Все должности';
    if (selected.length == 1) {
      final key = selected.first;
      for (final o in options) {
        if (o.key == key) return o.label;
      }
      if (key == kTimesheetNoPositionFilterKey) {
        return kTimesheetNoPositionFilterLabel;
      }
      return key;
    }
    return 'Должности · ${selected.length}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final options = ref.watch(availablePositionsForTimesheetProvider);
    final selected = ref.watch(timesheetSelectedPositionKeysProvider);
    final label = _triggerLabel(selected, options);
    final textStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 14,
      height: 1.2,
      color: scheme.onSurface,
    );
    final borderColor = scheme.outline.withValues(alpha: 0.38);
    final fill = scheme.surfaceContainerHighest.withValues(alpha: 0.45);
    final iconMuted = scheme.onSurface.withValues(alpha: 0.55);

    if (options.isEmpty) {
      return Tooltip(
        message: 'Нет должностей для фильтра',
        child: Container(
          height: _triggerHeight,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_triggerRadius),
            border: Border.all(color: borderColor),
            color: fill,
          ),
          child: Text(
            'Должности',
            style: textStyle?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.45),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    void commitSelection(Set<String> keys) {
      ref.read(timesheetSelectedPositionKeysProvider.notifier).state = keys;
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
        _TimesheetPositionFilterMenu(
          key: ValueKey(options.map((e) => e.key).join('\x1e')),
          width: _menuWidth,
          maxScrollHeight: _menuMaxHeight,
          options: options,
          selectedKeys: selected,
          onCommitSelection: commitSelection,
        ),
      ],
      builder: (context, menuController, _) {
        return Tooltip(
          message: 'Фильтр по должностям',
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(_triggerRadius),
            child: InkWell(
              borderRadius: BorderRadius.circular(_triggerRadius),
              onTap: () {
                if (menuController.isOpen) {
                  menuController.close();
                } else {
                  menuController.open();
                }
              },
              child: Ink(
                height: _triggerHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_triggerRadius),
                  border: Border.all(color: borderColor),
                  color: fill,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.badge_outlined,
                        size: 18,
                        color: iconMuted,
                      ),
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
                        color: iconMuted,
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

/// Содержимое меню должностей: мультивыбор с галочками.
class _TimesheetPositionFilterMenu extends StatelessWidget {
  /// Создаёт панель выбора должностей.
  const _TimesheetPositionFilterMenu({
    super.key,
    required this.width,
    required this.maxScrollHeight,
    required this.options,
    required this.selectedKeys,
    required this.onCommitSelection,
  });

  final double width;
  final double maxScrollHeight;
  final List<TimesheetPositionFilterOption> options;
  final Set<String> selectedKeys;
  final ValueChanged<Set<String>> onCommitSelection;

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
                      maxLines: 1,
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
            child: Text('ДОЛЖНОСТИ', style: headerStyle),
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
                    semanticLabel: 'Все должности',
                    selected: selectedKeys.isEmpty,
                    label: 'Все должности',
                    onTap: () {
                      if (selectedKeys.isNotEmpty) {
                        onCommitSelection(const {});
                      }
                    },
                  ),
                  for (final option in options)
                    selectableRow(
                      semanticLabel: option.label,
                      selected: selectedKeys.contains(option.key),
                      label: option.label,
                      onTap: () {
                        final next = Set<String>.from(selectedKeys);
                        if (next.contains(option.key)) {
                          next.remove(option.key);
                        } else {
                          next.add(option.key);
                        }
                        onCommitSelection(next);
                      },
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
