import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/features/timesheet/presentation/providers/timesheet_provider.dart';
import 'package:projectgt/features/timesheet/presentation/widgets/timesheet_filter_widget.dart';

// Геометрия как у [EmployeesTableFiltersToolbar] и панели табеля.
const double _kBarHeight = 34;
const double _kBarRadius = 18;
const double _kFs = 14;
const double _kIcon = 18;

Color _tsBorderColor(ColorScheme scheme) =>
    scheme.outline.withValues(alpha: 0.38);

Color _tsTrackFill(ColorScheme scheme) =>
    scheme.surfaceContainerHighest.withValues(alpha: 0.45);

/// Фиксированная внешняя ширина [TimesheetCompactMonthSwitcher] (для раскладки панели).
///
/// Подпись «Сентябрь-2026» — самая длинная в ru_RU.
const double kTimesheetMonthSwitcherOuterWidth = 184;

const double _kMonthNavSlotWidth = 30;
const double _kMonthLabelWidth =
    kTimesheetMonthSwitcherOuterWidth - _kMonthNavSlotWidth * 2;

BoxDecoration _monthSwitcherDecoration(ColorScheme scheme) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(_kBarRadius),
    border: Border.all(
      color: scheme.primary.withValues(alpha: 0.62),
      width: 1.25,
    ),
    color: scheme.primary.withValues(alpha: 0.14),
  );
}

int _monthOrdinal(DateTime date) => date.year * 12 + date.month;

/// Компактный переключатель месяца в панели фильтров (высота 34, как у поиска).
class TimesheetCompactMonthSwitcher extends ConsumerWidget {
  /// Создаёт переключатель периода табеля.
  const TimesheetCompactMonthSwitcher({super.key});

  static String _monthYearLabel(DateTime monthStart) {
    final s = formatMonthYear(monthStart);
    if (s.isEmpty) return '';
    return s.replaceFirst(RegExp(r'\s+'), '-');
  }

  void _shiftMonth(WidgetRef ref, int delta) {
    final start = ref.read(timesheetProvider).startDate;
    final next = DateTime(start.year, start.month + delta, 1);
    final end = DateTime(next.year, next.month + 1, 0);
    ref.read(timesheetProvider.notifier).setDateRange(next, end);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final start = ref.watch(timesheetProvider).startDate;
    final label = _monthYearLabel(start);
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final viewedMonth = DateTime(start.year, start.month);
    final canGoForward =
        _monthOrdinal(viewedMonth) < _monthOrdinal(currentMonth);

    final accent = scheme.primary;
    final iconActive = accent.withValues(alpha: 0.9);
    final iconDisabled = scheme.onSurface.withValues(alpha: 0.28);
    final textStyle =
        theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: _kFs,
          height: 1.2,
          color: accent,
          letterSpacing: 0.1,
        ) ??
        TextStyle(fontSize: _kFs, fontWeight: FontWeight.w700, color: accent);

    Widget navSlot({
      required String tooltip,
      required IconData icon,
      required bool enabled,
      VoidCallback? onTap,
    }) {
      return SizedBox(
        width: _kMonthNavSlotWidth,
        height: _kBarHeight,
        child: enabled && onTap != null
            ? Tooltip(
                message: tooltip,
                child: Semantics(
                  button: true,
                  label: tooltip,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(_kBarRadius),
                      onTap: onTap,
                      child: Icon(icon, size: _kIcon, color: iconActive),
                    ),
                  ),
                ),
              )
            : ExcludeSemantics(
                child: Icon(icon, size: _kIcon, color: iconDisabled),
              ),
      );
    }

    return SizedBox(
      width: kTimesheetMonthSwitcherOuterWidth,
      height: _kBarHeight,
      child: DecoratedBox(
        decoration: _monthSwitcherDecoration(scheme),
        child: Row(
          children: [
            navSlot(
              tooltip: 'Предыдущий месяц',
              icon: Icons.chevron_left_rounded,
              enabled: true,
              onTap: () => _shiftMonth(ref, -1),
            ),
            SizedBox(
              width: _kMonthLabelWidth,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: textStyle,
              ),
            ),
            navSlot(
              tooltip: 'Следующий месяц',
              icon: Icons.chevron_right_rounded,
              enabled: canGoForward,
              onTap: canGoForward ? () => _shiftMonth(ref, 1) : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Поле поиска в панели фильтров табеля (стиль как у модуля «Сотрудники»).
class TimesheetToolbarSearch extends ConsumerStatefulWidget {
  /// Создаёт поле поиска для панели фильтров.
  const TimesheetToolbarSearch({super.key});

  @override
  ConsumerState<TimesheetToolbarSearch> createState() =>
      _TimesheetToolbarSearchState();
}

class _TimesheetToolbarSearchState
    extends ConsumerState<TimesheetToolbarSearch> {
  late final TextEditingController _controller;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(timesheetSearchQueryProvider),
    );
    _focus = FocusNode()..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _syncSearch(String query) {
    ref.read(timesheetSearchQueryProvider.notifier).state = query;
  }

  BoxDecoration _searchDecoration(ThemeData theme, {required bool focused}) {
    final scheme = theme.colorScheme;
    final borderColor = focused
        ? scheme.primary.withValues(alpha: 0.85)
        : _tsBorderColor(scheme);
    final width = focused ? 1.5 : 1.0;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(_kBarRadius),
      border: Border.all(color: borderColor, width: width),
      color: _tsTrackFill(scheme),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    ref.listen<String>(timesheetSearchQueryProvider, (previous, next) {
      if (previous == next) return;
      if (_controller.text == next) return;
      _controller.text = next;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    });

    final scheme = theme.colorScheme;
    final textStyle =
        theme.textTheme.bodyMedium?.copyWith(
          fontSize: _kFs,
          height: 1.2,
          color: scheme.onSurface,
        ) ??
        TextStyle(fontSize: _kFs, color: scheme.onSurface);

    return _TimesheetToolbarSearchField(
      decoration: _searchDecoration(theme, focused: _focus.hasFocus),
      controller: _controller,
      focusNode: _focus,
      textStyle: textStyle,
      hintStyle: textStyle.copyWith(
        color: scheme.onSurface.withValues(alpha: 0.42),
      ),
      onChanged: _syncSearch,
    );
  }
}

class _TimesheetToolbarSearchField extends StatelessWidget {
  const _TimesheetToolbarSearchField({
    required this.decoration,
    required this.controller,
    required this.focusNode,
    required this.textStyle,
    required this.hintStyle,
    required this.onChanged,
  });

  final BoxDecoration decoration;
  final TextEditingController controller;
  final FocusNode focusNode;
  final TextStyle textStyle;
  final TextStyle hintStyle;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iconMuted = scheme.onSurface.withValues(alpha: 0.55);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final hasText = controller.text.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: _kBarHeight,
          decoration: decoration,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(_kBarRadius),
            child: Row(
              children: [
                const SizedBox(width: 10),
                Icon(Icons.search_rounded, size: _kIcon, color: iconMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    style: textStyle,
                    cursorHeight: _kFs + 2,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Поиск: ФИО',
                      hintStyle: hintStyle,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: onChanged,
                  ),
                ),
                if (hasText)
                  Tooltip(
                    message: 'Очистить',
                    waitDuration: const Duration(milliseconds: 400),
                    child: Semantics(
                      button: true,
                      label: 'Очистить поиск',
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            controller.clear();
                            onChanged('');
                          },
                          child: SizedBox(
                            width: _kBarHeight,
                            height: _kBarHeight,
                            child: Center(
                              child: Icon(
                                Icons.close_rounded,
                                size: 20,
                                color: iconMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Ширина поля поиска в панели фильтров — как в [EmployeesTableFiltersToolbar].
double timesheetToolbarSearchWidth(
  double rowWidth, {
  bool hasTrailingExport = true,
  bool hasMonthSwitcher = true,
}) {
  const gapsReserveBase = 212.0;
  const monthSwitcherReserve = kTimesheetMonthSwitcherOuterWidth + 12;
  const trailingActionsReserve = 88.0;
  final gapsReserve =
      gapsReserveBase +
      (hasMonthSwitcher ? monthSwitcherReserve : 0) +
      (hasTrailingExport ? trailingActionsReserve : 0);
  final computedSearch = rowWidth.isFinite
      ? math.min(380.0, math.max(220.0, rowWidth * 0.34))
      : 380.0;
  if (!rowWidth.isFinite) return computedSearch;
  return math.min(computedSearch, math.max(160.0, rowWidth - gapsReserve));
}
