import 'package:flutter/material.dart';
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
  /// Экран табеля.
  timesheet,
  /// Экран расчётов (ФОТ).
  payrolls,
  /// Экран экспорта.
  export,
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
    final profileState = ref.watch(profileProvider);
    final user = authState.user;
    final profile = profileState.profile;

    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: Column(
          children: [
            // Верхняя часть с основным контентом
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  SizedBox(
                    height: 170,
                    child: DrawerHeader(
                      margin: EdgeInsets.zero,
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
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
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Аватар с улучшенным дизайном и возможностью клика
                              GestureDetector(
                                onTap: () => context.goNamed('profile'),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 32,
                                        backgroundColor: theme.colorScheme.primary,
                                        child: profile?.photoUrl != null || user?.photoUrl != null
                                            ? ClipOval(
                                                child: CachedNetworkImage(
                                                  imageUrl: profile?.photoUrl ?? user?.photoUrl ?? '',
                                                  width: 64,
                                                  height: 64,
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) => Container(
                                                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                                    child: Icon(
                                                      Icons.person,
                                                      size: 32,
                                                      color: theme.colorScheme.primary,
                                                    ),
                                                  ),
                                                  errorWidget: (context, url, error) => Icon(
                                                    Icons.person,
                                                    size: 32,
                                                    color: theme.colorScheme.onPrimary,
                                                  ),
                                                ),
                                              )
                                            : Icon(
                                                Icons.person,
                                                size: 32,
                                                color: theme.colorScheme.onPrimary,
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
                                              color: theme.colorScheme.surface,
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            profile?.shortName ?? user?.name ?? 'USER',
                                            style: theme.textTheme.titleLarge?.copyWith(
                                              color: theme.colorScheme.onSurface,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            profile?.role == 'admin' ? 'ADMIN' : 'USER',
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              color: profile?.role == 'admin' 
                                                ? Colors.purple
                                                : theme.colorScheme.primary,
                                              fontWeight: FontWeight.bold,
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
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            user?.email ?? 'email@example.com',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
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
                  DrawerItemWidget(
                    icon: Icons.work_outline,
                    title: 'Работы',
                    isSelected: activeRoute.toString() == 'AppRoute.works',
                    onTap: () {
                      context.pop();
                      context.goNamed('works');
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
                  DrawerItemWidget(
                    icon: Icons.payments,
                    title: 'ФОТ',
                    isSelected: activeRoute.toString() == 'AppRoute.payrolls',
                    onTap: () {
                      context.pop();
                      context.goNamed('payrolls');
                    },
                  ),
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
                ],
              ),
            ),
            
            // Разделитель
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Divider(
                height: 1,
                thickness: 1,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
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
    );
  }
} 