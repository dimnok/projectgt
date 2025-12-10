import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/presentation/state/auth_state.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:projectgt/presentation/widgets/drawer_item_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';
import 'package:projectgt/features/roles/presentation/widgets/role_badge.dart';

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

  /// Экран складского учёта.
  inventory,

  /// Экран управления ролями.
  roles,

  /// Экран заявок.
  procurement,

  /// Экран настроек заявок.
  procurementSettings,
}

/// Виджет для группировки пунктов меню (например, "Справочники" с подпунктами).
class DrawerGroupWidget extends StatefulWidget {
  /// Иконка группы.
  final IconData icon;

  /// Название группы.
  final String title;

  /// Дочерние элементы группы.
  final List<DrawerGroupItem> items;

  /// Текущий активный маршрут для выделения.
  final AppRoute activeRoute;

  /// Создаёт группу пунктов меню.
  const DrawerGroupWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.items,
    required this.activeRoute,
  });

  @override
  State<DrawerGroupWidget> createState() => _DrawerGroupWidgetState();
}

class _DrawerGroupWidgetState extends State<DrawerGroupWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: math.pi / 2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Заголовок группы - точно как обычная кнопка
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
                if (_isExpanded) {
                  _animationController.forward();
                } else {
                  _animationController.reverse();
                }
              },
              borderRadius: BorderRadius.circular(12),
              splashColor: Colors.green.withValues(alpha: 0.1),
              highlightColor: Colors.green.withValues(alpha: 0.05),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Icon(
                      widget.icon,
                      size: 24,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                    RotationTransition(
                      turns: _rotationAnimation,
                      child: Icon(
                        Icons.chevron_right,
                        size: 20,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Дочерние элементы (анимируемое раскрытие)
        ClipRect(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Align(
                alignment: Alignment.topCenter,
                heightFactor: _animationController.value,
                child: child,
              );
            },
            child: Column(
              children: widget.items.map((item) {
                final isSelected = item.isSelected(widget.activeRoute);
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 2.0),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: item.onTap,
                      borderRadius: BorderRadius.circular(12),
                      splashColor: Colors.green.withValues(alpha: 0.1),
                      highlightColor: Colors.green.withValues(alpha: 0.05),
                      child: Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: isSelected
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.transparent,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 12.0),
                          child: Row(
                            children: [
                              const SizedBox(width: 8),
                              Icon(
                                Icons.circle,
                                size: 6,
                                color: isSelected
                                    ? Colors.green
                                    : Colors.transparent,
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: isSelected
                                        ? Colors.green
                                        : theme.colorScheme.onSurface,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  width: 4,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

/// Элемент группы меню с информацией для отображения и обработки.
class DrawerGroupItem {
  /// Название элемента.
  final String title;

  /// Функция для проверки, является ли этот элемент активным.
  final bool Function(AppRoute) isSelected;

  /// Колбэк при нажатии на элемент.
  final VoidCallback onTap;

  /// Создаёт элемент группы меню.
  const DrawerGroupItem({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });
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
    final permissionService = ref.watch(permissionServiceProvider);
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
                                            Flexible(
                                              child: Text(
                                                currentUserProfile?.shortName ??
                                                    user?.name ??
                                                    'USER',
                                                style: theme
                                                    .textTheme.titleLarge
                                                    ?.copyWith(
                                                  color: theme
                                                      .colorScheme.onSurface,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.5,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: RoleBadge(
                                                roleId: user?.roleId,
                                                fallbackRole: null,
                                              ),
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
                            icon: CupertinoIcons.home,
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
                          PermissionGuard(
                            module: 'works',
                            permission: 'read',
                            child: DrawerItemWidget(
                              icon: CupertinoIcons.wrench,
                              title: 'Работы',
                              isSelected:
                                  activeRoute.toString() == 'AppRoute.works',
                              onTap: () {
                                context.pop();
                                context.goNamed('works');
                              },
                            ),
                          ),
                          PermissionGuard(
                            module: 'work_plans',
                            permission: 'read',
                            child: DrawerItemWidget(
                              icon: CupertinoIcons.calendar_today,
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
                          ),
                          PermissionGuard(
                            module: 'materials',
                            permission: 'read',
                            child: DrawerItemWidget(
                              icon: CupertinoIcons.cube_box,
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
                          ),
                          PermissionGuard(
                            module: 'inventory',
                            permission: 'read',
                            child: DrawerItemWidget(
                              icon: CupertinoIcons.archivebox, // Склад
                              title: 'Склад',
                              isSelected: activeRoute == AppRoute.inventory,
                              onTap: () {
                                if (activeRoute == AppRoute.inventory) {
                                  context.pop();
                                } else {
                                  context.pop();
                                  context.goNamed('inventory');
                                }
                              },
                            ),
                          ),
                          PermissionGuard(
                            module: 'timesheet',
                            permission: 'read',
                            child: DrawerItemWidget(
                              icon: CupertinoIcons.clock,
                              title: 'Табель',
                              isSelected: activeRoute == AppRoute.timesheet,
                              onTap: () {
                                context.pop();
                                context.goNamed('timesheet');
                              },
                            ),
                          ),
                          // Админские разделы
                          PermissionGuard(
                            module: 'employees',
                            permission: 'read',
                            child: DrawerItemWidget(
                              icon: CupertinoIcons.person_3,
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
                          ),
                          Builder(builder: (context) {
                            final items = <DrawerGroupItem>[];
                            if (permissionService.can('objects', 'read')) {
                              items.add(DrawerGroupItem(
                                title: 'Объекты',
                                isSelected: (route) =>
                                    route == AppRoute.objects,
                                onTap: () {
                                  context.pop();
                                  context.goNamed('objects');
                                },
                              ));
                            }
                            if (permissionService.can('contractors', 'read')) {
                              items.add(DrawerGroupItem(
                                title: 'Контрагенты',
                                isSelected: (route) =>
                                    route == AppRoute.contractors,
                                onTap: () {
                                  context.pop();
                                  context.goNamed('contractors');
                                },
                              ));
                            }
                            if (permissionService.can('contracts', 'read')) {
                              items.add(DrawerGroupItem(
                                title: 'Договоры',
                                isSelected: (route) =>
                                    route == AppRoute.contracts,
                                onTap: () {
                                  context.pop();
                                  context.goNamed('contracts');
                                },
                              ));
                            }

                            if (items.isNotEmpty) {
                              return DrawerGroupWidget(
                                icon: CupertinoIcons.book,
                                title: 'Справочники',
                                activeRoute: activeRoute,
                                items: items,
                              );
                            }
                            return const SizedBox.shrink();
                          }),
                          PermissionGuard(
                            module: 'estimates',
                            permission: 'read',
                            child: DrawerItemWidget(
                              icon: CupertinoIcons.list_number,
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
                          ),
                          PermissionGuard(
                            module: 'payroll',
                            permission: 'read',
                            child: DrawerItemWidget(
                              icon: CupertinoIcons.creditcard,
                              title: 'ФОТ',
                              isSelected:
                                  activeRoute.toString() == 'AppRoute.payrolls',
                              onTap: () {
                                context.pop();
                                context.goNamed('payrolls');
                              },
                            ),
                          ),
                          PermissionGuard(
                            module: 'procurement',
                            permission: 'read',
                            child: DrawerItemWidget(
                              icon: CupertinoIcons.cart,
                              title: 'Заявки',
                              isSelected: activeRoute == AppRoute.procurement,
                              onTap: () {
                                if (activeRoute == AppRoute.procurement) {
                                  context.pop();
                                } else {
                                  context.pop();
                                  context.goNamed('procurement');
                                }
                              },
                            ),
                          ),
                          // Выгрузка доступна всем пользователям (с проверкой прав)
                          PermissionGuard(
                            module: 'export',
                            permission: 'read',
                            child: DrawerItemWidget(
                              icon: CupertinoIcons.tray_arrow_down,
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
                          ),
                          PermissionGuard(
                            module: 'users',
                            permission: 'read',
                            child: DrawerItemWidget(
                              icon: CupertinoIcons.person_2,
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
                          ),
                          PermissionGuard(
                            module: 'system',
                            permission: 'read',
                            child: DrawerItemWidget(
                              icon: CupertinoIcons.arrow_2_circlepath,
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
                          ),
                          PermissionGuard(
                            module: 'roles',
                            permission: 'read',
                            child: DrawerItemWidget(
                              icon: CupertinoIcons.lock_shield,
                              title: 'Управление ролями',
                              isSelected: activeRoute == AppRoute.roles,
                              onTap: () {
                                if (activeRoute == AppRoute.roles) {
                                  context.pop();
                                } else {
                                  context.pop();
                                  context.goNamed('roles');
                                }
                              },
                            ),
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
                        icon: CupertinoIcons.square_arrow_left,
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
