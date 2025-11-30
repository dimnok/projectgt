import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/presentation/state/auth_state.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:projectgt/presentation/state/employee_state.dart';
import 'package:projectgt/presentation/state/contractor_state.dart';
import 'package:projectgt/presentation/state/contract_state.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/features/home/presentation/widgets/contract_progress_widget.dart';
import 'package:projectgt/features/home/presentation/widgets/shifts_calendar_widgets.dart';
import 'package:projectgt/features/home/presentation/widgets/work_plan_summary_widget.dart';
// import removed: notification test utilities
// import removed: works provider used only in tests

const Color _telegramBlue = Color(0xFF229ED9);
const Color _whatsappGreen = Color(0xFF25D366);

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

    final userDisplayName =
        profileState.profile?.shortName ?? authState.user?.name ?? 'USER';
    final permissionService = ref.watch(permissionServiceProvider);

    // --- Логика приветствия и мотивации ---
    final hour = DateTime.now().hour;
    String greetingPrefix;
    String timeBasedSubtitle;

    if (hour >= 5 && hour < 12) {
      greetingPrefix = 'Доброе утро';
      timeBasedSubtitle =
          'Желаю продуктивного и плодотворного дня. Не забывайте контролировать рабочие процессы и оптимизировать результаты.';
    } else if (hour >= 12 && hour < 18) {
      greetingPrefix = 'Добрый день';
      timeBasedSubtitle =
          'Рабочий день в разгаре. Самое время свериться с планами и зафиксировать промежуточные результаты.';
    } else if (hour >= 18 && hour < 23) {
      greetingPrefix = 'Добрый вечер';
      timeBasedSubtitle =
          'День подходит к концу. Отличное время для подведения итогов и планирования завтрашнего дня.';
    } else {
      greetingPrefix = 'Доброй ночи';
      timeBasedSubtitle =
          'Система работает стабильно. Не забывайте про отдых, чтобы завтра быть в ресурсе.';
    }

    // Пытаемся извлечь имя из полного ФИО (обычно 2-е слово: Фамилия Имя Отчество)
    String firstName = '';
    final fullName = profileState.profile?.fullName;
    if (fullName != null && fullName.trim().isNotEmpty) {
      final parts = fullName.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        firstName = parts[1]; // Берём Имя
      } else {
        firstName = parts[0];
      }
    }
    // Если не вышло, используем shortName или fallback, убирая инициалы если получится
    if (firstName.isEmpty) {
      firstName = userDisplayName.split(' ').first;
    }

    final fullGreeting = '$greetingPrefix, $firstName';
    // ---------------------------------------

    // Метрика: топовая смена (недоступна без модуля выгрузки)
    String topShiftSubtitle = 'Нет данных';
    int shiftsCount = 0;

    final metrics = [
      _Metric(
        label: 'Работы',
        value: shiftsCount,
        icon: CupertinoIcons.hammer,
        subtitle: topShiftSubtitle,
        isLoading: false,
        accent: _telegramBlue, // Changed from _telegramBlue
        onTap: () => context.goNamed('works'),
      ),
      if (permissionService.can('employees', 'read'))
        _Metric(
          label: 'Сотрудники',
          value: employeesState.employees.length,
          icon: CupertinoIcons.person_2,
          subtitle: 'Список персонала',
          isLoading: employeesState.status == EmployeeStatus.loading,
          accent: _telegramBlue, // Changed from _telegramBlue
          onTap: () => context.goNamed('employees'),
        ),
      if (permissionService.can('contractors', 'read'))
        _Metric(
          label: 'Контрагенты',
          value: contractorsState.contractors.length,
          icon: CupertinoIcons.building_2_fill,
          subtitle: 'Партнёры и компании',
          isLoading: contractorsState.status == ContractorStatus.loading,
          accent: _whatsappGreen, // Changed from _whatsappGreen
          onTap: () => context.goNamed('contractors'),
        ),
      if (permissionService.can('contracts', 'read'))
        _Metric(
          label: 'Договоры',
          value: contractsState.contracts.length,
          icon: CupertinoIcons.doc_text,
          subtitle: 'Текущие соглашения',
          isLoading: contractsState.status == ContractStatusState.loading,
          accent: _telegramBlue, // Changed from _telegramBlue
          onTap: () => context.goNamed('contracts'),
        ),
      if (permissionService.can('estimates', 'read'))
        _Metric(
          label: 'Сметы',
          value: estimatesState.estimates.length,
          icon: CupertinoIcons.table,
          subtitle: 'Расчёты и материалы',
          isLoading: estimatesState.isLoading,
          accent: _whatsappGreen, // Changed from _whatsappGreen
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
                title: fullGreeting,
                subtitle: timeBasedSubtitle,
                parallaxProgress: _parallaxProgress,
                hour: hour,
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
                          child: const Padding(
                            padding: EdgeInsets.all(16),
                            child: SizedBox(
                              height: 300,
                              child: ShiftsCalendarFlipCard(),
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
                                children: const [
                                  // Страница 1: Календарь смен
                                  ShiftsCalendarFlipCard(),
                                  // Страница 2: Прогресс договора
                                  ContractProgressWidget(),
                                  // Страница 3: План работ
                                  WorkPlanSummaryWidget(),
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

              Center(
                child: GTPrimaryButton(
                  text: 'Тест окна',
                  onPressed: () {
                    final width = MediaQuery.of(context).size.width;
                    if (width >= 800) {
                      // Desktop: Dialog
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          backgroundColor: Colors.transparent,
                          insetPadding: const EdgeInsets.all(24),
                          child: DesktopDialogContent(
                            title: 'Тестовое окно',
                            width: 500,
                            footer: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                GTSecondaryButton(
                                  text: 'Отмена',
                                  onPressed: () => Navigator.pop(context),
                                ),
                                const SizedBox(width: 16),
                                GTPrimaryButton(
                                  text: 'ОК',
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Это контент тестового окна для десктопа (Dialog). '
                              'Оно поддерживает фиксированную ширину, кнопку закрытия и адаптивный скролл.',
                            ),
                          ),
                        ),
                      );
                    } else {
                      // Mobile: BottomSheet
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        constraints: const BoxConstraints(maxWidth: 640),
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) => MobileBottomSheetContent(
                          title: 'Тестовое окно',
                          footer: Row(
                            children: [
                              Expanded(
                                child: GTSecondaryButton(
                                  text: 'Отмена',
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GTPrimaryButton(
                                  text: 'ОК',
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Это контент тестового модального окна для мобильных (BottomSheet). '
                            'Оно поддерживает скролл, безопасные зоны и адаптивность.',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),

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
  final String title;
  final String subtitle;
  final double parallaxProgress;
  final int hour;

  const _GreetingHeader({
    required this.title,
    required this.subtitle,
    required this.parallaxProgress,
    required this.hour,
  });

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
          // Усиливаем эффект параллакса (было 8)
          final dy = value * 14;
          return Transform.translate(
            offset: Offset(0, dy),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    // Усиливаем прозрачность градиента при скролле
                    _telegramBlue.withValues(alpha: 0.12 + 0.15 * value),
                    _whatsappGreen.withValues(alpha: 0.12 + 0.15 * value),
                  ],
                ),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.08),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Row(
                children: [
                  AnimatedScale(
                    // Усиливаем эффект масштабирования иконки (было 0.02)
                    scale: 1.0 + value * 0.1,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    child: _TimeOfDayIcon(hour: hour),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
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

class _TimeOfDayIcon extends StatefulWidget {
  final int hour;
  const _TimeOfDayIcon({required this.hour});

  @override
  State<_TimeOfDayIcon> createState() => _TimeOfDayIconState();
}

class _TimeOfDayIconState extends State<_TimeOfDayIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _updateAnimationParams();
  }

  @override
  void didUpdateWidget(_TimeOfDayIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_getPeriod(oldWidget.hour) != _getPeriod(widget.hour)) {
      _updateAnimationParams();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getPeriod(int h) {
    if (h >= 5 && h < 12) return 'morning';
    if (h >= 12 && h < 18) return 'day';
    if (h >= 18 && h < 23) return 'evening';
    return 'night';
  }

  void _updateAnimationParams() {
    _controller.stop();
    final period = _getPeriod(widget.hour);

    if (period == 'morning') {
      _controller.duration = const Duration(milliseconds: 2500);
      _controller.repeat(reverse: true);
    } else if (period == 'day') {
      _controller.duration = const Duration(seconds: 12);
      _controller.repeat(); // 0 -> 1 continuous
    } else if (period == 'evening') {
      _controller.duration = const Duration(milliseconds: 3000);
      _controller.repeat(reverse: true);
    } else {
      _controller.duration = const Duration(milliseconds: 3500);
      _controller.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final period = _getPeriod(widget.hour);

    // Конфигурация статики (цвета, иконка)
    IconData iconData;
    Color iconColor;
    Color bgColor;

    if (period == 'morning') {
      iconData = CupertinoIcons.sunrise_fill;
      iconColor = Colors.orange;
      bgColor = Colors.orange.withValues(alpha: 0.15);
    } else if (period == 'day') {
      iconData = CupertinoIcons.sun_max_fill;
      iconColor = Colors.amber.shade700;
      bgColor = Colors.amber.withValues(alpha: 0.15);
    } else if (period == 'evening') {
      iconData = CupertinoIcons.sunset_fill;
      iconColor = Colors.deepOrange;
      bgColor = Colors.deepOrange.withValues(alpha: 0.15);
    } else {
      iconData = CupertinoIcons.moon_stars_fill;
      iconColor = const Color(0xFF5E35B1);
      bgColor = const Color(0xFF5E35B1).withValues(alpha: 0.15);
    }

    final iconWidget = Icon(iconData, color: iconColor, size: 28);

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      // AnimatedBuilder перерисовывает только трансформацию, не пересоздавая иконку
      child: AnimatedBuilder(
        animation: _controller,
        child: Center(child: iconWidget),
        builder: (context, child) {
          // Используем transform для вычисления кривой "на лету" без создания объекта Animation
          final double t = Curves.easeInOut.transform(_controller.value);

          if (period == 'morning') {
            // Пульсация при восходе (масштаб)
            final scale = 0.9 + (0.25 * t); // 0.9 -> 1.15
            return Transform.scale(scale: scale, child: child);
          } else if (period == 'day') {
            // Вращение солнца (линейное или сглаженное)
            // Для солнца лучше линейное вращение, поэтому берем raw value
            return Transform.rotate(
                angle: _controller.value * 2 * 3.14159, child: child);
          } else if (period == 'evening') {
            // Закат (пульсация вниз)
            final scale = 1.1 - (0.2 * t); // 1.1 -> 0.9
            return Transform.scale(scale: scale, child: child);
          } else {
            // Ночь (покачивание)
            // -0.15 rad -> +0.15 rad
            final angle = -0.15 + (0.3 * t);
            return Transform.rotate(angle: angle, child: child);
          }
        },
      ),
    );
  }
}

// moved to shifts_calendar_widgets.dart

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
