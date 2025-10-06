import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/presentation/state/auth_state.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:projectgt/presentation/widgets/drawer_item_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Перечисление маршрутов приложения для навигации в AppDrawer.
enum AppRoute {
  /// Главный экран (домашняя страница).
  home,

  /// Экран профиля пользователя.
  profile,

  /// Экран списка пользователей.
  users,

  /// Экран списка сотрудников.
  employees,

  /// Экран списка подрядчиков.
  contractors,

  /// Экран объектов.
  objects,

  /// Экран контрактов.
  contracts,

  /// Экран сметы.
  estimates,

  /// Экран работ.
  works,

  /// Экран материалов.
  material,

  /// Экран табеля.
  timesheet,

  /// Экран расчётов (ФОТ).
  payrolls,

  /// Экран экспорта.
  export,

  /// Экран плана работ.
  workPlans,

  /// Экран управления версиями.
  versionManagement,
}

/// Боковое меню (Drawer) для навигации по основным разделам приложения.
///
/// Адаптивный, поддерживает выделение активного маршрута, отображает профиль пользователя и быстрый выход.
class AppDrawer extends ConsumerWidget {
  /// Активный маршрут для выделения текущего пункта меню.
  final AppRoute activeRoute;

  /// Создаёт боковое меню с выделением [activeRoute].
  const AppDrawer({
    super.key,
    required this.activeRoute,
  });

  @override

  /// Строит виджет бокового меню с профилем, навигацией и выходом.
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final currentUserProfileState = ref.watch(currentUserProfileProvider);
    final user = authState.user;
    final currentUserProfile = currentUserProfileState.profile;
    final screenWidth = MediaQuery.of(context).size.width;
    final double drawerWidth = screenWidth >= 800
        ? 360.0
        : screenWidth >= 600
            ? screenWidth * 0.6
            : screenWidth * 0.7;

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      width: drawerWidth,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.08),
              ),
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              builder: (context, t, child) {
                final double angle = (1 - t) * (math.pi / 2);
                final Matrix4 transform = Matrix4.identity()
                  ..setEntry(3, 2, 0.0015)
                  ..rotateY(angle);
                return Opacity(
                  opacity: t,
                  child: Transform(
                    alignment: Alignment.centerLeft,
                    transform: transform,
                    child: child,
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    // Верхняя часть с основным контентом
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          SizedBox(
                            height: 120,
                            child: DrawerHeader(
                              margin: EdgeInsets.zero,
                              padding:
                                  const EdgeInsets.fromLTRB(24, 24, 24, 16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.shadow
                                        .withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Аватар и информация пользователя
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      // Аватар с улучшенным дизайном и возможностью клика
                                      GestureDetector(
                                        onTap: () => context.goNamed('profile'),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.2),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Stack(
                                            children: [
                                              CircleAvatar(
                                                radius: 32,
                                                backgroundColor:
                                                    theme.colorScheme.primary,
                                                child: currentUserProfile
                                                                ?.photoUrl !=
                                                            null ||
                                                        user?.photoUrl != null
                                                    ? ClipOval(
                                                        child:
                                                            CachedNetworkImage(
                                                          imageUrl: currentUserProfile
                                                                  ?.photoUrl ??
                                                              user?.photoUrl ??
                                                              '',
                                                          width: 64,
                                                          height: 64,
                                                          fit: BoxFit.cover,
                                                          placeholder:
                                                              (context, url) =>
                                                                  Container(
                                                            color: theme
                                                                .colorScheme
                                                                .primary
                                                                .withValues(
                                                                    alpha: 0.1),
                                                            child: Icon(
                                                              Icons.person,
                                                              size: 32,
                                                              color: theme
                                                                  .colorScheme
                                                                  .primary,
                                                            ),
                                                          ),
                                                          errorWidget: (context,
                                                                  url, error) =>
                                                              Icon(
                                                            Icons.person,
                                                            size: 32,
                                                            color: theme
                                                                .colorScheme
                                                                .onPrimary,
                                                          ),
                                                        ),
                                                      )
                                                    : Icon(
                                                        Icons.person,
                                                        size: 32,
                                                        color: theme.colorScheme
                                                            .onPrimary,
                                                      ),
                                              ),
                                              Positioned(
                                                right: 0,
                                                bottom: 0,
                                                child: Container(
                                                  width: 14,
                                                  height: 14,
                                                  decoration: BoxDecoration(
                                                    color: Colors.green,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: theme
                                                          .colorScheme.surface,
                                                      width: 2,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Имя и email пользователя
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    currentUserProfile
                                                            ?.shortName ??
                                                        user?.name ??
                                                        'USER',
                                                    style: theme
                                                        .textTheme.titleLarge
                                                        ?.copyWith(
                                                      color: theme.colorScheme
                                                          .onSurface,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      letterSpacing: 0.5,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: theme
                                                        .colorScheme.primary
                                                        .withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: Text(
                                                    currentUserProfile?.role ==
                                                            'admin'
                                                        ? 'ADMIN'
                                                        : 'USER',
                                                    style: theme
                                                        .textTheme.labelSmall
                                                        ?.copyWith(
                                                      color: currentUserProfile
                                                                  ?.role ==
                                                              'admin'
                                                          ? Colors.purple
                                                          : theme.colorScheme
                                                              .primary,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.email_outlined,
                                                  size: 14,
                                                  color: theme
                                                      .colorScheme.onSurface
                                                      .withValues(alpha: 0.7),
                                                ),
                                                const SizedBox(width: 6),
                                                Flexible(
                                                  child: Text(
                                                    user?.email ??
                                                        'email@example.com',
                                                    style: theme
                                                        .textTheme.bodyMedium
                                                        ?.copyWith(
                                                      color: theme
                                                          .colorScheme.onSurface
                                                          .withValues(
                                                              alpha: 0.7),
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Divider(
                              height: 1,
                              thickness: 1,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.1),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Пункты меню
                          DrawerItemWidget(
                            icon: Icons.home_rounded,
                            title: 'Главная',
                            isSelected: activeRoute == AppRoute.home,
                            onTap: () {
                              if (activeRoute == AppRoute.home) {
                                context.pop();
                              } else {
                                context.pop();
                                context.goNamed('home');
                              }
                            },
                          ),
                          DrawerItemWidget(
                            icon: Icons.work_outline,
                            title: 'Работы',
                            isSelected:
                                activeRoute.toString() == 'AppRoute.works',
                            onTap: () {
                              context.pop();
                              context.goNamed('works');
                            },
                          ),
                          DrawerItemWidget(
                            icon: Icons.calendar_view_week_rounded,
                            title: 'План работ',
                            isSelected: activeRoute == AppRoute.workPlans,
                            onTap: () {
                              if (activeRoute == AppRoute.workPlans) {
                                context.pop();
                              } else {
                                context.pop();
                                context.goNamed('work_plans');
                              }
                            },
                          ),
                          DrawerItemWidget(
                            icon: Icons.inventory_2_outlined,
                            title: 'Материал',
                            isSelected: activeRoute == AppRoute.material,
                            onTap: () {
                              if (activeRoute == AppRoute.material) {
                                context.pop();
                              } else {
                                context.pop();
                                context.goNamed('material');
                              }
                            },
                          ),
                          DrawerItemWidget(
                            icon: Icons.assignment_outlined,
                            title: 'Табель',
                            isSelected: activeRoute == AppRoute.timesheet,
                            onTap: () {
                              context.pop();
                              context.goNamed('timesheet');
                            },
                          ),
                          // Админские разделы
                          if (user?.role == 'admin')
                            DrawerItemWidget(
                              icon: Icons.people_alt_rounded,
                              title: 'Сотрудники',
                              isSelected: activeRoute == AppRoute.employees,
                              onTap: () {
                                if (activeRoute == AppRoute.employees) {
                                  context.pop();
                                } else {
                                  context.pop();
                                  context.goNamed('employees');
                                }
                              },
                            ),
                          if (user?.role == 'admin')
                            DrawerItemWidget(
                              icon: Icons.location_city_rounded,
                              title: 'Объекты',
                              isSelected: activeRoute == AppRoute.objects,
                              onTap: () {
                                context.pop();
                                context.goNamed('objects');
                              },
                            ),
                          if (user?.role == 'admin')
                            DrawerItemWidget(
                              icon: Icons.business_rounded,
                              title: 'Контрагенты',
                              isSelected: activeRoute == AppRoute.contractors,
                              onTap: () {
                                if (activeRoute == AppRoute.contractors) {
                                  context.pop();
                                } else {
                                  context.pop();
                                  context.goNamed('contractors');
                                }
                              },
                            ),
                          if (user?.role == 'admin')
                            DrawerItemWidget(
                              icon: Icons.description_rounded,
                              title: 'Договоры',
                              isSelected: activeRoute == AppRoute.contracts,
                              onTap: () {
                                if (activeRoute == AppRoute.contracts) {
                                  context.pop();
                                } else {
                                  context.pop();
                                  context.goNamed('contracts');
                                }
                              },
                            ),
                          if (user?.role == 'admin')
                            DrawerItemWidget(
                              icon: Icons.table_chart_rounded,
                              title: 'Сметы',
                              isSelected: activeRoute == AppRoute.estimates,
                              onTap: () {
                                if (activeRoute == AppRoute.estimates) {
                                  context.pop();
                                } else {
                                  context.pop();
                                  context.goNamed('estimates');
                                }
                              },
                            ),
                          if (user?.role == 'admin')
                            DrawerItemWidget(
                              icon: Icons.payments,
                              title: 'ФОТ',
                              isSelected:
                                  activeRoute.toString() == 'AppRoute.payrolls',
                              onTap: () {
                                context.pop();
                                context.goNamed('payrolls');
                              },
                            ),
                          // Выгрузка доступна всем пользователям
                          DrawerItemWidget(
                            icon: Icons.file_download_outlined,
                            title: 'Выгрузка',
                            isSelected: activeRoute == AppRoute.export,
                            onTap: () {
                              if (activeRoute == AppRoute.export) {
                                context.pop();
                              } else {
                                context.pop();
                                context.goNamed('export');
                              }
                            },
                          ),
                          if (user?.role == 'admin')
                            DrawerItemWidget(
                              icon: Icons.people_rounded,
                              title: 'Пользователи',
                              isSelected: activeRoute == AppRoute.users,
                              onTap: () {
                                if (activeRoute == AppRoute.users) {
                                  context.pop();
                                } else {
                                  context.pop();
                                  context.goNamed('users');
                                }
                              },
                            ),
                          if (user?.role == 'admin')
                            DrawerItemWidget(
                              icon: Icons.system_update_alt,
                              title: 'Управление версиями',
                              isSelected:
                                  activeRoute == AppRoute.versionManagement,
                              onTap: () {
                                if (activeRoute == AppRoute.versionManagement) {
                                  context.pop();
                                } else {
                                  context.pop();
                                  context.goNamed('version_management');
                                }
                              },
                            ),
                          // Telegram модерация удалена
                        ],
                      ),
                    ),

                    // Разделитель
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.1),
                      ),
                    ),

                    // Выход из аккаунта внизу меню
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: DrawerItemWidget(
                        icon: Icons.logout_rounded,
                        title: 'Выйти из аккаунта',
                        isSelected: false,
                        onTap: () {
                          context.pop();
                          ref.read(authProvider.notifier).logout();
                          context.goNamed('login');
                        },
                        isDestructive: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
