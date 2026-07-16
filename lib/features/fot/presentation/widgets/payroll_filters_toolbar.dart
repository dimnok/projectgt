import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/features/employees/presentation/utils/employees_layout_utils.dart';

import '../providers/payroll_filter_providers.dart';
import 'payroll_objects_bar_dropdown.dart';
import 'payroll_tab_segment.dart';
import 'payroll_tab_toolbar_actions.dart';
import 'payroll_toolbar_metrics.dart';

const double _kBarHeight = PayrollToolbarMetrics.height;
const double _kBarRadius = PayrollToolbarMetrics.radius;
const double _kFs = 14;
const double _kIcon = 18;

Color _payrollBorderColor(ColorScheme scheme) =>
    scheme.outline.withValues(alpha: 0.38);

Color _payrollTrackFill(ColorScheme scheme) =>
    scheme.surfaceContainerHighest.withValues(alpha: 0.45);

/// Фиксированная внешняя ширина [PayrollCompactMonthSwitcher].
const double kPayrollMonthSwitcherOuterWidth = 184;

const double _kMonthNavSlotWidth = 30;
const double _kMonthLabelWidth =
    kPayrollMonthSwitcherOuterWidth - _kMonthNavSlotWidth * 2;

BoxDecoration _monthSwitcherDecoration(ColorScheme scheme) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(_kBarRadius),
    border: Border.all(
      color: scheme.primary.withValues(alpha: 0.62),
      width: 1,
    ),
    color: scheme.primary.withValues(alpha: 0.14),
  );
}

/// Компактный переключатель месяца в панели фильтров ФОТ.
class PayrollCompactMonthSwitcher extends ConsumerWidget {
  /// Создаёт переключатель периода.
  const PayrollCompactMonthSwitcher({super.key});

  static String _monthYearLabel(int year, int month) {
    final s = formatMonthYear(DateTime(year, month));
    if (s.isEmpty) return '';
    return s.replaceFirst(RegExp(r'\s+'), '-');
  }

  void _shiftMonth(WidgetRef ref, int delta) {
    final state = ref.read(payrollFilterProvider);
    final next = DateTime(state.selectedYear, state.selectedMonth + delta, 1);
    ref
        .read(payrollFilterProvider.notifier)
        .setYearAndMonth(next.year, next.month);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final filterState = ref.watch(payrollFilterProvider);
    final label = _monthYearLabel(
      filterState.selectedYear,
      filterState.selectedMonth,
    );

    final accent = scheme.primary;
    final iconActive = accent.withValues(alpha: 0.9);
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
      required VoidCallback onTap,
    }) {
      return SizedBox(
        width: _kMonthNavSlotWidth,
        height: _kBarHeight,
        child: Tooltip(
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
        ),
      );
    }

    return SizedBox(
      width: kPayrollMonthSwitcherOuterWidth,
      height: _kBarHeight,
      child: DecoratedBox(
        decoration: _monthSwitcherDecoration(scheme),
        child: Row(
          children: [
            navSlot(
              tooltip: 'Предыдущий месяц',
              icon: Icons.chevron_left_rounded,
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
              onTap: () => _shiftMonth(ref, 1),
            ),
          ],
        ),
      ),
    );
  }
}

/// Поле поиска в панели фильтров ФОТ (desktop/tablet).
class PayrollToolbarSearch extends ConsumerStatefulWidget {
  /// Создаёт поле поиска.
  const PayrollToolbarSearch({super.key});

  @override
  ConsumerState<PayrollToolbarSearch> createState() =>
      _PayrollToolbarSearchState();
}

class _PayrollToolbarSearchState extends ConsumerState<PayrollToolbarSearch> {
  late final TextEditingController _controller;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(payrollSearchQueryProvider),
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
    ref.read(payrollSearchQueryProvider.notifier).state = query;
  }

  BoxDecoration _searchDecoration(ThemeData theme, {required bool focused}) {
    final scheme = theme.colorScheme;
    final borderColor = focused
        ? scheme.primary.withValues(alpha: 0.85)
        : _payrollBorderColor(scheme);
    final width = focused ? 1.5 : 1.0;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(_kBarRadius),
      border: Border.all(color: borderColor, width: width),
      color: _payrollTrackFill(scheme),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    ref.listen<String>(payrollSearchQueryProvider, (previous, next) {
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

    return _PayrollToolbarSearchField(
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

class _PayrollToolbarSearchField extends StatelessWidget {
  const _PayrollToolbarSearchField({
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

/// Примерная ширина [PayrollTabSegment] для расчёта поля поиска.
const double kPayrollTabSegmentOuterWidth = 272;

/// Ширина поля поиска в панели фильтров — как в модуле «Табель».
double payrollToolbarSearchWidth(
  double rowWidth, {
  bool hasTrailingActions = true,
  bool hasMonthSwitcher = true,
  bool hasTabSegment = true,
}) {
  const gapsReserveBase = 196.0;
  const monthSwitcherReserve = kPayrollMonthSwitcherOuterWidth + 12;
  const tabSegmentReserve = kPayrollTabSegmentOuterWidth + 12;
  const trailingActionsReserve = 200.0;
  final gapsReserve =
      gapsReserveBase +
      (hasMonthSwitcher ? monthSwitcherReserve : 0) +
      (hasTabSegment ? tabSegmentReserve : 0) +
      (hasTrailingActions ? trailingActionsReserve : 0);
  final computedSearch = rowWidth.isFinite
      ? math.min(380.0, math.max(200.0, rowWidth * 0.28))
      : 380.0;
  if (!rowWidth.isFinite) return computedSearch;
  return math.min(computedSearch, math.max(140.0, rowWidth - gapsReserve));
}

/// Единая панель фильтров модуля ФОТ (стиль модуля «Табель»).
class PayrollFiltersToolbar extends ConsumerWidget {
  /// Создаёт панель фильтров.
  const PayrollFiltersToolbar({
    super.key,
    required this.selectedTabIndex,
    required this.onTabChanged,
  });

  /// Активная вкладка: 0 ФОТ, 1 Премии, 2 Штрафы, 3 Выплаты.
  final int selectedTabIndex;

  /// Вызывается при смене вкладки.
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useMobileList = EmployeesLayoutUtils.useEmployeesMobileList(context);
    final objectsEnabled = selectedTabIndex != 3;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final rowW = constraints.maxWidth;
          final includeSearch = !useMobileList;
          final searchW = includeSearch
              ? payrollToolbarSearchWidth(
                  rowW,
                  hasMonthSwitcher: true,
                  hasTabSegment: true,
                )
              : 0.0;

          final trailingActions = PayrollTabToolbarActions(
            selectedTabIndex: selectedTabIndex,
          );

          final leadingCluster = SizedBox(
            height: PayrollToolbarMetrics.height,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                PayrollTabSegment(
                  selectedIndex: selectedTabIndex,
                  onChanged: onTabChanged,
                ),
                const SizedBox(width: 12),
                const PayrollCompactMonthSwitcher(),
                if (includeSearch) ...[
                  const SizedBox(width: 12),
                  SizedBox(width: searchW, child: const PayrollToolbarSearch()),
                ],
                const SizedBox(width: 8),
                PayrollObjectsBarDropdown(enabled: objectsEnabled),
              ],
            ),
          );

          if (!useMobileList) {
            return SizedBox(
              height: PayrollToolbarMetrics.height,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  leadingCluster,
                  const Spacer(),
                  trailingActions,
                ],
              ),
            );
          }

          return SizedBox(
            height: PayrollToolbarMetrics.height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: leadingCluster,
                  ),
                ),
                const SizedBox(width: 8),
                trailingActions,
              ],
            ),
          );
        },
      ),
    );
  }
}
