import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:projectgt/presentation/state/auth_state.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:projectgt/presentation/widgets/photo_picker_avatar.dart';
import 'package:projectgt/features/profile/presentation/widgets/content_constrained_box.dart';
import 'package:projectgt/features/profile/presentation/widgets/profile_status_switch.dart';
import 'package:projectgt/features/profile/presentation/screens/applications_screen.dart';
import 'package:projectgt/features/profile/presentation/screens/instructions_screen.dart';
import 'package:projectgt/features/objects/domain/entities/object.dart';
import 'package:projectgt/domain/entities/profile.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/profile/presentation/widgets/profile_edit_form.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';
import 'package:projectgt/features/roles/presentation/widgets/role_badge.dart';
import 'package:projectgt/presentation/widgets/grouped_menu.dart';
import 'package:projectgt/features/profile/utils/profile_utils.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';

/// Экран профиля пользователя.
///
/// Позволяет просматривать и редактировать профиль, менять фото, а также выполнять выход из аккаунта.
/// Поддерживает просмотр чужого профиля (для админа) и собственного профиля.
///
/// Пример использования:
/// ```dart
/// ProfileScreen();
/// ProfileScreen(userId: 'user-123');
/// ```
class ProfileScreen extends ConsumerStatefulWidget {
  /// Идентификатор пользователя для просмотра профиля (опционально).
  final String? userId;

  /// Создаёт экран профиля для [userId] или текущего пользователя.
  const ProfileScreen({
    super.key,
    this.userId,
  });

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

/// Состояние для [ProfileScreen].
///
/// Управляет загрузкой, редактированием, обновлением и отображением профиля пользователя.
class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  /// Флаг для отслеживания первичной загрузки профиля.
  bool _isInitialLoaded = false;

  /// Список всех объектов, доступных пользователю.
  List<ObjectEntity> _allObjects = [];

  /// Информация о версии приложения.
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileIfNeeded();
      _loadObjects();
      _loadAppVersion();
    });
  }

  /// Загружает информацию о версии приложения.
  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();

      if (mounted) {
        setState(() {
          // Проверяем, что version не пустой
          if (packageInfo.version.isNotEmpty) {
            _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
          } else {
            _appVersion = 'Build ${packageInfo.buildNumber}';
          }
        });
      }
    } catch (e) {
      // Тихий fallback на версию из pubspec.yaml для Web
      if (mounted) {
        setState(() {
          _appVersion = '1.0.2+22';
        });
      }
    }
  }

  /// Загружает профиль пользователя, если он ещё не был загружен.
  void _loadProfileIfNeeded() {
    // Загружаем профиль только один раз при первом открытии экрана
    if (!_isInitialLoaded) {
      // Если передан userId, загружаем этот профиль.
      // Для текущего пользователя загрузкой занимается ProfileNotifier.
      final userId = widget.userId;
      if (userId != null) {
        ref.read(profileProvider.notifier).getProfile(userId);
      }
      _isInitialLoaded = true;
    }
  }

  /// Загружает список объектов из репозитория.
  Future<void> _loadObjects() async {
    final objects = await ref.read(objectRepositoryProvider).getObjects();
    if (!mounted) return;
    setState(() {
      _allObjects = objects;
    });
  }

  // Проверяем, является ли текущий профиль профилем авторизованного пользователя
  // или текущий пользователь - администратор
  bool _isCurrentUserProfile() {
    final authUser = ref.read(authProvider).user;
    final profile = ref.read(profileProvider).profile;

    if (widget.userId == null) {
      return true; // Если userId не передан, значит это экран текущего пользователя
    }

    // Администратор (с правом users.update) может редактировать любой профиль
    if (ref.read(permissionServiceProvider).can('users', 'update')) {
      return true;
    }

    return authUser?.id == profile?.id;
  }

  /// Генерирует сокращенное имя из полного в формате "Фамилия И.О.".
  // String? _generateShortName(String fullName) { ... } // Удалено, используется ProfileUtils

  /// Обновляет профиль пользователя (текущий или просматриваемый).
  Future<void> _updateProfile(Profile updatedProfile, bool isOwn,
      {String? newRoleId, bool? newStatus}) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      // Обновляем таблицу profiles только если это наш собственный профиль
      if (isOwn) {
        await ref
            .read(currentUserProfileProvider.notifier)
            .updateCurrentUserProfile(updatedProfile);
      }

      // [RBAC v3] Если роль или статус были изменены админом, обновляем их в company_members
      // Это работает для любого пользователя (включая себя), если есть права
      if ((newRoleId != null || newStatus != null) &&
          updatedProfile.lastCompanyId != null) {
        await ref.read(profileProvider.notifier).updateMember(
              userId: updatedProfile.id,
              companyId: updatedProfile.lastCompanyId!,
              roleId: newRoleId,
              isActive: newStatus,
            );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Ошибка при обновлении: $e')),
        );
      }
    }
  }

  void _editProfile() {
    final bool isOwn = widget.userId == null;
    final profile = isOwn
        ? ref.read(currentUserProfileProvider).profile
        : ref.read(profileProvider).profile;
    final bool isAdmin =
        ref.read(permissionServiceProvider).can('users', 'update');

    if (profile == null) return;

    final isDesktop = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;

    void onSave(String fullName, String phone, List<String> selectedObjectIds,
        String? employeeId, String? roleId) async {
      final navigator = Navigator.of(context);
      final updatedProfile = ProfileUtils.prepareProfileForUpdate(
        originalProfile: profile,
        fullName: fullName,
        phone: phone,
        selectedObjectIds: selectedObjectIds,
        employeeId: employeeId,
        roleId: roleId,
        isAdmin: isAdmin,
      );

      // Передаем newRoleId только если он изменился и мы админы
      final String? changedRoleId =
          (isAdmin && roleId != profile.roleId) ? roleId : null;

      await _updateProfile(updatedProfile, isOwn, newRoleId: changedRoleId);

      if (mounted) {
        navigator.pop();
      }
    }

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.all(24),
          child: DesktopDialogContent(
            title: 'Редактирование профиля',
            child: ProfileEditForm(
              profile: profile,
              allObjects: _allObjects,
              isAdmin: isAdmin,
              initialEmployeeId: profile.object?['employee_id'] as String?,
              initialRoleId: profile.roleId,
              onSave: onSave,
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        constraints: const BoxConstraints(maxWidth: 640),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => MobileBottomSheetContent(
          title: 'Редактирование профиля',
          child: ProfileEditForm(
            profile: profile,
            allObjects: _allObjects,
            isAdmin: isAdmin,
            initialEmployeeId: profile.object?['employee_id'] as String?,
            initialRoleId: profile.roleId,
            onSave: onSave,
          ),
        ),
      );
    }
  }

  Future<void> _confirmLogout() async {
    bool? confirmed;
    await AdaptiveAlertDialog.show(
      context: context,
      title: 'Подтвердить выход',
      message: 'Вы действительно хотите выйти из аккаунта?',
      icon: 'arrow.right.square.fill',
      actions: [
        AlertAction(
          title: 'Отмена',
          style: AlertActionStyle.cancel,
          onPressed: () {
            confirmed = false;
          },
        ),
        AlertAction(
          title: 'Выйти',
          style: AlertActionStyle.destructive,
          onPressed: () {
            confirmed = true;
          },
        ),
      ],
    );
    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) context.goNamed('login');
    }
  }

  /// Строит группу действий (редактирование, выход) в стиле Apple Settings.
  Widget _buildActionsGroup({
    required bool showLogout,
    required bool showEdit,
  }) {
    if (!showLogout && !showEdit) return const SizedBox.shrink();

    final actions = <Widget>[];

    if (showEdit) {
      actions.add(
        AppleMenuItem(
          icon: CupertinoIcons.pencil,
          iconColor: CupertinoColors.systemBlue,
          title: 'Редактировать профиль',
          onTap: _editProfile,
        ),
      );
    }

    if (showLogout) {
      actions.add(
        AppleMenuItem(
          icon: CupertinoIcons.square_arrow_right,
          iconColor: CupertinoColors.systemRed,
          title: 'Выйти из аккаунта',
          onTap: _confirmLogout,
        ),
      );
    }

    return AppleMenuGroup(children: actions);
  }

  Widget _buildHeaderSection({
    required ThemeData theme,
    required bool isDesktop,
    required double avatarRadius,
    required bool isLoading,
    required Profile? profile,
    required dynamic user,
    required bool isOwn,
  }) {
    final header = Column(
      children: [
        PhotoPickerAvatar(
          imageUrl: profile?.photoUrl,
          localFile: null,
          label: '',
          isLoading: isLoading,
          entity: 'profile',
          id: profile?.id ?? user?.id ?? '',
          displayName: profile?.fullName ?? user?.name ?? '',
          onPhotoChanged: (url) async {
            if (profile != null) {
              final updatedProfile = profile.copyWith(
                photoUrl: url,
                updatedAt: DateTime.now(),
              );
              await _updateProfile(updatedProfile, isOwn);
            }
          },
          placeholderIcon: CupertinoIcons.person_fill,
          radius: avatarRadius,
        ),
        const SizedBox(height: 16),
        Text(
          profile?.fullName ?? user?.name ?? 'USER',
          style: theme.textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          profile?.email ?? user?.email ?? 'email@example.com',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
      ],
    );

    return ContentConstrainedBox(child: header);
  }

  Widget _buildInfoSection({
    required ThemeData theme,
    required bool isDesktop,
    required Profile? profile,
    required ProfileState profileState,
    required bool isCurrentUser,
    required dynamic user,
    required bool isOwn,
  }) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Группа: Основная информация
        AppleMenuGroup(
          children: [
            Builder(
              builder: (context) {
                final employeeId = profile?.object?['employee_id'] as String?;
                final hasEmployee = employeeId != null && employeeId.isNotEmpty;

                return AppleMenuItem(
                  icon: CupertinoIcons.person,
                  iconColor: CupertinoColors.systemBlue,
                  title: profile?.fullName ?? 'Не указано',
                  showChevron: hasEmployee,
                  onTap: hasEmployee
                      ? () {
                          context
                              .pushNamed('employee_details', pathParameters: {
                            'employeeId': employeeId,
                          });
                        }
                      : null,
                );
              },
            ),
            AppleMenuItem(
              icon: CupertinoIcons.mail,
              iconColor: CupertinoColors.systemGrey,
              title: profile?.email ?? 'Не указан',
              showChevron: false,
            ),
            if (profile?.phone != null && profile!.phone!.isNotEmpty)
              AppleMenuItem(
                icon: CupertinoIcons.phone,
                iconColor: CupertinoColors.systemGreen,
                title: profile.phone!,
                showChevron: false,
              ),
          ],
        ),
        const SizedBox(height: 20),
        // Группа: Роль и статус
        AppleMenuGroup(
          children: [
            AppleMenuItem(
              icon: CupertinoIcons.shield,
              iconColor: CupertinoColors.systemPurple,
              title: 'Роль',
              trailing: RoleBadge(
                roleId: profile?.roleId,
                systemRole: profile?.systemRole,
                fallbackRole: null,
              ),
            ),
            AppleMenuItem(
              icon: CupertinoIcons.circle,
              iconColor: profile?.status == true
                  ? CupertinoColors.systemGreen
                  : CupertinoColors.systemRed,
              title: 'Статус',
              trailing: ProfileStatusSwitch(
                value: profile?.status == true,
                canToggle:
                    ref.read(permissionServiceProvider).can('users', 'update'),
                isBusy: profileState.status == ProfileStatus.loading,
                onChanged: (v) async {
                  if (profile != null) {
                    final updatedProfile = profile.copyWith(
                      status: v,
                      updatedAt: DateTime.now(),
                    );
                    await _updateProfile(updatedProfile, isOwn, newStatus: v);
                  }
                },
              ),
              showChevron: false,
            ),
          ],
        ),
        if ((profile?.objectIds?.isNotEmpty ?? false) &&
            _allObjects.isNotEmpty) ...[
          const SizedBox(height: 20),
          // Группа: Объекты
          AppleMenuGroup(
            children: [
              AppleMenuItem(
                icon: CupertinoIcons.house_alt,
                iconColor: CupertinoColors.systemOrange,
                title: 'Объекты',
                subtitle: _allObjects
                    .where((obj) => profile!.objectIds!.contains(obj.id))
                    .map((obj) => obj.name)
                    .join(', '),
                subtitleMaxLines: 1,
                showChevron: false,
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        // Группа: Дополнительные разделы
        AppleMenuGroup(
          children: [
            AppleMenuItem(
              icon: CupertinoIcons.bell,
              iconColor: CupertinoColors.systemRed,
              title: 'Уведомления',
              onTap: () => context.push('/profile/notifications'),
            ),
            AppleMenuItem(
              icon: CupertinoIcons.money_dollar,
              iconColor: CupertinoColors.systemGreen,
              title: 'Финансовая информация',
              onTap: () => context.push('/profile/financial'),
            ),
            AppleMenuItem(
              icon: CupertinoIcons.doc_text,
              iconColor: CupertinoColors.systemOrange,
              title: 'Заявления',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ApplicationsScreen(),
                  ),
                );
              },
            ),
            AppleMenuItem(
              icon: CupertinoIcons.cube_box,
              iconColor: Colors.brown,
              title: 'Выданное имущество (ТМЦ)',
              onTap: () => context.push('/profile/property'),
            ),
            AppleMenuItem(
              icon: CupertinoIcons.question_circle,
              iconColor: CupertinoColors.systemBlue,
              title: 'Инструкции',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const InstructionsScreen(),
                  ),
                );
              },
            ),
            AppleMenuItem(
              icon: CupertinoIcons.settings,
              iconColor: CupertinoColors.systemGrey,
              title: 'Настройки',
              onTap: () => context.push('/profile/settings'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Группа: Действия
        _buildActionsGroup(
          showLogout: widget.userId == null ||
              ref.read(authProvider).user?.id == profile?.id,
          showEdit: isCurrentUser,
        ),
        if (_appVersion.isNotEmpty) ...[
          const SizedBox(height: 20),
          AppleMenuGroup(
            children: [
              AppleMenuItem(
                icon: CupertinoIcons.info,
                iconColor: CupertinoColors.systemGrey,
                title: 'Версия приложения',
                trailing: Text(
                  _appVersion,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                showChevron: false,
              ),
            ],
          ),
        ],
        const SizedBox(height: 24),
      ],
    );

    return ContentConstrainedBox(child: content);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final bool isOwn = widget.userId == null;
    final profileState = isOwn
        ? ref.watch(currentUserProfileProvider)
        : ref.watch(profileProvider);
    final user = authState.user;
    final profile = profileState.profile;

    // Desktop/Web: крупнее аватар
    final bool isDesktop = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;
    final double avatarRadius = isDesktop ? 120.0 : 88.0;

    final isLoading = authState.status == AuthStatus.loading ||
        profileState.status == ProfileStatus.loading ||
        (profileState.status == ProfileStatus.initial && profile == null);

    // Определяем, является ли этот профиль профилем текущего пользователя
    final isCurrentUser = _isCurrentUserProfile();

    final topInset = MediaQuery.of(context).padding.top;
    // Высота нашего кастомного AppBarWidget (см. preferredSize) + небольшой зазор
    const appBarExtra = 24.0;
    final topOverlay = topInset + kToolbarHeight + appBarExtra;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBarWidget(
        title: 'Профиль',
        leading: widget.userId != null ? const BackButton() : null,
      ),
      drawer:
          isCurrentUser ? const AppDrawer(activeRoute: AppRoute.profile) : null,
      body: isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                final userId = widget.userId ?? ref.read(authProvider).user?.id;
                if (userId != null) {
                  if (isOwn) {
                    await ref
                        .read(currentUserProfileProvider.notifier)
                        .refreshCurrentUserProfile(userId);
                  } else {
                    await ref
                        .read(profileProvider.notifier)
                        .refreshProfile(userId);
                  }
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Верхний блок с градиентом виден под AppBar за счет extendBodyBehindAppBar
                    Container(
                      width: double.infinity,
                      padding:
                          EdgeInsets.only(top: topOverlay + 16, bottom: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.05),
                            theme.scaffoldBackgroundColor,
                          ],
                        ),
                      ),
                      child: _buildHeaderSection(
                        theme: theme,
                        isDesktop: isDesktop,
                        avatarRadius: avatarRadius,
                        isLoading: isLoading,
                        profile: profile,
                        user: user,
                        isOwn: isOwn,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildInfoSection(
                        theme: theme,
                        isDesktop: isDesktop,
                        profile: profile,
                        profileState: profileState,
                        isCurrentUser: isCurrentUser,
                        user: user,
                        isOwn: isOwn,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
