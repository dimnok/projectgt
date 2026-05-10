import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/theme/theme_settings_provider.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_backdrop.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_screen_header.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:projectgt/features/home/presentation/widgets/home_dashboard_constants.dart';
import 'package:projectgt/features/home/presentation/widgets/home_desktop_dashboard.dart';
import 'package:projectgt/features/home/presentation/widgets/home_mobile_dashboard.dart';
import 'package:projectgt/features/home/presentation/widgets/home_sliver_hero_delegate.dart';

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

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appearance = MobileAtmosphereAppearance.of(context);
    final isDark = appearance.isDark;
    final profileState = ref.watch(currentUserProfileProvider);
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= kHomeDesktopDashboardBreakpoint;

    // --- Логика приветствия и мотивации ---
    final hour = DateTime.now().hour;
    String greetingPrefix;

    if (hour >= 5 && hour < 12) {
      greetingPrefix = 'Доброе утро';
    } else if (hour >= 12 && hour < 18) {
      greetingPrefix = 'Добрый день';
    } else if (hour >= 18 && hour < 23) {
      greetingPrefix = 'Добрый вечер';
    } else {
      greetingPrefix = 'Доброй ночи';
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
    final fullGreeting = '$greetingPrefix, $firstName';
    // ---------------------------------------

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: appearance.atmosphereBase,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: isDark
            ? appearance.atmosphereBase
            : Colors.transparent,
        drawer: const AppDrawer(activeRoute: AppRoute.home),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const MobileAtmosphereBackdrop(),
            SafeArea(
              bottom: false,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Прилипающая шапка (Hero)
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: HomeSliverHeroDelegate(
                      pageTitle: 'Главная',
                      title: fullGreeting,
                      hour: hour,
                      isDesktop: isDesktop,
                      leading: Builder(
                        builder: (ctx) => MobileAtmosphereChromeCircleButton(
                          appearance: appearance,
                          tooltip: 'Меню',
                          icon: Icons.menu_rounded,
                          onTap: () => Scaffold.of(ctx).openDrawer(),
                        ),
                      ),
                      trailing: MobileAtmosphereChromeCircleButton(
                        appearance: appearance,
                        tooltip: isDark ? 'Светлая тема' : 'Тёмная тема',
                        icon: isDark
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                        onTap: () {
                          ref
                              .read(themeSettingsProvider.notifier)
                              .setThemeMode(
                                isDark ? ThemeMode.light : ThemeMode.dark,
                              );
                        },
                      ),
                    ),
                  ),

                  // Основной контент
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 24),
                        if (isDesktop)
                          const HomeDesktopDashboard()
                        else
                          const HomeMobileDashboard(),
                        const SizedBox(height: 24),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
