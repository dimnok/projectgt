import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/features/employees/presentation/providers/employee_timesheet_month_provider.dart';
import 'package:projectgt/features/employees/presentation/providers/employees_module_objects_provider.dart';
import 'package:projectgt/features/timesheet/presentation/widgets/timesheet_hours_loading_indicator.dart';

/// Вкладка «Табель» в карточке сотрудника.
///
/// Компактный просмотр месяца: сводка часов и полоска дней.
/// Данные загружаются при первом показе ([isActive] = true).
class EmployeeTimesheetSection extends ConsumerStatefulWidget {
  /// Сотрудник, чей табель отображается.
  final Employee employee;

  /// `true`, когда вкладка «Табель» выбрана (для ленивой загрузки).
  final bool isActive;

  /// Создаёт вкладку табеля сотрудника.
  const EmployeeTimesheetSection({
    super.key,
    required this.employee,
    this.isActive = true,
  });

  @override
  ConsumerState<EmployeeTimesheetSection> createState() =>
      _EmployeeTimesheetSectionState();
}

class _EmployeeTimesheetSectionState
    extends ConsumerState<EmployeeTimesheetSection> {
  late DateTime _monthStart;
  bool _wasActivated = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _monthStart = DateTime(now.year, now.month);
    _wasActivated = widget.isActive;
  }

  @override
  void didUpdateWidget(covariant EmployeeTimesheetSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Без setState: build родителя уже пересоберёт этот кадр.
    if (widget.isActive && !_wasActivated) {
      _wasActivated = true;
    }
  }

  EmployeeTimesheetMonthKey get _monthKey => EmployeeTimesheetMonthKey(
    employeeId: widget.employee.id,
    monthStart: _monthStart,
  );

  void _shiftMonth(int delta) {
    final next = DateTime(_monthStart.year, _monthStart.month + delta);
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    if (delta > 0 &&
        (next.year * 12 + next.month) >
            (currentMonth.year * 12 + currentMonth.month)) {
      return;
    }
    setState(() => _monthStart = next);
  }

  @override
  Widget build(BuildContext context) {
    if (!_wasActivated) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final asyncData = ref.watch(employeeTimesheetMonthProvider(_monthKey));
    final includeInTimesheet = widget.employee.includeInTimesheet;
    final objectNames = {
      for (final object in ref.watch(employeesModuleObjectsProvider))
        object.id: object.name,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!includeInTimesheet) ...[
          _ExcludedBanner(theme: theme),
          const SizedBox(height: 12),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: _MonthSwitcher(
            monthStart: _monthStart,
            onPrevious: () => _shiftMonth(-1),
            onNext: () => _shiftMonth(1),
          ),
        ),
        const SizedBox(height: 16),
        asyncData.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: TimesheetHoursLoadingIndicator(),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: SelectableText.rich(
              TextSpan(
                text: 'Не удалось загрузить табель.\n$error',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.error,
                ),
              ),
            ),
          ),
          data: (data) => _TimesheetMonthBody(
            monthStart: _monthStart,
            data: data,
            theme: theme,
            objectNames: objectNames,
          ),
        ),
      ],
    );
  }
}

class _TimesheetMonthBody extends StatelessWidget {
  const _TimesheetMonthBody({
    required this.monthStart,
    required this.data,
    required this.theme,
    required this.objectNames,
  });

  final DateTime monthStart;
  final EmployeeTimesheetMonthData data;
  final ThemeData theme;
  final Map<String, String> objectNames;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(monthStart.year, monthStart.month + 1, 0).day;
    final legend = data.objectsLegend;
    final colors = _TimesheetObjectColors.fromLegend(legend);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeroSummary(data: data, theme: theme),
        const SizedBox(height: 16),
        _MonthDaysStrip(
          monthStart: monthStart,
          daysInMonth: daysInMonth,
          data: data,
          theme: theme,
          objectNames: objectNames,
          colors: colors,
        ),
        if (legend.isNotEmpty) ...[
          const SizedBox(height: 20),
          _ObjectsLegend(
            legend: legend,
            objectNames: objectNames,
            colors: colors,
            theme: theme,
          ),
        ],
      ],
    );
  }
}

class _HeroSummary extends StatelessWidget {
  const _HeroSummary({required this.data, required this.theme});

  final EmployeeTimesheetMonthData data;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Часов за месяц',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatHours(data.totalHours),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 44,
            color: scheme.outline.withValues(alpha: 0.2),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Дней',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${data.daysWithHours}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.05,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Полоска дней месяца: сверху дата, посередине маркер, снизу часы.
///
/// Все дни всегда помещаются в доступную ширину без горизонтальной прокрутки.
class _MonthDaysStrip extends StatelessWidget {
  const _MonthDaysStrip({
    required this.monthStart,
    required this.daysInMonth,
    required this.data,
    required this.theme,
    required this.objectNames,
    required this.colors,
  });

  final DateTime monthStart;
  final int daysInMonth;
  final EmployeeTimesheetMonthData data;
  final ThemeData theme;
  final Map<String, String> objectNames;
  final _TimesheetObjectColors colors;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;

    return Semantics(
      label: 'Часы по дням месяца',
      child: Row(
        children: [
          for (var i = 1; i <= daysInMonth; i++) ...[
            if (i > 1) const SizedBox(width: 2),
            Expanded(
              child: Builder(
                builder: (context) {
                  final day = DateTime(monthStart.year, monthStart.month, i);
                  final hours = data.dayTotal(day);
                  final slices = data.objectsForDay(day);
                  final hasHours = hours > 0;
                  final isWeekend =
                      day.weekday == DateTime.saturday ||
                      day.weekday == DateTime.sunday;
                  final hoursLabel = hasHours ? _formatHours(hours) : '·';

                  return Tooltip(
                    message: _dayTooltip(
                      day: day,
                      hours: hours,
                      slices: slices,
                      objectNames: objectNames,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '$i',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              height: 1.1,
                              color: isWeekend
                                  ? scheme.error.withValues(alpha: 0.85)
                                  : scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        _DayHoursBar(
                          slices: slices,
                          hasHours: hasHours,
                          colors: colors,
                          emptyColor: scheme.outline.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 5),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            hoursLabel,
                            maxLines: 1,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              fontWeight: hasHours
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              height: 1.1,
                              color: hasHours
                                  ? scheme.onSurface
                                  : scheme.onSurface.withValues(alpha: 0.28),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DayHoursBar extends StatelessWidget {
  const _DayHoursBar({
    required this.slices,
    required this.hasHours,
    required this.colors,
    required this.emptyColor,
  });

  final List<EmployeeTimesheetObjectHours> slices;
  final bool hasHours;
  final _TimesheetObjectColors colors;
  final Color emptyColor;

  @override
  Widget build(BuildContext context) {
    if (!hasHours || slices.isEmpty) {
      return Container(
        height: 8,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          color: emptyColor,
        ),
      );
    }

    if (slices.length == 1) {
      return Container(
        height: 8,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          color: colors.colorFor(slices.first.objectId),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: 8,
        width: double.infinity,
        child: Row(
          children: [
            for (var i = 0; i < slices.length; i++) ...[
              if (i > 0) const SizedBox(width: 1),
              Expanded(
                flex: _barFlex(slices[i].hours),
                child: ColoredBox(color: colors.colorFor(slices[i].objectId)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ObjectsLegend extends StatelessWidget {
  const _ObjectsLegend({
    required this.legend,
    required this.objectNames,
    required this.colors,
    required this.theme,
  });

  final List<EmployeeTimesheetObjectHours> legend;
  final Map<String, String> objectNames;
  final _TimesheetObjectColors colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Легенда объектов за месяц',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < legend.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _LegendChip(
              name: _objectDisplayName(legend[i].objectId, objectNames),
              hours: legend[i].hours,
              color: colors.colorFor(legend[i].objectId),
              theme: theme,
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.name,
    required this.hours,
    required this.color,
    required this.theme,
  });

  final String name;
  final num hours;
  final Color color;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final hoursLabel = '${_formatHours(hours)} ч';

    return Semantics(
      label: '$name, $hoursLabel',
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.38)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                  color: scheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              hoursLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w500,
                height: 1.15,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Палитра цветов объектов на полоске дней и в легенде.
class _TimesheetObjectColors {
  const _TimesheetObjectColors(this._byId);

  final Map<String, Color> _byId;

  /// Назначает цвета по порядку легенды (больше часов — раньше в палитре).
  factory _TimesheetObjectColors.fromLegend(
    List<EmployeeTimesheetObjectHours> legend,
  ) {
    return _TimesheetObjectColors({
      for (var i = 0; i < legend.length; i++)
        legend[i].objectId: _kObjectPalette[i % _kObjectPalette.length],
    });
  }

  Color colorFor(String objectId) => _byId[objectId] ?? _kObjectPalette.first;
}

/// Контрастные цвета, читаемые в светлой и тёмной теме (без красного выходных).
const _kObjectPalette = <Color>[
  Color(0xFF5B8DEF),
  Color(0xFF3DCC8A),
  Color(0xFFE8B84A),
  Color(0xFFB07CE8),
  Color(0xFF2EC4B6),
  Color(0xFFE07A5F),
  Color(0xFF7AA2F7),
  Color(0xFF8FCB6D),
  Color(0xFFD4A017),
  Color(0xFF9B8EC8),
];

int _barFlex(num hours) {
  final scaled = (hours * 100).round();
  return scaled < 1 ? 1 : scaled;
}

String _objectDisplayName(String objectId, Map<String, String> names) {
  final name = names[objectId]?.trim();
  if (name != null && name.isNotEmpty) return name;
  return 'Объект';
}

String _dayTooltip({
  required DateTime day,
  required num hours,
  required List<EmployeeTimesheetObjectHours> slices,
  required Map<String, String> objectNames,
}) {
  final date = formatRuDate(day);
  if (hours <= 0) return date;

  final buffer = StringBuffer('$date — ${_formatHours(hours)} ч');
  for (final slice in slices) {
    buffer
      ..write('\n')
      ..write(_objectDisplayName(slice.objectId, objectNames))
      ..write(': ')
      ..write(_formatHours(slice.hours))
      ..write(' ч');
  }
  return buffer.toString();
}

class _ExcludedBanner extends StatelessWidget {
  const _ExcludedBanner({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(CupertinoIcons.info, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Не учитывается в табеле',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthSwitcher extends StatelessWidget {
  const _MonthSwitcher({
    required this.monthStart,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime monthStart;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  static const double _barHeight = 34;
  static const double _radius = 18;
  static const double _navWidth = 30;
  static const double _outerWidth = 184;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final viewed = DateTime(monthStart.year, monthStart.month);
    final canGoForward =
        (viewed.year * 12 + viewed.month) <
        (currentMonth.year * 12 + currentMonth.month);
    final accent = scheme.primary;
    final label = formatMonthYear(monthStart).replaceFirst(RegExp(r'\s+'), '-');

    Widget nav({
      required String tooltip,
      required IconData icon,
      required bool enabled,
      required VoidCallback? onTap,
    }) {
      return SizedBox(
        width: _navWidth,
        height: _barHeight,
        child: enabled && onTap != null
            ? Tooltip(
                message: tooltip,
                child: Semantics(
                  button: true,
                  label: tooltip,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(_radius),
                      onTap: onTap,
                      child: Icon(
                        icon,
                        size: 18,
                        color: accent.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ),
              )
            : ExcludeSemantics(
                child: Icon(
                  icon,
                  size: 18,
                  color: scheme.onSurface.withValues(alpha: 0.28),
                ),
              ),
      );
    }

    return SizedBox(
      width: _outerWidth,
      height: _barHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(
            color: scheme.primary.withValues(alpha: 0.62),
            width: 1.25,
          ),
          color: scheme.primary.withValues(alpha: 0.14),
        ),
        child: Row(
          children: [
            nav(
              tooltip: 'Предыдущий месяц',
              icon: Icons.chevron_left_rounded,
              enabled: true,
              onTap: onPrevious,
            ),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  height: 1.2,
                  color: accent,
                ),
              ),
            ),
            nav(
              tooltip: 'Следующий месяц',
              icon: Icons.chevron_right_rounded,
              enabled: canGoForward,
              onTap: canGoForward ? onNext : null,
            ),
          ],
        ),
      ),
    );
  }
}

String _formatHours(num hours) {
  if (hours == 0) return '0';
  final asDouble = hours.toDouble();
  if (asDouble == asDouble.truncateToDouble()) {
    return asDouble.toInt().toString();
  }
  return formatQuantity(hours);
}
