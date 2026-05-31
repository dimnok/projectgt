import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/features/employees/presentation/utils/employees_layout_utils.dart';
import 'package:projectgt/features/timesheet/domain/timesheet_attendance_stats.dart';
import 'package:projectgt/features/timesheet/presentation/providers/timesheet_filters_providers.dart';
import 'package:projectgt/features/timesheet/presentation/providers/timesheet_provider.dart';

/// Ориентир ширины кнопки «Статистика» в панели фильтров (для раскладки поиска).
const double kTimesheetAttendanceStatsTriggerWidth = 126;

/// Ширина диалога статистики на десктопе.
const double kTimesheetAttendanceStatsDialogWidth = 1040;

/// Кнопка и окно со статистикой посещаемости за выбранный месяц.
class TimesheetAttendanceStatsAction extends ConsumerWidget {
  /// Создаёт действие открытия статистики посещаемости.
  const TimesheetAttendanceStatsAction({super.key});

  static const double _triggerHeight = 34;
  static const double _triggerRadius = 18;
  static const double _iconSize = 18;
  static const double _fontSize = 14;

  static BoxDecoration _triggerDecoration(
    ColorScheme scheme, {
    required bool enabled,
  }) {
    if (!enabled) {
      return BoxDecoration(
        borderRadius: BorderRadius.circular(_triggerRadius),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.22)),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.28),
      );
    }
    return BoxDecoration(
      borderRadius: BorderRadius.circular(_triggerRadius),
      border: Border.all(color: scheme.primary.withValues(alpha: 0.45)),
      gradient: LinearGradient(
        colors: [
          scheme.primary.withValues(alpha: 0.18),
          scheme.tertiary.withValues(alpha: 0.12),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: scheme.primary.withValues(alpha: 0.12),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ts = ref.watch(timesheetProvider);
    final busy = ts.isLoading;
    final hasEmployees = ts.employees.isNotEmpty;
    final enabled = !busy && hasEmployees;

    final textStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: _fontSize,
      height: 1.2,
      color: enabled
          ? scheme.primary
          : scheme.onSurface.withValues(alpha: 0.45),
    );
    final iconColor = enabled
        ? scheme.primary
        : scheme.onSurface.withValues(alpha: 0.35);

    return Tooltip(
      message: 'Топ-5 по посещаемости за месяц',
      child: Semantics(
        button: true,
        label: 'Статистика посещаемости',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(_triggerRadius),
            onTap: enabled
                ? () {
                    final result = computeTimesheetAttendanceStats(
                      employees: ts.employees,
                      entries: ts.entries,
                      startDate: ts.startDate,
                      endDate: ts.endDate,
                      hasObjectFilter:
                          ts.selectedObjectIds?.isNotEmpty ?? false,
                      positionKeys: ref.read(
                        timesheetSelectedPositionKeysProvider,
                      ),
                    );
                    _openStatsWithMonth(context, result, ts.startDate);
                  }
                : null,
            child: Container(
              height: _triggerHeight,
              constraints: const BoxConstraints(
                minWidth: _triggerHeight,
                maxWidth: 140,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: _triggerDecoration(scheme, enabled: enabled),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final iconOnly =
                      constraints.maxWidth.isFinite &&
                      constraints.maxWidth < 92;

                  if (iconOnly) {
                    return Center(
                      child: Icon(
                        Icons.insights_outlined,
                        size: _iconSize,
                        color: iconColor,
                      ),
                    );
                  }

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.insights_outlined,
                        size: _iconSize,
                        color: iconColor,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Статистика',
                          style: textStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void _openStatsWithMonth(
    BuildContext context,
    TimesheetAttendanceStatsResult data,
    DateTime monthStart,
  ) {
    final monthLabel = formatMonthYear(monthStart);
    final title = monthLabel.isEmpty
        ? 'Посещаемость за месяц'
        : 'Посещаемость · $monthLabel';

    if (EmployeesLayoutUtils.useEmployeesDesktopModal(context)) {
      DesktopDialogContent.show<void>(
        context,
        title: title,
        width: kTimesheetAttendanceStatsDialogWidth,
        scrollable: true,
        child: TimesheetAttendanceStatsBody(result: data),
      );
      return;
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(maxWidth: screenWidth),
      builder: (ctx) => MobileBottomSheetContent(
        title: title,
        child: TimesheetAttendanceStatsBody(result: data),
      ),
    );
  }
}

/// Палитра секции «высокая посещаемость».
class _HighAttendancePalette {
  static const Color accent = Color(0xFF2E7D32);
  static const Color accentLight = Color(0xFF66BB6A);

  static List<Color> gradient(ColorScheme scheme) => [
    const Color(0xFF1B5E20).withValues(alpha: 0.14),
    const Color(0xFF43A047).withValues(alpha: 0.08),
  ];

  static const List<Color> barGradient = [
    Color(0xFF43A047),
    Color(0xFF81C784),
  ];
}

/// Палитра секции «низкая посещаемость».
class _LowAttendancePalette {
  static const Color accent = Color(0xFFC62828);
  static const Color accentLight = Color(0xFFEF5350);

  static List<Color> gradient(ColorScheme scheme) => [
    const Color(0xFFB71C1C).withValues(alpha: 0.12),
    scheme.error.withValues(alpha: 0.06),
  ];

  static const List<Color> barGradient = [
    Color(0xFFE53935),
    Color(0xFFFF8A80),
  ];
}

/// Содержимое окна статистики посещаемости.
class TimesheetAttendanceStatsBody extends StatelessWidget {
  /// Создаёт тело диалога.
  const TimesheetAttendanceStatsBody({super.key, required this.result});

  /// Рассчитанные топы.
  final TimesheetAttendanceStatsResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (result.totalEmployeesConsidered == 0) {
      return _EmptyStatsState(scheme: scheme, theme: theme);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 640;

        final highSection = _StatsSection(
          title: 'Высокая посещаемость',
          subtitle: 'Топ-5 по отработанным дням',
          icon: Icons.emoji_events_rounded,
          accent: _HighAttendancePalette.accent,
          accentLight: _HighAttendancePalette.accentLight,
          gradientColors: _HighAttendancePalette.gradient(scheme),
          barGradient: _HighAttendancePalette.barGradient,
          emptyHint: 'Недостаточно данных',
          items: result.topHighAttendance,
        );

        final lowSection = _StatsSection(
          title: 'Низкая посещаемость',
          subtitle: 'Топ-5 с наименьшим охватом дней',
          icon: Icons.trending_down_rounded,
          accent: _LowAttendancePalette.accent,
          accentLight: _LowAttendancePalette.accentLight,
          gradientColors: _LowAttendancePalette.gradient(scheme),
          barGradient: _LowAttendancePalette.barGradient,
          emptyHint: 'Недостаточно данных',
          items: result.topLowAttendance,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SummaryBanner(
              totalEmployees: result.totalEmployeesConsidered,
              scheme: scheme,
              theme: theme,
            ),
            const SizedBox(height: 20),
            if (wide)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: highSection),
                    const SizedBox(width: 16),
                    Expanded(child: lowSection),
                  ],
                ),
              )
            else ...[
              highSection,
              const SizedBox(height: 16),
              lowSection,
            ],
          ],
        );
      },
    );
  }
}

class _EmptyStatsState extends StatelessWidget {
  const _EmptyStatsState({required this.scheme, required this.theme});

  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      ),
      child: Column(
        children: [
          Icon(
            Icons.groups_outlined,
            size: 40,
            color: scheme.onSurface.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 12),
          Text(
            'Нет сотрудников для расчёта с текущими фильтрами.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({
    required this.totalEmployees,
    required this.scheme,
    required this.theme,
  });

  final int totalEmployees;
  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            scheme.primary.withValues(alpha: 0.22),
            scheme.tertiary.withValues(alpha: 0.14),
            scheme.surfaceContainerHighest.withValues(alpha: 0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  scheme.primary,
                  scheme.tertiary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.35),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(
              Icons.calendar_month_rounded,
              color: scheme.onPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'В расчёте $totalEmployees сотрудников',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Посещаемость — доля календарных дней месяца с отмеченными '
                  'часами. Учитываются фильтры объектов и должностей.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.65),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.accentLight,
    required this.gradientColors,
    required this.barGradient,
    required this.emptyHint,
    required this.items,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Color accentLight;
  final List<Color> gradientColors;
  final List<Color> barGradient;
  final String emptyHint;
  final List<TimesheetEmployeeAttendanceStat> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withValues(alpha: 0.3)),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                emptyHint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            )
          else
            ...List.generate(items.length, (index) {
              return _StatRow(
                rank: index + 1,
                stat: items[index],
                accent: accent,
                accentLight: accentLight,
                barGradient: barGradient,
              );
            }),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.rank,
    required this.stat,
    required this.accent,
    required this.accentLight,
    required this.barGradient,
  });

  final int rank;
  final TimesheetEmployeeAttendanceStat stat;
  final Color accent;
  final Color accentLight;
  final List<Color> barGradient;

  /// Медали: золото / серебро / бронза — контрастные, без пересечения оранжевых тонов.
  ({Color bg, Color fg, Color ring, IconData? icon}) _rankStyle(
    Brightness brightness,
  ) {
    final isDark = brightness == Brightness.dark;
    switch (rank) {
      case 1:
        return (
          bg: isDark ? const Color(0xFF5D4037).withValues(alpha: 0.35) : const Color(0xFFFFF8E1),
          fg: isDark ? const Color(0xFFFFD54F) : const Color(0xFFF9A825),
          ring: const Color(0xFFFFB300),
          icon: Icons.looks_one_rounded,
        );
      case 2:
        return (
          bg: isDark ? const Color(0xFF455A64).withValues(alpha: 0.4) : const Color(0xFFECEFF1),
          fg: isDark ? const Color(0xFFB0BEC5) : const Color(0xFF78909C),
          ring: isDark ? const Color(0xFF90A4AE) : const Color(0xFFB0BEC5),
          icon: Icons.looks_two_rounded,
        );
      case 3:
        return (
          bg: isDark ? const Color(0xFF4E342E).withValues(alpha: 0.35) : const Color(0xFFEFEBE9),
          fg: isDark ? const Color(0xFFA1887F) : const Color(0xFF6D4C41),
          ring: const Color(0xFF8D6E63),
          icon: Icons.looks_3_rounded,
        );
      default:
        return (
          bg: accent.withValues(alpha: 0.12),
          fg: accent,
          ring: accent.withValues(alpha: 0.4),
          icon: null,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rankStyle = _rankStyle(theme.brightness);
    final percent = stat.attendancePercent.clamp(0, 100).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: scheme.surface.withValues(alpha: theme.brightness == Brightness.dark ? 0.55 : 0.92),
        border: Border.all(
          color: rank <= 3
              ? rankStyle.ring.withValues(alpha: 0.55)
              : scheme.outline.withValues(alpha: 0.12),
          width: rank <= 3 ? 1.5 : 1,
        ),
        boxShadow: rank <= 3
            ? [
                BoxShadow(
                  color: rankStyle.ring.withValues(alpha: 0.18),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RankBadge(
                rank: rank,
                style: rankStyle,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stat.displayName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (stat.position != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        stat.position!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _PercentChip(
                percent: percent,
                accent: accent,
                accentLight: accentLight,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _AttendanceProgressBar(
            value: percent / 100,
            gradient: barGradient,
            backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _MetricChip(
                icon: Icons.event_available_rounded,
                label: '${stat.workedDays} / ${stat.totalDaysInPeriod} дн.',
                color: accent,
              ),
              _MetricChip(
                icon: Icons.schedule_rounded,
                label: '${formatQuantity(stat.totalHours)} ч',
                color: accentLight,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank, required this.style});

  final int rank;
  final ({Color bg, Color fg, Color ring, IconData? icon}) style;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: style.bg,
        border: Border.all(color: style.ring, width: 2),
        boxShadow: [
          BoxShadow(
            color: style.ring.withValues(alpha: 0.28),
            blurRadius: 5,
          ),
        ],
      ),
      child: Center(
        child: style.icon != null
            ? Icon(style.icon, size: 20, color: style.fg)
            : Text(
                '$rank',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: style.fg,
                ),
              ),
      ),
    );
  }
}

class _PercentChip extends StatelessWidget {
  const _PercentChip({
    required this.percent,
    required this.accent,
    required this.accentLight,
  });

  final double percent;
  final Color accent;
  final Color accentLight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [accent, accentLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        formatPercentage(percent, decimalDigits: 0),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _AttendanceProgressBar extends StatelessWidget {
  const _AttendanceProgressBar({
    required this.value,
    required this.gradient,
    required this.backgroundColor,
  });

  final double value;
  final List<Color> gradient;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 8,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: backgroundColor),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value.clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.first.withValues(alpha: 0.4),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }
}
