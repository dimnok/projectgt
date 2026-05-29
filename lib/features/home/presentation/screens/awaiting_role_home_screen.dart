import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/theme/theme_settings_provider.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_backdrop.dart';
import 'package:projectgt/core/widgets/mobile_atmosphere_screen_header.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/features/home/presentation/widgets/awaiting_role_desktop_bento.dart';
import 'package:projectgt/features/home/presentation/widgets/awaiting_role_home_widgets.dart';
import 'package:projectgt/features/home/presentation/widgets/home_dashboard_constants.dart';
import 'package:projectgt/features/home/presentation/widgets/home_sliver_hero_delegate.dart';
import 'package:projectgt/domain/entities/profile.dart';
import 'package:projectgt/presentation/state/auth_state.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';

/// Главный экран для сотрудника без назначенной роли.
///
/// Не загружает бизнес-данные; показывает статус ожидания и обзор возможностей
/// приложения, пока администратор не назначит роль.
class AwaitingRoleHomeScreen extends ConsumerStatefulWidget {
  /// Создаёт экран ожидания назначения роли.
  const AwaitingRoleHomeScreen({super.key});

  @override
  ConsumerState<AwaitingRoleHomeScreen> createState() =>
      _AwaitingRoleHomeScreenState();
}

class _AwaitingRoleHomeScreenState extends ConsumerState<AwaitingRoleHomeScreen> {
  bool _isChecking = false;
  late final PageController _pageController;
  int _currentPage = 0;

  static const _features = [
    AwaitingRoleFeatureItem(
      icon: Icons.engineering_outlined,
      title: 'Смены на объектах',
      subtitle: 'Ежедневный учёт работы бригад на стройплощадках',
      accent: Color(0xFF0D9488),
      highlights: [
        'Открытие и закрытие смен с привязкой к объекту',
        'Фиксация выработки и состава бригады',
        'Контроль плана по людям и срокам договора',
      ],
    ),
    AwaitingRoleFeatureItem(
      icon: Icons.description_outlined,
      title: 'Договоры и объекты',
      subtitle: 'Структура проектов компании в одном реестре',
      accent: Color(0xFF2563EB),
      highlights: [
        'Карточки договоров с ключевыми сроками и суммами',
        'Привязка объектов (площадок) к договорам',
        'Быстрый переход к сменам и сметам по договору',
      ],
    ),
    AwaitingRoleFeatureItem(
      icon: Icons.table_chart_outlined,
      title: 'Сметы и ВОР',
      subtitle: 'Сметная документация и ведомости объёмов работ',
      accent: Color(0xFF7C3AED),
      highlights: [
        'Загрузка и ведение смет, ревизии и допсоглашения',
        'ВОР: позиции, объёмы, статусы согласования',
        'Экспорт в Excel для согласования с заказчиком',
      ],
    ),
    AwaitingRoleFeatureItem(
      icon: Icons.people_outline,
      title: 'Команда и роли',
      subtitle: 'Сотрудники, права и безопасный доступ',
      accent: Color(0xFFEA580C),
      highlights: [
        'Приглашение в компанию одноразовым кодом',
        'Гибкие роли: кто что видит и может менять',
        'Отключение доступа без удаления истории',
      ],
    ),
    AwaitingRoleFeatureItem(
      icon: Icons.insights_outlined,
      title: 'Аналитика и главная',
      subtitle: 'Сводка для руководителя и исполнителя',
      accent: Color(0xFF059669),
      highlights: [
        'План / факт по договору, людям и деньгам',
        'Календарь смен и открытые смены на сегодня',
        'Понятная главная — только разрешённые виджеты',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkRoleAssigned() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);
    try {
      final userId = ref.read(authProvider).user?.id;
      if (userId == null) return;
      await ref
          .read(currentUserProfileProvider.notifier)
          .refreshCurrentUserProfile(userId);
      await ref.read(authProvider.notifier).checkAuthStatus(force: true);
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appearance = MobileAtmosphereAppearance.of(context);
    final isDark = appearance.isDark;
    final profile = ref.watch(currentUserProfileProvider).profile;
    final companyAsync = ref.watch(companyProfileProvider);
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= kHomeDesktopDashboardBreakpoint;

    final companyName = companyAsync.maybeWhen(
      data: (c) => c?.nameShort ?? c?.nameFull,
      orElse: () => null,
    );

    final hour = DateTime.now().hour;
    final heroTitle = _heroGreeting(profile?.fullName);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: appearance.atmosphereBase,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor:
            isDark ? appearance.atmosphereBase : Colors.transparent,
        drawer: const AppDrawer(activeRoute: AppRoute.home),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const MobileAtmosphereBackdrop(),
            SafeArea(
              bottom: false,
              child: CustomScrollView(
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: HomeSliverHeroDelegate(
                      pageTitle: 'Главная',
                      title: heroTitle,
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
                          ref.read(themeSettingsProvider.notifier).setThemeMode(
                                isDark ? ThemeMode.light : ThemeMode.dark,
                              );
                        },
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      isDesktop ? 32 : 16,
                      8,
                      isDesktop ? 32 : 16,
                      24 + MediaQuery.paddingOf(context).bottom,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isDesktop ? 1280 : double.infinity,
                          ),
                          child: isDesktop
                              ? _buildDesktopBody(
                                  context,
                                  companyName: companyName,
                                  profile: profile,
                                )
                              : _buildMobileBody(
                                  context,
                                  companyName: companyName,
                                  profile: profile,
                                ),
                        ),
                      ),
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

  Widget _buildMobileBody(
    BuildContext context, {
    required String? companyName,
    required Profile? profile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ..._buildSharedHeader(
          context,
          companyName: companyName,
          profile: profile,
        ),
        const SizedBox(height: 16),
        const AwaitingRoleKpiStrip(),
        const SizedBox(height: 20),
        AwaitingRoleActionPanel(
          isChecking: _isChecking,
          onCheckRole: _checkRoleAssigned,
          onContactAdmin: () {
            AppSnackBar.show(
              context: context,
              message:
                  'Напишите администратору или руководителю: '
                  '«Назначьте мне роль в Стройка PRO». '
                  'Путь: меню → Пользователи → ваш профиль → Роль.',
              kind: AppSnackBarKind.info,
            );
          },
        ),
        const SizedBox(height: 24),
        const AwaitingRoleAboutAppCard(),
        ..._buildDiscoverySection(context, isWide: false),
        const SizedBox(height: 28),
        const AwaitingRoleGuidanceSection(),
        const SizedBox(height: 20),
        const AwaitingRoleFaqSection(),
      ],
    );
  }

  Widget _buildDesktopBody(
    BuildContext context, {
    required String? companyName,
    required Profile? profile,
  }) {
    return AwaitingRoleDesktopLayout(
      companyName: companyName,
      statusMessage: _statusMessage(
        firstName: _extractFirstName(profile?.fullName),
        companyName: companyName,
      ),
      features: _features,
      isChecking: _isChecking,
      onCheckRole: _checkRoleAssigned,
      onContactAdmin: () {
        AppSnackBar.show(
          context: context,
          message:
              'Напишите администратору или руководителю: '
              '«Назначьте мне роль в Стройка PRO». '
              'Путь: меню → Пользователи → ваш профиль → Роль.',
          kind: AppSnackBarKind.info,
        );
      },
    );
  }

  List<Widget> _buildSharedHeader(
    BuildContext context, {
    required String? companyName,
    required Profile? profile,
  }) {
    return [
      const AwaitingRoleProgressTimeline(),
      const SizedBox(height: 16),
      AwaitingRoleStatusCard(
        companyName: companyName,
        message: _statusMessage(
          firstName: _extractFirstName(profile?.fullName),
          companyName: companyName,
        ),
      ),
    ];
  }

  List<Widget> _buildDiscoverySection(BuildContext context, {required bool isWide}) {
    final theme = Theme.of(context);
    return [
      SizedBox(height: isWide ? 0 : 28),
      Text(
        'Знакомство со «Стройка PRO»',
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'Листайте карточки влево-вправо. В каждой — кратко, '
        'чем модуль помогает в ежедневной работе на стройке.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          height: 1.4,
        ),
      ),
      const SizedBox(height: 16),
      AwaitingRoleFeatureCarousel(
        controller: _pageController,
        currentIndex: _currentPage,
        onPageChanged: (i) => setState(() => _currentPage = i),
        items: _features,
        isDesktop: isWide,
      ),
      const SizedBox(height: 24),
      AwaitingRoleModuleChips(isWide: isWide),
    ];
  }

  String _heroGreeting(String? fullName) {
    final hour = DateTime.now().hour;
    final prefix = hour >= 5 && hour < 12
        ? 'Доброе утро'
        : hour >= 12 && hour < 18
            ? 'Добрый день'
            : hour >= 18 && hour < 23
                ? 'Добрый вечер'
                : 'Доброй ночи';
    final name = _extractFirstName(fullName);
    if (name.isEmpty) return '$prefix! Настраиваем доступ';
    return '$prefix, $name';
  }

  String _statusMessage({
    required String firstName,
    required String? companyName,
  }) {
    final who = firstName.isNotEmpty ? '$firstName, вы' : 'Вы';
    if (companyName != null && companyName.isNotEmpty) {
      return '$who уже в команде «$companyName». '
          'Сейчас у вас статус «Без роли» — это нормально сразу после входа по коду. '
          'Как только администратор назначит роль, главный экран заполнится данными '
          'строго по вашим правам.';
    }
    return '$who уже в организации. '
        'Статус «Без роли» — ожидание настройки доступа. '
        'После назначения роли откроется рабочая главная с вашими разделами.';
  }

  String _extractFirstName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return '';
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return parts[1];
    return parts.first;
  }
}
