import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/month_group.dart';
import '../../domain/entities/light_work.dart';
import '../providers/month_groups_provider.dart';
import '../providers/month_summary_provider.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/error/failure.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/features/works/presentation/providers/month_chart_data_provider.dart';
import 'package:projectgt/features/works/presentation/widgets/daily_work_chart.dart';

/// Сетка отступов панели месяца (базовый шаг 16, как у десктопа договоров).
abstract final class _MonthDetailsSpacing {
  static const double grid = 16;
  static const double insetHDesktop = 20;
  static const double insetVDesktopTop = 16;
  static const double insetVDesktopBottom = 24;
  static const double section = 24;
  static const double block = 20;
  static const double titleBelow = 10;
  static const double listItemGap = 10;
  static const double twinColumns = 24;
}

/// Панель детальной информации за месяц (графики, KPI, статистика).
class MonthDetailsPanel extends ConsumerStatefulWidget {
  /// Группа смен за месяц.
  final MonthGroup group;

  /// Флаг отображения AppBar для мобильных устройств.
  final bool showMobileAppBar;

  /// Флаг использования фона с группировкой.
  final bool useGroupedBackground;

  /// Создаёт панель деталей месяца.
  const MonthDetailsPanel({
    super.key,
    required this.group,
    this.showMobileAppBar = false,
    this.useGroupedBackground = false,
  });

  @override
  ConsumerState<MonthDetailsPanel> createState() => _MonthDetailsPanelState();
}

class _MonthDetailsPanelState extends ConsumerState<MonthDetailsPanel> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthName = widget.group.monthName;
    final isMobileLayout =
        widget.showMobileAppBar || ResponsiveUtils.isMobile(context);
    final isDesktop = !isMobileLayout;

    final monthGroupsAsync = ref.watch(monthGroupsProvider);

    return monthGroupsAsync.when(
      data: (groups) {
        final currentGroup = groups.firstWhere(
          (g) => g.month == widget.group.month,
          orElse: () => widget.group,
        );

        final works = currentGroup.works;
        final isLoading = works == null;

        final totalEmployees = _calculateTotalEmployees();
        final totalHours = _calculateTotalHours();

        // Загружаем полные данные для графика и расчетов KPI
        final chartDataAsync = ref.watch(
          monthChartDataProvider(widget.group.month),
        );
        final fullWorks = chartDataAsync.valueOrNull;
        final averagePerEmployee = _calculateAveragePerEmployee(fullWorks);

        final formattedMonthTitle = monthName;

        final isGroupedBackground =
            widget.useGroupedBackground || widget.showMobileAppBar;
        final groupedBackgroundColor = theme.brightness == Brightness.light
            ? theme.colorScheme.surfaceContainerHigh
            : theme.colorScheme.surfaceContainerLowest;
        final scaffoldBackgroundColor = isGroupedBackground
            ? groupedBackgroundColor
            : Colors.transparent;

        return Scaffold(
          backgroundColor: scaffoldBackgroundColor,
          appBar: widget.showMobileAppBar
              ? AppBarWidget(
                  title: formattedMonthTitle,
                  leading: const BackButton(),
                  centerTitle: true,
                  showThemeSwitch: false,
                )
              : null,
          body: isLoading
              ? const Center(child: CupertinoActivityIndicator())
              : SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: isMobileLayout ? 16 : _MonthDetailsSpacing.insetHDesktop,
                    right: isMobileLayout ? 16 : _MonthDetailsSpacing.insetHDesktop,
                    top: isMobileLayout ? 20 : _MonthDetailsSpacing.insetVDesktopTop,
                    bottom: isMobileLayout
                        ? 20
                        : _MonthDetailsSpacing.insetVDesktopBottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isDesktop) ...[
                        _buildHeaderDesktop(
                          context,
                          formattedMonthTitle,
                          currentGroup.isCurrentMonth,
                        ),
                        const SizedBox(height: _MonthDetailsSpacing.block),
                      ] else
                        const SizedBox(height: 12),

                      // --- График выработки ---
                      RepaintBoundary(
                        child: _buildDailyChart(context, chartDataAsync),
                      ),
                      SizedBox(
                        height: isDesktop
                            ? _MonthDetailsSpacing.block
                            : _MonthDetailsSpacing.grid,
                      ),

                      // --- KPI Карточки ---
                      if (isDesktop)
                        _buildKpiGridDesktop(
                          context,
                          currentGroup,
                          averagePerEmployee,
                          totalEmployees,
                          totalHours,
                        )
                      else
                        _buildKpiListMobile(
                          context,
                          currentGroup,
                          averagePerEmployee,
                          totalEmployees,
                          totalHours,
                        ),

                      SizedBox(
                        height: isDesktop
                            ? _MonthDetailsSpacing.section
                            : 32,
                      ),

                      if (isDesktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle(context, 'По системам'),
                                  const SizedBox(
                                    height: _MonthDetailsSpacing.titleBelow,
                                  ),
                                  _buildSystemsStats(context, isDesktop: true),
                                ],
                              ),
                            ),
                            const SizedBox(
                              width: _MonthDetailsSpacing.twinColumns,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle(context, 'По объектам'),
                                  const SizedBox(
                                    height: _MonthDetailsSpacing.titleBelow,
                                  ),
                                  _buildObjectsStats(context, isDesktop: true),
                                ],
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildSectionTitle(context, 'По системам'),
                            const SizedBox(height: 12),
                            _buildSystemsStats(context, isDesktop: false),
                            const SizedBox(height: 32),
                            _buildSectionTitle(context, 'По объектам'),
                            const SizedBox(height: 12),
                            _buildObjectsStats(context, isDesktop: false),
                          ],
                        ),

                      SizedBox(
                        height: isDesktop
                            ? _MonthDetailsSpacing.section
                            : 32,
                      ),
                    ],
                  ),
                ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CupertinoActivityIndicator()),
      ),
      error: (e, s) {
        final failure = e is Failure ? e : Failure.fromException(e);
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.exclamationmark_triangle,
                    size: 48,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    failure.message ?? 'Ошибка загрузки данных',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  GTSecondaryButton(
                    text: 'Повторить',
                    onPressed: () =>
                        ref.read(monthGroupsProvider.notifier).refresh(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDailyChart(
    BuildContext context,
    AsyncValue<List<LightWork>> chartDataAsync,
  ) {
    return chartDataAsync.when(
      data: (data) {
        if (data.isEmpty) return const SizedBox.shrink();
        return DailyWorkChart(
          works: data,
          month: widget.group.month,
          isDesktop: !ResponsiveUtils.isMobile(context),
        );
      },
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CupertinoActivityIndicator()),
      ),
      error: (e, s) => const SizedBox.shrink(),
    );
  }

  Widget _buildHeaderDesktop(
    BuildContext context,
    String title,
    bool isCurrentMonth,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            if (isCurrentMonth)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Текущий месяц',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiGridDesktop(
    BuildContext context,
    MonthGroup group,
    String averagePerEmployee,
    int totalEmployees,
    double totalHours,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Адаптивная сетка: 3 колонки, 2 ряда для десктопа
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _KpiCard(
                    title: 'Общая сумма',
                    value: formatCurrency(group.totalAmount),
                    icon: CupertinoIcons.money_dollar_circle_fill,
                    color: Colors.green,
                    isLarge: true,
                    relaxed: true,
                  ),
                ),
                const SizedBox(width: _MonthDetailsSpacing.grid),
                Expanded(
                  child: _KpiCard(
                    title: 'Всего смен',
                    value: '${group.worksCount}',
                    icon: CupertinoIcons.briefcase_fill,
                    color: Colors.blue,
                    relaxed: true,
                  ),
                ),
                const SizedBox(width: _MonthDetailsSpacing.grid),
                Expanded(
                  child: _KpiCard(
                    title: 'Специалистов',
                    value: '$totalEmployees',
                    icon: CupertinoIcons.person_3_fill,
                    color: Colors.teal,
                    relaxed: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: _MonthDetailsSpacing.grid),
            Row(
              children: [
                Expanded(
                  child: _KpiCard(
                    title: 'Часов',
                    value: totalHours > 0 ? totalHours.toStringAsFixed(0) : '0',
                    icon: CupertinoIcons.time_solid,
                    color: Colors.deepOrange,
                    relaxed: true,
                  ),
                ),
                const SizedBox(width: _MonthDetailsSpacing.grid),
                Expanded(
                  child: _KpiCard(
                    title: 'Средняя смена',
                    value: group.worksCount > 0
                        ? formatCurrency(group.totalAmount / group.worksCount)
                        : formatCurrency(0),
                    icon: CupertinoIcons.chart_bar_square_fill,
                    color: Colors.orange,
                    relaxed: true,
                  ),
                ),
                const SizedBox(width: _MonthDetailsSpacing.grid),
                Expanded(
                  child: _KpiCard(
                    title: 'Выработка / чел.',
                    value: averagePerEmployee,
                    icon: CupertinoIcons.person_crop_circle_fill,
                    color: Colors.purple,
                    relaxed: true,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiListMobile(
    BuildContext context,
    MonthGroup group,
    String averagePerEmployee,
    int totalEmployees,
    double totalHours,
  ) {
    final theme = Theme.of(context);
    final valueStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );

    // Используем старый AppleMenuGroup для мобилки
    return _AppleMenuGroup(
      children: [
        _AppleMenuItem(
          icon: CupertinoIcons.money_dollar_circle_fill,
          iconColor: Colors.green,
          title: 'Общая сумма',
          trailing: Text(formatCurrency(group.totalAmount), style: valueStyle),
        ),
        _AppleMenuItem(
          icon: CupertinoIcons.briefcase_fill,
          iconColor: Colors.blue,
          title: 'Всего смен',
          trailing: Text('${group.worksCount}', style: valueStyle),
        ),
        _AppleMenuItem(
          icon: CupertinoIcons.person_3_fill,
          iconColor: Colors.teal,
          title: 'Специалистов',
          trailing: Text('$totalEmployees', style: valueStyle),
        ),
        _AppleMenuItem(
          icon: CupertinoIcons.time_solid,
          iconColor: Colors.deepOrange,
          title: 'Часов',
          trailing: Text(
            totalHours > 0 ? totalHours.toStringAsFixed(0) : '0',
            style: valueStyle,
          ),
        ),
        _AppleMenuItem(
          icon: CupertinoIcons.chart_bar_square_fill,
          iconColor: Colors.orange,
          title: 'Средняя смена',
          trailing: Text(
            group.worksCount > 0
                ? formatCurrency(group.totalAmount / group.worksCount)
                : formatCurrency(0),
            style: valueStyle,
          ),
        ),
        _AppleMenuItem(
          icon: CupertinoIcons.person_crop_circle_fill,
          iconColor: Colors.purple,
          title: 'Выработка / чел.',
          trailing: Text(averagePerEmployee, style: valueStyle),
        ),
      ],
    );
  }

  Widget _buildSystemsStats(BuildContext context, {bool isDesktop = false}) {
    final systemsSummaryAsync = ref.watch(
      systemsSummaryProvider(widget.group.month),
    );

    return systemsSummaryAsync.when(
      data: (summaries) {
        if (summaries.isEmpty) {
          return _buildEmptyState(context, 'Нет данных по системам', isDesktop);
        }

        if (isDesktop) {
          return Column(
            children: summaries
                .map(
                  (stat) => Padding(
                    padding: const EdgeInsets.only(
                      bottom: _MonthDetailsSpacing.listItemGap,
                    ),
                    child: _SummaryListItem(
                      icon: CupertinoIcons.hammer_fill,
                      iconColor: Colors.indigo,
                      title: stat.system,
                      subtitle: '${stat.itemsCount} раб.',
                      value: formatCurrency(stat.totalAmount),
                      relaxed: true,
                    ),
                  ),
                )
                .toList(),
          );
        }

        return Column(
          children: summaries
              .map(
                (stat) => Padding(
                  padding: const EdgeInsets.only(
                    bottom: _MonthDetailsSpacing.listItemGap,
                  ),
                  child: _SummaryListItem(
                    icon: CupertinoIcons.hammer_fill,
                    iconColor: Colors.indigo,
                    title: stat.system,
                    subtitle: '${stat.itemsCount} раб.',
                    value: formatCurrency(stat.totalAmount),
                    relaxed: false,
                  ),
                ),
              )
              .toList(),
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (e, s) => _buildEmptyState(context, 'Ошибка: $e', isDesktop),
    );
  }

  Widget _buildObjectsStats(BuildContext context, {bool isDesktop = false}) {
    final objectsSummaryAsync = ref.watch(
      objectsSummaryProvider(widget.group.month),
    );

    return objectsSummaryAsync.when(
      data: (summaries) {
        if (summaries.isEmpty) {
          return _buildEmptyState(context, 'Нет данных по объектам', isDesktop);
        }

        return Column(
          children: summaries
              .map(
                (stat) => Padding(
                  padding: EdgeInsets.only(
                    bottom: isDesktop
                        ? _MonthDetailsSpacing.listItemGap
                        : 8,
                  ),
                  child: _SummaryListItem(
                    icon: CupertinoIcons.location_solid,
                    iconColor: Colors.redAccent,
                    title: stat.objectName,
                    subtitle: '${stat.worksCount} смен',
                    value: formatCurrency(stat.totalAmount),
                    relaxed: isDesktop,
                  ),
                ),
              )
              .toList(),
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (e, s) => _buildEmptyState(context, 'Ошибка: $e', isDesktop),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    String message,
    bool isDesktop,
  ) {
    return _EmptyState(message: message);
  }

  String _calculateAveragePerEmployee(List<LightWork>? works) {
    if (works == null || works.isEmpty) return '0 ₽';
    final totalEmployees = works.fold<int>(
      0,
      (sum, work) => sum + work.employeesCount,
    );
    if (totalEmployees == 0) return '0 ₽';
    final totalAmount = works.fold<double>(
      0,
      (sum, work) => sum + work.totalAmount,
    );
    return formatCurrency(totalAmount / totalEmployees);
  }

  int _calculateTotalEmployees() {
    final employeesAsync = ref.watch(
      monthTotalEmployeesProvider(widget.group.month),
    );
    return employeesAsync.when(
      data: (s) => s.totalEmployees,
      loading: () => 0,
      error: (_, __) => 0,
    );
  }

  double _calculateTotalHours() {
    final hoursAsync = ref.watch(monthTotalHoursProvider(widget.group.month));
    return hoursAsync.when(
      data: (s) => s.totalHours,
      loading: () => 0,
      error: (_, __) => 0,
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isLarge;
  final bool relaxed;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isLarge = false,
    this.relaxed = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = relaxed
        ? const EdgeInsets.fromLTRB(18, 18, 18, 16)
        : const EdgeInsets.all(16);
    final titleToValueGap = relaxed ? 16.0 : 12.0;
    final iconGap = relaxed ? 14.0 : 12.0;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (relaxed)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(icon, size: 22, color: color),
                  ),
                )
              else
                Icon(icon, size: 20, color: color),
              SizedBox(width: iconGap),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: titleToValueGap),
          Text(
            value,
            style: isLarge
                ? theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.5,
                  )
                : theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
          ),
        ],
      ),
    );
  }
}

class _SummaryListItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String value;
  final bool relaxed;

  const _SummaryListItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    this.relaxed = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final horizontal = relaxed ? 18.0 : 16.0;
    final vertical = relaxed ? 16.0 : 14.0;
    final iconBox = relaxed ? 40.0 : 36.0;
    final iconSize = relaxed ? 22.0 : 20.0;
    final midGap = relaxed ? 14.0 : 16.0;
    final endGap = relaxed ? 14.0 : 16.0;

    final iconWidget = relaxed
        ? Container(
            width: iconBox,
            height: iconBox,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: iconSize, color: iconColor),
          )
        : Icon(icon, size: iconSize, color: iconColor);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          iconWidget,
          SizedBox(width: midGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: endGap),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: relaxed ? 4 : 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Center(
        child: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _AppleMenuGroup extends StatelessWidget {
  const _AppleMenuGroup({required this.children});

  final List<_AppleMenuItem> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _buildChildrenWithDividers(context),
        ),
      ),
    );
  }

  List<Widget> _buildChildrenWithDividers(BuildContext context) {
    final theme = Theme.of(context);
    final List<Widget> widgets = [];

    for (var i = 0; i < children.length; i++) {
      widgets.add(children[i]);
      if (i < children.length - 1) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 60, right: 16),
            child: Divider(
              height: 1,
              thickness: 1,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
            ),
          ),
        );
      }
    }

    return widgets;
  }
}

class _AppleMenuItem extends StatelessWidget {
  const _AppleMenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
