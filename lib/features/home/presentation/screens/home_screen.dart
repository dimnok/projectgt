import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:projectgt/presentation/state/auth_state.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:projectgt/presentation/state/employee_state.dart';
import 'package:projectgt/presentation/state/contractor_state.dart';
import 'package:projectgt/presentation/state/contract_state.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:projectgt/features/export/presentation/providers/export_provider.dart';
import 'package:projectgt/features/export/domain/entities/export_filter.dart';
import 'package:projectgt/features/home/presentation/widgets/contract_progress_widget.dart';
import 'package:projectgt/features/home/presentation/widgets/shifts_calendar_widgets.dart';
import 'package:projectgt/features/home/presentation/widgets/work_plan_summary_widget.dart';
// import removed: notification test utilities
// import removed: works provider used only in tests

// Мягкие акцентные цвета в стиле Telegram и WhatsApp
const Color _telegramBlue = Color(0xFF229ED9);
const Color _whatsappGreen = Color(0xFF25D366);
const Color _softRed = Color(0xFFE57373);

/// Главный экран приложения ProjectGT с современной шапкой, метриками и heatmap смен.
class HomeScreen extends ConsumerStatefulWidget {
  /// Создаёт главный экран приложения.
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _initialized = false;
  late final ScrollController _scrollController;
  double _parallaxProgress = 0.0; // 0..1
  late final PageController _mainCardsPageController;
  int _mainCardsPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _mainCardsPageController = PageController();
    _scrollController.addListener(() {
      final offset = _scrollController.offset;
      final p = (offset / 200).clamp(0.0, 1.0);
      if (p != _parallaxProgress) {
        setState(() => _parallaxProgress = p);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      // Инициализируем необходимые данные для метрик
      // Сотрудники и сметы не автозагружаются — инициируем вручную
      Future.microtask(() {
        ref.read(employeeProvider.notifier).getEmployees();
        ref.read(estimateNotifierProvider.notifier).loadEstimates();
        ref.read(workPlanNotifierProvider.notifier).loadWorkPlans();
        final now = DateTime.now();
        final dateFrom = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 30));
        final dateTo = DateTime(now.year, now.month, now.day);
        ref
            .read(exportProvider.notifier)
            .loadReportData(ExportFilter(dateFrom: dateFrom, dateTo: dateTo));
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _mainCardsPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final profileState = ref.watch(currentUserProfileProvider);

    final employeesState = ref.watch(employeeProvider);
    final contractorsState = ref.watch(contractorProvider);
    final contractsState = ref.watch(contractProvider);
    final estimatesState = ref.watch(estimateNotifierProvider);
    final exportState = ref.watch(exportProvider);

    final userDisplayName =
        profileState.profile?.shortName ?? authState.user?.name ?? 'USER';

    // Подсчёт топовой смены по сумме из отчётов экспорта
    String topShiftSubtitle = 'Нет данных';
    int shiftsCount = 0;
    if (exportState.reports.isNotEmpty) {
      final Map<DateTime, double> sumByDate = {};
      for (final r in exportState.reports) {
        final d = DateTime(r.workDate.year, r.workDate.month, r.workDate.day);
        final total = (r.total ?? 0).toDouble();
        sumByDate[d] = (sumByDate[d] ?? 0) + total;
      }
      shiftsCount = sumByDate.length;
      if (sumByDate.isNotEmpty) {
        final top =
            sumByDate.entries.reduce((a, b) => a.value >= b.value ? a : b);
        final dateStr = DateFormat('dd.MM.yyyy').format(top.key);
        final amountStr = NumberFormat.currency(
                locale: 'ru_RU', symbol: '₽', decimalDigits: 0)
            .format(top.value);
        topShiftSubtitle = 'Топ смена $dateStr: $amountStr';
      }
    }

    final isAdmin = authState.user?.role == 'admin';

    final metrics = [
      _Metric(
        label: 'Работы',
        value: shiftsCount,
        icon: CupertinoIcons.hammer,
        subtitle: topShiftSubtitle,
        isLoading: exportState.isLoading,
        accent: _telegramBlue,
        onTap: () => context.goNamed('works'),
      ),
      if (isAdmin)
        _Metric(
          label: 'Сотрудники',
          value: employeesState.employees.length,
          icon: CupertinoIcons.person_2,
          subtitle: 'Список персонала',
          isLoading: employeesState.status == EmployeeStatus.loading,
          accent: _telegramBlue,
          onTap: () => context.goNamed('employees'),
        ),
      if (isAdmin)
        _Metric(
          label: 'Контрагенты',
          value: contractorsState.contractors.length,
          icon: CupertinoIcons.building_2_fill,
          subtitle: 'Партнёры и компании',
          isLoading: contractorsState.status == ContractorStatus.loading,
          accent: _whatsappGreen,
          onTap: () => context.goNamed('contractors'),
        ),
      if (isAdmin)
        _Metric(
          label: 'Договоры',
          value: contractsState.contracts.length,
          icon: CupertinoIcons.doc_text,
          subtitle: 'Текущие соглашения',
          isLoading: contractsState.status == ContractStatusState.loading,
          accent: _telegramBlue,
          onTap: () => context.goNamed('contracts'),
        ),
      if (isAdmin)
        _Metric(
          label: 'Сметы',
          value: estimatesState.estimates.length,
          icon: CupertinoIcons.table,
          subtitle: 'Расчёты и материалы',
          isLoading: estimatesState.isLoading,
          accent: _whatsappGreen,
          onTap: () => context.goNamed('estimates'),
        ),
    ];

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const AppBarWidget(title: 'Главная'),
      drawer: const AppDrawer(activeRoute: AppRoute.home),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Приветствие
              _GreetingHeader(
                userDisplayName: userDisplayName,
                parallaxProgress: _parallaxProgress,
              ),
              const SizedBox(height: 24),

              // Объединённый контейнер: свайп между календарём смен и прогрессом договора
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  int crossAxisCount = 1;
                  if (width >= 1100) {
                    crossAxisCount = 4;
                  } else if (width >= 800) {
                    crossAxisCount = 3;
                  } else if (width >= 560) {
                    crossAxisCount = 2;
                  }
                  const double crossAxisSpacing = 16;
                  final double cardWidth =
                      (width - (crossAxisCount - 1) * crossAxisSpacing) /
                          crossAxisCount;

                  // Desktop: карточки рядом
                  if (width >= 1100) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: cardWidth,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: theme.colorScheme.outline
                                  .withValues(alpha: 0.18),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: SizedBox(
                              height: 300,
                              child: SingleChildScrollView(
                                physics: const NeverScrollableScrollPhysics(),
                                child: _ShiftsHeatmap(
                                  reports: exportState.reports,
                                  isLoading: exportState.isLoading,
                                  onDateTap: (d, v) {
                                    // На десктопе пока оставим без flip
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: cardWidth,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: theme.colorScheme.outline
                                  .withValues(alpha: 0.18),
                            ),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(16),
                            child: SizedBox(
                              height: 300,
                              child: ContractProgressWidget(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: cardWidth,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: theme.colorScheme.outline
                                  .withValues(alpha: 0.18),
                            ),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(16),
                            child: SizedBox(
                              height: 300,
                              child: WorkPlanSummaryWidget(),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  // Mobile/Tablet: свайп между календарём и прогрессом в одном контейнере
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: cardWidth,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color:
                              theme.colorScheme.outline.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 300,
                              child: PageView(
                                controller: _mainCardsPageController,
                                onPageChanged: (i) =>
                                    setState(() => _mainCardsPageIndex = i),
                                children: [
                                  // Страница 1: Календарь смен
                                  ShiftsCalendarFlipCard(
                                    reports: exportState.reports,
                                    isLoading: exportState.isLoading,
                                  ),
                                  // Страница 2: Прогресс договора
                                  const ContractProgressWidget(),
                                  // Страница 3: План работ
                                  const WorkPlanSummaryWidget(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildDot(theme, _mainCardsPageIndex == 0),
                                const SizedBox(width: 6),
                                _buildDot(theme, _mainCardsPageIndex == 1),
                                const SizedBox(width: 6),
                                _buildDot(theme, _mainCardsPageIndex == 2),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Метрики
              _MetricsGrid(metrics: metrics),
              const SizedBox(height: 24),

              // Тестовые кнопки удалены

              // Диагностические тестовые кнопки удалены
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildDot(ThemeData theme, bool active) {
  return Container(
    width: 6,
    height: 6,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: active
          ? theme.colorScheme.primary
          : theme.colorScheme.onSurface.withValues(alpha: 0.25),
    ),
  );
}

class _GreetingHeader extends StatelessWidget {
  final String userDisplayName;
  final double parallaxProgress;
  const _GreetingHeader(
      {required this.userDisplayName, required this.parallaxProgress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: parallaxProgress),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          final dy = value * 8; // лёгкий параллакс
          return Transform.translate(
            offset: Offset(0, dy),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _telegramBlue.withValues(alpha: 0.10 + 0.05 * value),
                    _whatsappGreen.withValues(alpha: 0.10 + 0.05 * value),
                  ],
                ),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.08),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: [
                  AnimatedScale(
                    scale: 1.0 + value * 0.02,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _telegramBlue.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(CupertinoIcons.sparkles,
                          color: _telegramBlue),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Здравствуйте, $userDisplayName',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Сводка по ключевым разделам ниже. Нажмите на карточку, чтобы открыть.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// moved to shifts_calendar_widgets.dart

class _ShiftsHeatmap extends StatelessWidget {
  final List<dynamic> reports; // ExportReport
  final bool isLoading;
  final void Function(DateTime date, double value)? onDateTap;
  const _ShiftsHeatmap(
      {required this.reports, required this.isLoading, this.onDateTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Агрегация сумм по датам (только текущий месяц)
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    final Map<DateTime, double> sumByDate = {};
    double maxValue = 0;
    for (final r in reports) {
      if (r.workDate.year == now.year && r.workDate.month == now.month) {
        final d = DateTime(r.workDate.year, r.workDate.month, r.workDate.day);
        final total = (r.total ?? 0).toDouble();
        sumByDate[d] = (sumByDate[d] ?? 0) + total;
        if (sumByDate[d]! > maxValue) maxValue = sumByDate[d]!;
      }
    }

    // Построение календарной сетки месяца (Пн..Вс)
    final int prefix = monthStart.weekday - 1; // 0..6, где 0 — Пн
    final int daysInMonth = monthEnd.day;
    final int totalCells = ((prefix + daysInMonth + 6) ~/ 7) * 7; // кратно 7

    List<DateTime?> cells = List<DateTime?>.filled(totalCells, null);
    for (int i = 0; i < daysInMonth; i++) {
      cells[prefix + i] = DateTime(now.year, now.month, i + 1);
    }

    Widget cell(DateTime? d) {
      if (d == null) {
        return const SizedBox(width: 14, height: 14);
      }
      final v = sumByDate[d] ?? 0.0;
      final bool isMax = maxValue > 0 && (v == maxValue);
      final bool isZero = v == 0.0;

      Color fill;
      Color border;
      Color textColor;
      if (isZero) {
        fill = _softRed.withValues(alpha: 0.18);
        border = _softRed.withValues(alpha: 0.28);
        textColor = _softRed.withValues(alpha: 0.9);
      } else if (isMax) {
        fill = _whatsappGreen.withValues(alpha: 0.28);
        border = _whatsappGreen.withValues(alpha: 0.38);
        textColor = _whatsappGreen;
      } else {
        fill = _telegramBlue.withValues(alpha: 0.22);
        border = _telegramBlue.withValues(alpha: 0.32);
        textColor = _telegramBlue;
      }

      final box = Tooltip(
        message:
            '${DateFormat('dd.MM.yyyy').format(d)} — ${NumberFormat.currency(locale: 'ru_RU', symbol: '₽', decimalDigits: 0).format(v)}',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: border),
          ),
          width: 14,
          height: 14,
          child: Center(
            child: Text(
              '${d.day}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    height: 1.0,
                    color: textColor.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
      );
      if (onDateTap == null || isZero) return box;
      return GestureDetector(onTap: () => onDateTap!(d, v), child: box);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(CupertinoIcons.calendar,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
            const SizedBox(width: 8),
            Text(
              'Календарь смен',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            if (isLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  // Цвет прогресса возьмётся из темы
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            // 7 столбцов (Пн..Вс), строки — недели месяца
            const columns = 7;
            final rows = (cells.length / columns).ceil();
            const double spacing =
                4.0; // суммарно 4 по горизонтали на ячейку (2 слева + 2 справа)
            final double baseSize =
                (constraints.maxWidth - (columns * spacing)) / columns;
            final double size = baseSize * 0.94;

            List<Widget> weekRows = [];
            for (int r = 0; r < rows; r++) {
              final startIndex = r * columns;
              final endIndex = startIndex + columns;
              final weekDays = cells.sublist(startIndex, endIndex);
              weekRows.add(Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: weekDays
                      .map((d) =>
                          SizedBox(width: size, height: size, child: cell(d)))
                      .toList(),
                ),
              ));
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: weekRows,
            );
          },
        ),
      ],
    );
  }
}

class _Metric {
  final String label;
  final int value;
  final IconData icon;
  final String subtitle;
  final bool isLoading;
  final Color accent;
  final VoidCallback onTap;
  _Metric({
    required this.label,
    required this.value,
    required this.icon,
    required this.subtitle,
    required this.isLoading,
    required this.accent,
    required this.onTap,
  });
}

class _MetricsGrid extends StatelessWidget {
  final List<_Metric> metrics;
  const _MetricsGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = 1;
        if (width >= 1100) {
          crossAxisCount = 4;
        } else if (width >= 800) {
          crossAxisCount = 3;
        } else if (width >= 560) {
          crossAxisCount = 2;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.4,
          ),
          itemCount: metrics.length,
          itemBuilder: (context, index) {
            final metric = metrics[index];
            return InkWell(
              onTap: metric.onTap,
              borderRadius: BorderRadius.circular(14),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      metric.accent.withValues(alpha: 0.06),
                      metric.accent.withValues(alpha: 0.12),
                    ],
                  ),
                  border: Border.all(
                    color: metric.accent.withValues(alpha: 0.18),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: metric.accent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child:
                            Icon(metric.icon, color: metric.accent, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              metric.label,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              metric.value.toString(),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              metric.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (metric.isLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            // Цвет прогресса возьмётся из темы
                          ),
                        )
                      else
                        Icon(
                          CupertinoIcons.chevron_right,
                          size: 16,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Быстрые действия удалены по запросу
