import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'timesheet_filter_widget.dart';

/// Единый фильтр состава списка: часы за период и смена сегодня.
///
/// Заменяет два сегментированных переключателя одной кнопкой в стиле
/// [TimesheetObjectsBarDropdown] / [TimesheetPositionsBarDropdown].
class TimesheetListFilterDropdown extends ConsumerWidget {
  /// Создаёт выпадающий фильтр состава списка.
  const TimesheetListFilterDropdown({
    super.key,
    required this.periodContainsToday,
  });

  /// Сегодня попадает в отображаемый период табеля.
  final bool periodContainsToday;

  static const double _triggerHeight = 34;
  static const double _triggerRadius = 18;
  static const double _menuWidth = 248;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hoursScope = ref.watch(timesheetEmployeeListScopeProvider);
    final shiftScope = ref.watch(timesheetOpenShiftFilterScopeProvider);
    final isActive = hasActiveTimesheetListFilters(
      hoursScope: hoursScope,
      shiftScope: shiftScope,
      periodContainsToday: periodContainsToday,
    );
    final label = timesheetListFilterTriggerLabel(
      hoursScope: hoursScope,
      shiftScope: shiftScope,
      periodContainsToday: periodContainsToday,
    );

    final borderColor = isActive
        ? scheme.primary.withValues(alpha: 0.62)
        : scheme.outline.withValues(alpha: 0.38);
    final fill = isActive
        ? scheme.primary.withValues(alpha: 0.1)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.45);
    final iconMuted = scheme.onSurface.withValues(alpha: 0.55);
    final textStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 14,
      height: 1.2,
      color: isActive ? scheme.primary : scheme.onSurface,
    );

    void setHoursScope(TimesheetEmployeeListScope scope) {
      ref.read(timesheetEmployeeListScopeProvider.notifier).state = scope;
    }

    void setShiftScope(TimesheetOpenShiftFilterScope scope) {
      ref.read(timesheetOpenShiftFilterScopeProvider.notifier).state = scope;
    }

    void resetAll() {
      setHoursScope(TimesheetEmployeeListScope.all);
      setShiftScope(TimesheetOpenShiftFilterScope.all);
    }

    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(scheme.surface),
        elevation: const WidgetStatePropertyAll(8),
        shadowColor: WidgetStatePropertyAll(
          scheme.shadow.withValues(alpha: 0.2),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: borderColor),
          ),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
      ),
      menuChildren: [
        _TimesheetListFilterMenu(
          width: _menuWidth,
          periodContainsToday: periodContainsToday,
          hoursScope: hoursScope,
          shiftScope: shiftScope,
          isActive: isActive,
          onHoursScopeChanged: setHoursScope,
          onShiftScopeChanged: setShiftScope,
          onReset: resetAll,
        ),
      ],
      builder: (context, menuController, _) {
        return Tooltip(
          message: 'Фильтр состава списка: часы и смена сегодня',
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
                      Icon(
                        Icons.tune_rounded,
                        size: 18,
                        color: isActive ? scheme.primary : iconMuted,
                      ),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
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
                        color: isActive ? scheme.primary : iconMuted,
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

class _TimesheetListFilterMenu extends StatelessWidget {
  const _TimesheetListFilterMenu({
    required this.width,
    required this.periodContainsToday,
    required this.hoursScope,
    required this.shiftScope,
    required this.isActive,
    required this.onHoursScopeChanged,
    required this.onShiftScopeChanged,
    required this.onReset,
  });

  final double width;
  final bool periodContainsToday;
  final TimesheetEmployeeListScope hoursScope;
  final TimesheetOpenShiftFilterScope shiftScope;
  final bool isActive;
  final ValueChanged<TimesheetEmployeeListScope> onHoursScopeChanged;
  final ValueChanged<TimesheetOpenShiftFilterScope> onShiftScopeChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final headerStyle = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 11,
      letterSpacing: 0.4,
      height: 1.1,
      color: scheme.onSurface.withValues(alpha: 0.55),
    );
    final rowTextStyle = theme.textTheme.bodyMedium?.copyWith(
      fontSize: 13.5,
      height: 1.15,
      color: scheme.onSurface,
    );
    final dividerColor = scheme.outline.withValues(alpha: 0.14);

    Widget sectionHeader(String title) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
        child: Text(title, style: headerStyle),
      );
    }

    Widget radioRow({
      required String label,
      required String semanticsLabel,
      required bool selected,
      required VoidCallback onTap,
      IconData? icon,
    }) {
      return Semantics(
        button: true,
        selected: selected,
        label: semanticsLabel,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
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
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                  ],
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
          sectionHeader('ЧАСЫ ЗА ПЕРИОД'),
          radioRow(
            label: 'Все сотрудники',
            semanticsLabel: 'Часы: все сотрудники',
            selected: hoursScope == TimesheetEmployeeListScope.all,
            onTap: () => onHoursScopeChanged(TimesheetEmployeeListScope.all),
            icon: Icons.people_outline_rounded,
          ),
          radioRow(
            label: 'С отработанными часами',
            semanticsLabel: 'Часы: с отработанными часами',
            selected: hoursScope == TimesheetEmployeeListScope.withHours,
            onTap: () =>
                onHoursScopeChanged(TimesheetEmployeeListScope.withHours),
            icon: Icons.schedule_rounded,
          ),
          radioRow(
            label: 'Без часов в периоде',
            semanticsLabel: 'Часы: без часов в периоде',
            selected: hoursScope == TimesheetEmployeeListScope.withoutHours,
            onTap: () =>
                onHoursScopeChanged(TimesheetEmployeeListScope.withoutHours),
            icon: Icons.hourglass_empty_rounded,
          ),
          if (periodContainsToday) ...[
            Divider(height: 1, thickness: 1, color: dividerColor),
            sectionHeader('СМЕНА СЕГОДНЯ'),
            radioRow(
              label: 'Все',
              semanticsLabel: 'Смена: все',
              selected: shiftScope == TimesheetOpenShiftFilterScope.all,
              onTap: () => onShiftScopeChanged(TimesheetOpenShiftFilterScope.all),
            ),
            radioRow(
              label: 'В открытой смене *',
              semanticsLabel: 'Смена: в открытой смене',
              selected: shiftScope == TimesheetOpenShiftFilterScope.inOpenShift,
              onTap: () => onShiftScopeChanged(
                TimesheetOpenShiftFilterScope.inOpenShift,
              ),
            ),
            radioRow(
              label: 'Не в смене',
              semanticsLabel: 'Смена: не в смене',
              selected:
                  shiftScope == TimesheetOpenShiftFilterScope.notInOpenShift,
              onTap: () => onShiftScopeChanged(
                TimesheetOpenShiftFilterScope.notInOpenShift,
              ),
            ),
          ],
          if (isActive) ...[
            Divider(height: 1, thickness: 1, color: dividerColor),
            Semantics(
              button: true,
              label: 'Сбросить фильтры состава',
              child: TextButton(
                onPressed: onReset,
                style: TextButton.styleFrom(
                  foregroundColor: scheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                child: const Text('Сбросить'),
              ),
            ),
          ] else
            const SizedBox(height: 6),
        ],
      ),
    );
  }
}
