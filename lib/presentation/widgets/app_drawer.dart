import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/presentation/state/auth_state.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:projectgt/presentation/widgets/drawer_item_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/features/company/presentation/widgets/company_create_dialog.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';
import 'package:projectgt/features/roles/presentation/widgets/role_badge.dart';
import 'package:collection/collection.dart';

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

  /// Экран модуля Cash Flow (Движение денежных средств).
  cashFlow,

  /// Экран модуля "Компания".
  company,
}

/// Виджет для группировки пунктов меню (например, "Справочники" с подпунктами).
class DrawerGroupWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAnyItemSelected = items.any((item) => item.isSelected(activeRoute));

    return _CollapsibleSection(
      initiallyExpanded: isAnyItemSelected,
      forceExpand: isAnyItemSelected,
      headerBuilder: (context, isExpanded, rotation) {
        final headerColor = isAnyItemSelected
            ? Colors.green
            : theme.colorScheme.onSurface;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Icon(
                    icon,
                    size: 20,
                    color: isAnyItemSelected
                        ? Colors.green
                        : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: headerColor,
                        fontSize: 16,
                        fontWeight: isAnyItemSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  RotationTransition(
                    turns: rotation,
                    child: Icon(
                      CupertinoIcons.chevron_right,
                      size: 20,
                      color: isAnyItemSelected ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      content: Column(
        children: items.map((item) {
          return DrawerItemWidget(
            title: item.title,
            icon: CupertinoIcons.circle,
            iconSize: 6,
            leadingPadding: 18,
            isSelected: item.isSelected(activeRoute),
            onTap: item.onTap,
          );
        }).toList(),
      ),
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

/// Функция для навигации с закрытием Drawer и проверкой текущего маршрута.
void _navigateTo(
  BuildContext context,
  String name,
  AppRoute route,
  AppRoute activeRoute,
) {
  context.pop();
  if (activeRoute != route) {
    context.goNamed(name);
  }
}

/// Боковое меню (Drawer) для навигации по основным разделам приложения.
class AppDrawer extends ConsumerWidget {
  /// Активный маршрут для выделения текущего пункта меню.
  final AppRoute activeRoute;

  /// Создаёт боковое меню с выделением [activeRoute].
  const AppDrawer({super.key, required this.activeRoute});

  Widget _buildMenuItem({
    required BuildContext context,
    required String module,
    required String title,
    required IconData icon,
    required AppRoute route,
    required String routeName,
  }) {
    return PermissionGuard(
      module: module,
      permission: 'read',
      child: DrawerItemWidget(
        icon: icon,
        title: title,
        isSelected: activeRoute == route,
        onTap: () => _navigateTo(context, routeName, route, activeRoute),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
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
                    _DrawerHeader(activeRoute: activeRoute),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          const _CompanySwitcher(),
                          const SizedBox(height: 8),
                          DrawerItemWidget(
                            icon: CupertinoIcons.home,
                            title: 'Главная',
                            isSelected: activeRoute == AppRoute.home,
                            onTap: () => _navigateTo(
                              context,
                              'home',
                              AppRoute.home,
                              activeRoute,
                            ),
                          ),
                          _buildMenuItem(
                            context: context,
                            module: 'cash_flow',
                            title: 'CASH FLOW',
                            icon: CupertinoIcons.money_rubl_circle,
                            route: AppRoute.cashFlow,
                            routeName: 'cash_flow',
                          ),
                          _buildMenuItem(
                            context: context,
                            module: 'company',
                            title: 'Компания',
                            icon: CupertinoIcons.briefcase,
                            route: AppRoute.company,
                            routeName: 'company',
                          ),
                          _buildMenuItem(
                            context: context,
                            module: 'works',
                            title: 'Работы',
                            icon: CupertinoIcons.wrench,
                            route: AppRoute.works,
                            routeName: 'works',
                          ),
                          _buildMenuItem(
                            context: context,
                            module: 'materials',
                            title: 'Материал',
                            icon: CupertinoIcons.cube_box,
                            route: AppRoute.material,
                            routeName: 'material',
                          ),
                          _buildMenuItem(
                            context: context,
                            module: 'inventory',
                            title: 'Склад',
                            icon: CupertinoIcons.archivebox,
                            route: AppRoute.inventory,
                            routeName: 'inventory',
                          ),
                          _buildMenuItem(
                            context: context,
                            module: 'timesheet',
                            title: 'Табель',
                            icon: CupertinoIcons.clock,
                            route: AppRoute.timesheet,
                            routeName: 'timesheet',
                          ),
                          _buildMenuItem(
                            context: context,
                            module: 'employees',
                            title: 'Сотрудники',
                            icon: CupertinoIcons.person_3,
                            route: AppRoute.employees,
                            routeName: 'employees',
                          ),
                          _DirectoriesSection(activeRoute: activeRoute),
                          _buildMenuItem(
                            context: context,
                            module: 'estimates',
                            title: 'Сметы',
                            icon: CupertinoIcons.list_number,
                            route: AppRoute.estimates,
                            routeName: 'estimates',
                          ),
                          _buildMenuItem(
                            context: context,
                            module: 'payroll',
                            title: 'ФОТ',
                            icon: CupertinoIcons.creditcard,
                            route: AppRoute.payrolls,
                            routeName: 'payrolls',
                          ),
                          _buildMenuItem(
                            context: context,
                            module: 'procurement',
                            title: 'Заявки',
                            icon: CupertinoIcons.cart,
                            route: AppRoute.procurement,
                            routeName: 'procurement',
                          ),
                          _buildMenuItem(
                            context: context,
                            module: 'export',
                            title: 'Выгрузка',
                            icon: CupertinoIcons.tray_arrow_down,
                            route: AppRoute.export,
                            routeName: 'export',
                          ),
                          _buildMenuItem(
                            context: context,
                            module: 'users',
                            title: 'Пользователи',
                            icon: CupertinoIcons.person_2,
                            route: AppRoute.users,
                            routeName: 'users',
                          ),
                          _buildMenuItem(
                            context: context,
                            module: 'system',
                            title: 'Управление версиями',
                            icon: CupertinoIcons.arrow_2_circlepath,
                            route: AppRoute.versionManagement,
                            routeName: 'version_management',
                          ),
                          _buildMenuItem(
                            context: context,
                            module: 'roles',
                            title: 'Управление ролями',
                            icon: CupertinoIcons.lock_shield,
                            route: AppRoute.roles,
                            routeName: 'roles',
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.1,
                        ),
                      ),
                    ),
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

/// Виджет заголовка бокового меню, отображающий информацию о текущем пользователе.
class _DrawerHeader extends ConsumerWidget {
  final AppRoute activeRoute;

  const _DrawerHeader({required this.activeRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final profileState = ref.watch(currentUserProfileProvider);
    final user = authState.user;
    final profile = profileState.profile;

    final photoUrl = profile?.photoUrl ?? user?.photoUrl;
    final displayName = profile?.shortName ?? user?.name ?? 'USER';
    final roleId = profile?.roleId ?? user?.roleId;
    final systemRole = profile?.systemRole ?? user?.systemRole;

    return Container(
      height: 120,
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
      child: Row(
        children: [
          GestureDetector(
            onTap: () =>
                _navigateTo(context, 'profile', AppRoute.profile, activeRoute),
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
                    child: photoUrl != null
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: photoUrl,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.1,
                                ),
                                child: Icon(
                                  CupertinoIcons.person,
                                  size: 32,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              errorWidget: (context, url, error) => const Icon(
                                CupertinoIcons.person,
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : const Icon(
                            CupertinoIcons.person,
                            size: 32,
                            color: Colors.white,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                RoleBadge(
                  roleId: roleId,
                  systemRole: systemRole,
                  fallbackRole: null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Виджет для переключения между компаниями пользователя в боковом меню.
class _CompanySwitcher extends ConsumerWidget {
  const _CompanySwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final companiesAsync = ref.watch(userCompaniesProvider);
    final activeCompanyId = ref.watch(activeCompanyIdProvider);

    return companiesAsync.when(
      data: (companies) {
        if (companies.isEmpty) return const SizedBox.shrink();

        final activeCompany =
            companies.firstWhereOrNull((c) => c.id == activeCompanyId) ??
            companies.first;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          child: _CollapsibleSection(
            headerBuilder: (context, isExpanded, rotation) {
              final headerColor = isExpanded
                  ? Colors.green
                  : theme.colorScheme.onSurface;

              return Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withValues(
                      alpha: isExpanded ? 0.1 : 0.05,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          activeCompany.nameShort,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: headerColor,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      RotationTransition(
                        turns: rotation,
                        child: Icon(
                          CupertinoIcons.chevron_right,
                          size: 18,
                          color: isExpanded ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            content: Column(
              children: [
                const SizedBox(height: 4),
                ...companies.where((c) => c.id != activeCompany.id).map((
                  company,
                ) {
                  return DrawerItemWidget(
                    title: company.nameShort,
                    icon: CupertinoIcons.circle,
                    iconSize: 4,
                    fontSize: 12,
                    leadingPadding: 32,
                    onTap: () async {
                      await ref
                          .read(authProvider.notifier)
                          .switchCompany(company.id);
                      if (context.mounted) context.pop();
                    },
                  );
                }),
                DrawerItemWidget(
                  title: 'Добавить компанию',
                  icon: CupertinoIcons.plus_circle,
                  iconSize: 16,
                  fontSize: 12,
                  leadingPadding: 32,
                  onTap: () {
                    context.pop();
                    CompanyCreateDialog.show(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CupertinoActivityIndicator(),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Вспомогательный виджет для реализации раскрывающихся секций в Drawer.
class _CollapsibleSection extends StatefulWidget {
  final Widget Function(
    BuildContext context,
    bool isExpanded,
    Animation<double> rotation,
  )
  headerBuilder;
  final Widget content;
  final bool initiallyExpanded;
  final bool forceExpand;

  const _CollapsibleSection({
    required this.headerBuilder,
    required this.content,
    this.initiallyExpanded = false,
    this.forceExpand = false,
  });

  @override
  State<_CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<_CollapsibleSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotation;
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      value: _isExpanded ? 1.0 : 0.0,
      vsync: this,
    );
    _rotation = Tween<double>(
      begin: 0,
      end: 0.25,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(_CollapsibleSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.forceExpand && !_isExpanded) {
      _toggle(true);
    }
  }

  void _toggle(bool expand) {
    setState(() => _isExpanded = expand);
    if (expand) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => _toggle(!_isExpanded),
          borderRadius: BorderRadius.circular(12),
          child: widget.headerBuilder(context, _isExpanded, _rotation),
        ),
        ClipRect(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Align(
                alignment: Alignment.topCenter,
                heightFactor: _controller.value,
                child: child,
              );
            },
            child: widget.content,
          ),
        ),
      ],
    );
  }
}

/// Секция справочников с проверкой прав доступа для каждого элемента.
class _DirectoriesSection extends ConsumerWidget {
  final AppRoute activeRoute;

  const _DirectoriesSection({required this.activeRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionService = ref.watch(permissionServiceProvider);
    final items = <DrawerGroupItem>[];

    void addIfAllowed(
      String module,
      String title,
      AppRoute route,
      String routeName,
    ) {
      if (permissionService.can(module, 'read')) {
        items.add(
          DrawerGroupItem(
            title: title,
            isSelected: (r) => r == route,
            onTap: () => _navigateTo(context, routeName, route, activeRoute),
          ),
        );
      }
    }

    addIfAllowed('objects', 'Объекты', AppRoute.objects, 'objects');
    addIfAllowed(
      'contractors',
      'Контрагенты',
      AppRoute.contractors,
      'contractors',
    );
    addIfAllowed('contracts', 'Договоры', AppRoute.contracts, 'contracts');

    if (items.isEmpty) return const SizedBox.shrink();

    return DrawerGroupWidget(
      icon: CupertinoIcons.book,
      title: 'Справочники',
      activeRoute: activeRoute,
      items: items,
    );
  }
}
