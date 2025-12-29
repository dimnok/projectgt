import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/presentation/state/auth_state.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/widgets/snowfall_widget.dart';
import 'package:projectgt/core/widgets/garland_widget.dart';
import 'package:projectgt/core/widgets/christmas_tree_widget.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:projectgt/features/home/presentation/widgets/contract_progress_widget.dart';
import 'package:projectgt/features/home/presentation/widgets/shifts_calendar_widgets.dart';
import 'package:projectgt/features/home/presentation/widgets/work_plan_summary_widget.dart';

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
  late final PageController _mainCardsPageController;
  int _mainCardsPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _mainCardsPageController = PageController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      Future.microtask(() {
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

    final userDisplayName =
        profileState.profile?.shortName ?? authState.user?.name ?? 'USER';

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
      // ignore: deprecated_member_use
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

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const AppBarWidget(title: 'Главная'),
      drawer: const AppDrawer(activeRoute: AppRoute.home),
      body: SnowfallWidget(
        child: Stack(
          children: [
            // Фоновая ёлка
            const Positioned(
              bottom: -20,
              right: -30,
              child: ChristmasTreeWidget(
                height: 350,
                opacity: 0.12, // Делаем её ненавязчивой, но заметной
              ),
            ),
            SafeArea(
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
                                    color: theme.colorScheme.outline.withValues(
                                      alpha: 0.18,
                                    ),
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
                                    color: theme.colorScheme.outline.withValues(
                                      alpha: 0.18,
                                    ),
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
                                    color: theme.colorScheme.outline.withValues(
                                      alpha: 0.18,
                                    ),
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
                                color: theme.colorScheme.outline.withValues(
                                  alpha: 0.18,
                                ),
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
                                      onPageChanged: (i) => setState(
                                        () => _mainCardsPageIndex = i,
                                      ),
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
                                      _buildDot(
                                        theme,
                                        _mainCardsPageIndex == 0,
                                      ),
                                      const SizedBox(width: 6),
                                      _buildDot(
                                        theme,
                                        _mainCardsPageIndex == 1,
                                      ),
                                      const SizedBox(width: 6),
                                      _buildDot(
                                        theme,
                                        _mainCardsPageIndex == 2,
                                      ),
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
                  ],
                ),
              ),
            ),
            const Positioned(top: 0, left: 0, right: 0, child: GarlandWidget()),
          ],
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
  final int hour;

  const _GreetingHeader({
    required this.title,
    required this.subtitle,
    required this.hour,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final weekDay = _getWeekDay(now.weekday);
    final month = _getMonth(now.month);
    final dateString = '$weekDay, ${now.day} $month';

    String period;
    if (hour >= 5 && hour < 12) {
      period = 'morning';
    } else if (hour >= 12 && hour < 18) {
      period = 'day';
    } else if (hour >= 18 && hour < 23) {
      period = 'evening';
    } else {
      period = 'night';
    }

    IconData iconData;
    Color baseColor;

    if (period == 'morning') {
      iconData = CupertinoIcons.sunrise_fill;
      baseColor = const Color(0xFFFF9A8B);
    } else if (period == 'day') {
      iconData = CupertinoIcons.sun_max_fill;
      baseColor = const Color(0xFF4FACFE);
    } else if (period == 'evening') {
      iconData = CupertinoIcons.sunset_fill;
      baseColor = const Color(0xFFFA709A);
    } else {
      iconData = CupertinoIcons.moon_stars_fill;
      baseColor = const Color(0xFF302B63);
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseColor.withValues(alpha: 0.12),
            baseColor.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(color: baseColor.withValues(alpha: 0.15), width: 1),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Иконка в углу
          Positioned(
            right: -10,
            top: -10,
            child: Icon(
              iconData,
              color: baseColor.withValues(alpha: 0.1),
              size: 100,
            ),
          ),
          // Шапка Деда Мороза
          Positioned(
            left: 10,
            top: -15,
            child: Transform.rotate(
              angle: -0.2,
              child: const Text('🎅', style: TextStyle(fontSize: 32)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateString.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getWeekDay(int day) {
    const days = [
      'Понедельник',
      'Вторник',
      'Среда',
      'Четверг',
      'Пятница',
      'Суббота',
      'Воскресенье',
    ];
    return days[day - 1];
  }

  String _getMonth(int month) {
    const months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];
    return months[month - 1];
  }
}
