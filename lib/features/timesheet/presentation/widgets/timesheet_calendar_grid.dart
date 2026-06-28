import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/features/timesheet/domain/entities/timesheet_entry.dart';
import 'package:projectgt/features/timesheet/domain/timesheet_today_open_shift.dart';

/// Геометрия календарной сетки табеля (шапка + строки + итог).
abstract final class TimesheetGridLayout {
  /// Ширина колонки чекбокса.
  static const double selectColWidth = 44;

  /// Ширина колонки ФИО.
  static const double employeeColWidth = 240;

  /// Ширина колонки дня.
  static const double dayColWidth = 40;

  /// Ширина колонки «Итого» (компактно под числа до «999,999»).
  static const double totalColWidth = 52;

  /// Отступ между шапкой и телом.
  static const double headerGap = 4;

  /// Фиксированная высота строки сотрудника ([ListView.itemExtent]).
  static const double dataRowHeight = 42;

  /// Высота строки итогов.
  static const double totalsRowHeight = 38;

  /// Минимальная ширина таблицы при [dayCount] днях в периоде.
  static double minTableWidth(int dayCount) =>
      selectColWidth +
      employeeColWidth +
      dayCount * dayColWidth +
      totalColWidth;

  /// Ширина сетки: на всю область, но не уже [minTableWidth] (горизонтальный скролл).
  static double layoutWidth(int dayCount, double viewportWidth) {
    final safeViewport = viewportWidth.isFinite && viewportWidth > 0
        ? viewportWidth
        : minTableWidth(dayCount);
    return safeViewport > minTableWidth(dayCount)
        ? safeViewport
        : minTableWidth(dayCount);
  }

  /// Ключ дня `yyyy-MM-dd` для индекса записей.
  static String dayKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Локальный календарный «сегодня» для подсветки колонки.
  static bool isCalendarToday(DateTime day) {
    final now = DateTime.now();
    return day.year == now.year && day.month == now.month && day.day == now.day;
  }

  /// Цвет звёздочки «в открытой смене».
  static Color openShiftStarColor(ColorScheme scheme) => scheme.tertiary;

  /// Лёгкий фон строки при выборе чекбоксом.
  static Color selectedRowBackground(
    ColorScheme scheme,
    Brightness brightness,
  ) {
    return scheme.primary.withValues(
      alpha: brightness == Brightness.dark ? 0.14 : 0.08,
    );
  }

  /// Цвет уголкового маркера примечания в ячейке дня.
  static Color commentCornerColor(ColorScheme scheme, Brightness brightness) {
    return brightness == Brightness.dark
        ? scheme.primary
        : scheme.primary.withValues(alpha: 0.92);
  }

  /// Размер уголкового маркера примечания.
  static const double commentCornerSize = 9;
}

/// Фиксированные и гибкая (ФИО) ячейки строки сетки.
abstract final class _TimesheetGridCells {
  static Widget fixed({
    required double width,
    required Color dividerColor,
    required Widget child,
    bool showRightBorder = true,
  }) {
    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            right: showRightBorder
                ? BorderSide(color: dividerColor)
                : BorderSide.none,
          ),
        ),
        child: child,
      ),
    );
  }

  /// Колонка «Сотрудник» забирает свободную ширину (как `1fr` в CSS Grid).
  static Widget employee({required Color dividerColor, required Widget child}) {
    return Expanded(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: TimesheetGridLayout.employeeColWidth,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: dividerColor)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Шапка сетки: чекбокс, ФИО, дни, итого.
class TimesheetGridHeader extends StatelessWidget {
  /// Дни периода (колонки).
  final List<DateTime> daysInRange;

  /// Цвет линий сетки.
  final Color dividerColor;

  /// Фон шапки.
  final Color headerBackground;

  /// Состояние «выбрать всех» (`null` — частичный выбор).
  final bool? selectAllValue;

  /// Переключение выбора всех видимых строк.
  final ValueChanged<bool?> onSelectAllChanged;

  /// Создаёт шапку сетки табеля.
  const TimesheetGridHeader({
    super.key,
    required this.daysInRange,
    required this.dividerColor,
    required this.headerBackground,
    required this.selectAllValue,
    required this.onSelectAllChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.bold,
    );

    return ColoredBox(
      color: headerBackground,
      child: DecoratedBox(
        decoration: BoxDecoration(border: Border.all(color: dividerColor)),
        child: Row(
          children: [
            _TimesheetGridCells.fixed(
              width: TimesheetGridLayout.selectColWidth,
              dividerColor: dividerColor,
              child: Padding(
                padding: const EdgeInsets.only(left: 6, right: 2),
                child: Tooltip(
                  message: 'Выбрать всех отображаемых сотрудников',
                  child: _TimesheetGridCheckbox(
                    value: selectAllValue,
                    tristate: true,
                    semanticLabel: 'Выбрать всех сотрудников в таблице',
                    onChanged: onSelectAllChanged,
                  ),
                ),
              ),
            ),
            _TimesheetGridCells.employee(
              dividerColor: dividerColor,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Сотрудник', style: headerStyle),
                ),
              ),
            ),
            for (final day in daysInRange)
              _TimesheetGridCells.fixed(
                width: TimesheetGridLayout.dayColWidth,
                dividerColor: dividerColor,
                child: _DayHeaderCell(
                  theme: theme,
                  day: day,
                  headerStyle: headerStyle,
                ),
              ),
            _TimesheetGridCells.fixed(
              width: TimesheetGridLayout.totalColWidth,
              dividerColor: dividerColor,
              showRightBorder: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                child: Center(
                  child: Text(
                    'Итого',
                    style: headerStyle?.copyWith(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayHeaderCell extends StatelessWidget {
  const _DayHeaderCell({
    required this.theme,
    required this.day,
    required this.headerStyle,
  });

  final ThemeData theme;
  final DateTime day;
  final TextStyle? headerStyle;

  @override
  Widget build(BuildContext context) {
    final isWeekend =
        day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
    final isToday = TimesheetGridLayout.isCalendarToday(day);
    final scheme = theme.colorScheme;
    final dayColor = isToday
        ? scheme.primary.withValues(alpha: 0.16)
        : isWeekend
        ? scheme.error.withValues(alpha: 0.18)
        : scheme.surface.withValues(alpha: 0.5);
    final textColor = isToday
        ? scheme.primary
        : isWeekend
        ? scheme.error
        : theme.textTheme.bodySmall?.color;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${day.day}',
            style: headerStyle?.copyWith(fontSize: 13, color: textColor),
          ),
          const SizedBox(height: 1),
          DecoratedBox(
            decoration: BoxDecoration(
              color: dayColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                formatRuWeekdayShort(day).toLowerCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: textColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Одна строка сотрудника в виртуализированной сетке.
class TimesheetGridEmployeeRow extends StatelessWidget {
  /// Сотрудник строки.
  final Employee employee;

  /// Дни периода.
  final List<DateTime> daysInRange;

  /// `yyyy-MM-dd` → записи за день для [employee].
  final Map<String, List<TimesheetEntry>> entriesByDayKey;

  /// Назначения в открытых сменах на сегодня.
  final TimesheetTodayOpenShiftIndex todayOpenShift;

  /// Строка отмечена чекбоксом.
  final bool isSelected;

  /// Цвет линий сетки.
  final Color dividerColor;

  /// Переключение чекбокса строки.
  final ValueChanged<bool?> onSelectionChanged;

  /// Открыть диалог посещаемости.
  final VoidCallback onEmployeeTap;

  /// Тап по ячейке дня с часами.
  final void Function(
    List<TimesheetEntry> entries,
    String employeeName,
    DateTime day,
  )
  onDayWithHoursTap;

  /// Создаёт строку сетки табеля.
  const TimesheetGridEmployeeRow({
    super.key,
    required this.employee,
    required this.daysInRange,
    required this.entriesByDayKey,
    required this.todayOpenShift,
    required this.isSelected,
    required this.dividerColor,
    required this.onSelectionChanged,
    required this.onEmployeeTap,
    required this.onDayWithHoursTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final employeeName = formatFullName(
      employee.lastName,
      employee.firstName,
      employee.middleName,
    );

    num totalHours = 0;
    final dayWidgets = <Widget>[];

    for (final day in daysInRange) {
      final key = TimesheetGridLayout.dayKey(day);
      final dayEntries = entriesByDayKey[key] ?? const <TimesheetEntry>[];
      final dayHours = dayEntries.fold<num>(0, (s, e) => s + e.hours);
      totalHours += dayHours;
      final commentTooltip = _timesheetDayCommentsTooltip(dayEntries);
      final isToday = TimesheetGridLayout.isCalendarToday(day);
      final inOpenShiftToday =
          isToday && todayOpenShift.contains(employee.id);
      final openShiftTooltip = inOpenShiftToday
          ? todayOpenShift.hintFor(employee.id)
          : null;

      dayWidgets.add(
        _TimesheetGridCells.fixed(
          width: TimesheetGridLayout.dayColWidth,
          dividerColor: dividerColor,
          child: Material(
            color: isToday
                ? scheme.primary.withValues(
                    alpha: theme.brightness == Brightness.dark ? 0.06 : 0.04,
                  )
                : Colors.transparent,
            child: InkWell(
              onTap: () {
                if (dayHours > 0) {
                  onDayWithHoursTap(dayEntries, employeeName, day);
                }
                HapticFeedback.selectionClick();
              },
              borderRadius: BorderRadius.circular(8),
              child: _timesheetDayCellBody(
                commentTooltip: commentTooltip,
                inOpenShift: inOpenShiftToday,
                openShiftTooltip: openShiftTooltip,
                scheme: scheme,
                brightness: theme.brightness,
                dayHours: dayHours,
                dayEntries: dayEntries,
                theme: theme,
              ),
            ),
          ),
        ),
      );
    }

    final rowBackground = isSelected
        ? TimesheetGridLayout.selectedRowBackground(scheme, theme.brightness)
        : Colors.transparent;

    return SizedBox(
      height: TimesheetGridLayout.dataRowHeight,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: rowBackground,
          border: Border(
            left: BorderSide(color: dividerColor),
            right: BorderSide(color: dividerColor),
            bottom: BorderSide(color: dividerColor),
          ),
        ),
        child: Row(
          children: [
            _TimesheetGridCells.fixed(
              width: TimesheetGridLayout.selectColWidth,
              dividerColor: dividerColor,
              child: Padding(
                padding: const EdgeInsets.only(left: 6, right: 2),
                child: Tooltip(
                  message: 'Выбрать строку',
                  child: _TimesheetGridCheckbox(
                    value: isSelected,
                    semanticLabel: 'Выбрать $employeeName',
                    onChanged: onSelectionChanged,
                  ),
                ),
              ),
            ),
            _TimesheetGridCells.employee(
              dividerColor: dividerColor,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onEmployeeTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                employeeName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  height: 1.15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              Icons.edit_calendar_outlined,
                              size: 14,
                              color: scheme.primary.withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                        if (employee.position != null &&
                            employee.position!.isNotEmpty)
                          Text(
                            employee.position!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.72),
                              fontSize: 10,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ...dayWidgets,
            _TimesheetGridCells.fixed(
              width: TimesheetGridLayout.totalColWidth,
              dividerColor: dividerColor,
              showRightBorder: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Center(
                  child: Text(
                    formatQuantity(totalHours),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Строка «Итого по дням» (сразу под списком сотрудников в общем скролле).
class TimesheetGridTotalsRow extends StatelessWidget {
  /// Дни периода.
  final List<DateTime> daysInRange;

  /// `yyyy-MM-dd` → все записи за день (уже по видимым сотрудникам).
  final Map<String, List<TimesheetEntry>> entriesByDayKey;

  /// Цвет линий сетки.
  final Color dividerColor;

  /// Создаёт строку итогов.
  const TimesheetGridTotalsRow({
    super.key,
    required this.daysInRange,
    required this.entriesByDayKey,
    required this.dividerColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    num grandTotal = 0;
    final dayWidgets = <Widget>[];

    for (final day in daysInRange) {
      final key = TimesheetGridLayout.dayKey(day);
      final dayEntries = entriesByDayKey[key] ?? const <TimesheetEntry>[];
      final dayHours = dayEntries.fold<num>(0, (s, e) => s + e.hours);
      grandTotal += dayHours;

      dayWidgets.add(
        _TimesheetGridCells.fixed(
          width: TimesheetGridLayout.dayColWidth,
          dividerColor: dividerColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Center(
              child: Text(
                formatQuantity(dayHours),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final totalsBackground = theme.brightness == Brightness.dark
        ? scheme.surfaceContainerHigh
        : scheme.surfaceContainerHighest.withValues(alpha: 0.65);

    return SizedBox(
      height: TimesheetGridLayout.totalsRowHeight,
      child: ColoredBox(
        color: totalsBackground,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: scheme.outline.withValues(alpha: 0.32)),
              left: BorderSide(color: dividerColor),
              right: BorderSide(color: dividerColor),
              bottom: BorderSide(color: dividerColor),
            ),
          ),
          child: Row(
            children: [
              _TimesheetGridCells.fixed(
                width: TimesheetGridLayout.selectColWidth,
                dividerColor: dividerColor,
                child: const SizedBox.shrink(),
              ),
              _TimesheetGridCells.employee(
                dividerColor: dividerColor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Text(
                    'Итого по дням',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ),
              ...dayWidgets,
              _TimesheetGridCells.fixed(
                width: TimesheetGridLayout.totalColWidth,
                dividerColor: dividerColor,
                showRightBorder: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Text(
                      formatQuantity(grandTotal),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Текст подсказки при наведении: уникальные примечания за день.
String? _timesheetDayCommentsTooltip(Iterable<TimesheetEntry> entries) {
  final lines = <String>[];
  final seen = <String>{};
  for (final entry in entries) {
    final text = entry.comment?.trim();
    if (text == null || text.isEmpty || !seen.add(text)) continue;
    final object = entry.objectName?.trim();
    lines.add(object != null && object.isNotEmpty ? '$object: $text' : text);
  }
  if (lines.isEmpty) return null;
  return lines.join('\n');
}

Widget _timesheetDayCellBody({
  required String? commentTooltip,
  required bool inOpenShift,
  required String? openShiftTooltip,
  required ColorScheme scheme,
  required Brightness brightness,
  required num dayHours,
  required List<TimesheetEntry> dayEntries,
  required ThemeData theme,
}) {
  final starColor = TimesheetGridLayout.openShiftStarColor(scheme);
  final starStyle = theme.textTheme.bodySmall?.copyWith(
    fontWeight: FontWeight.w700,
    fontSize: dayHours > 0 ? 10 : 13,
    color: starColor,
    height: 1,
  );

  Widget body = Stack(
    clipBehavior: Clip.hardEdge,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Center(
          child: dayHours > 0
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: dayEntries.any((e) => e.isManualEntry)
                        ? Border.all(color: scheme.primary, width: 1.5)
                        : null,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Text(
                      formatQuantity(dayHours),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                )
              : inOpenShift
              ? Text('*', style: starStyle, textAlign: TextAlign.center)
              : const SizedBox.shrink(),
        ),
      ),
      if (inOpenShift && dayHours > 0)
        Positioned(
          top: 1,
          left: 2,
          child: Text('*', style: starStyle),
        ),
      if (commentTooltip != null)
        Positioned(
          top: 0,
          right: 0,
          child: _TimesheetCommentCornerMark(
            color: TimesheetGridLayout.commentCornerColor(scheme, brightness),
          ),
        ),
    ],
  );

  final messages = <String>[
    if (openShiftTooltip != null) openShiftTooltip,
    if (commentTooltip != null) commentTooltip,
  ];
  if (messages.isEmpty) return body;

  return Tooltip(
    message: messages.join('\n'),
    preferBelow: true,
    verticalOffset: 12,
    child: Semantics(label: messages.join('. '), child: body),
  );
}

/// Уголковый маркер примечания в ячейке дня.
class _TimesheetCommentCornerMark extends StatelessWidget {
  const _TimesheetCommentCornerMark({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    const size = TimesheetGridLayout.commentCornerSize;
    return ExcludeSemantics(
      child: CustomPaint(
        size: const Size(size, size),
        painter: _TimesheetCommentCornerPainter(color: color),
      ),
    );
  }
}

class _TimesheetCommentCornerPainter extends CustomPainter {
  const _TimesheetCommentCornerPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _TimesheetCommentCornerPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _TimesheetGridCheckbox extends StatelessWidget {
  const _TimesheetGridCheckbox({
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    this.tristate = false,
  });

  final bool? value;
  final ValueChanged<bool?> onChanged;
  final String semanticLabel;
  final bool tristate;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: SizedBox.square(
        dimension: 32,
        child: Center(
          child: SizedBox.square(
            dimension: 20,
            child: Checkbox(
              value: value,
              tristate: tristate,
              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              splashRadius: 0,
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    );
  }
}
