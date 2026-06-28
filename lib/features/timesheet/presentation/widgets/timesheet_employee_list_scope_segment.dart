import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'timesheet_filter_widget.dart';

/// Сегментированный выбор состава списка: все / с часами / без часов за период.
///
/// Визуально согласован с [TimesheetObjectsBarDropdown] (высота, скругление, обводка).
class TimesheetEmployeeListScopeSegment extends ConsumerWidget {
  /// Создаёт сегмент для панели над таблицей табеля.
  const TimesheetEmployeeListScopeSegment({super.key});

  static const double _height = 34;
  static const double _radius = 18;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final scope = ref.watch(timesheetEmployeeListScopeProvider);
    final notifier = ref.read(timesheetEmployeeListScopeProvider.notifier);

    final borderColor = scheme.outline.withValues(alpha: 0.38);
    final trackFill = scheme.surfaceContainerHighest.withValues(alpha: 0.45);
    final selectedFill = scheme.surface;
    final outlineSelected = scheme.outline.withValues(alpha: 0.22);
    final shadowSoft = scheme.shadow.withValues(alpha: 0.1);

    TextStyle segmentText(bool selected) {
      final base = theme.textTheme.labelLarge ?? theme.textTheme.bodyMedium!;
      return base.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 12.5,
        height: 1.1,
        color: selected
            ? scheme.onSurface
            : scheme.onSurface.withValues(alpha: 0.52),
      );
    }

    Widget segment({
      required String label,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(_radius - 3),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_radius - 3),
                color: selected ? selectedFill : Colors.transparent,
                border: Border.all(
                  color: selected ? outlineSelected : Colors.transparent,
                  width: 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: shadowSoft,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: segmentText(selected),
              ),
            ),
          ),
        ),
      );
    }

    String semanticsLine() {
      return switch (scope) {
        TimesheetEmployeeListScope.all => 'Список: все сотрудники',
        TimesheetEmployeeListScope.withHours => 'Список: только с часами',
        TimesheetEmployeeListScope.withoutHours => 'Список: только без часов',
      };
    }

    return Tooltip(
      message:
          'Каких сотрудников показывать: все, с суммой часов в периоде или с нулевыми часами',
      child: Semantics(
        label: semanticsLine(),
        button: true,
        child: SizedBox(
          width: 264,
          height: _height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_radius),
              border: Border.all(color: borderColor),
              color: trackFill,
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Row(
                children: [
                  segment(
                    label: 'Все',
                    selected: scope == TimesheetEmployeeListScope.all,
                    onTap: () {
                      if (scope != TimesheetEmployeeListScope.all) {
                        notifier.state = TimesheetEmployeeListScope.all;
                      }
                    },
                  ),
                  segment(
                    label: 'С часами',
                    selected: scope == TimesheetEmployeeListScope.withHours,
                    onTap: () {
                      if (scope != TimesheetEmployeeListScope.withHours) {
                        notifier.state = TimesheetEmployeeListScope.withHours;
                      }
                    },
                  ),
                  segment(
                    label: 'Без часов',
                    selected: scope == TimesheetEmployeeListScope.withoutHours,
                    onTap: () {
                      if (scope != TimesheetEmployeeListScope.withoutHours) {
                        notifier.state =
                            TimesheetEmployeeListScope.withoutHours;
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
