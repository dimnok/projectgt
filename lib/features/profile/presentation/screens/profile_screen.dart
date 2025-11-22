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
import 'package:projectgt/features/profile/presentation/widgets/profile_status_switch.dart';
import 'package:projectgt/features/profile/presentation/screens/applications_screen.dart';
import 'package:projectgt/features/profile/presentation/screens/instructions_screen.dart';
import 'package:projectgt/domain/entities/object.dart';
import 'package:projectgt/domain/entities/profile.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/profile/presentation/widgets/profile_employee_link_edit_field.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';
import 'package:projectgt/features/roles/presentation/providers/roles_provider.dart';
import 'package:projectgt/features/roles/domain/entities/role.dart'
    as role_entity;
import 'package:projectgt/features/roles/presentation/widgets/role_badge.dart';

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
  String? _generateShortName(String fullName) {
    if (fullName.isEmpty) return null;

    final nameParts = fullName.split(' ');
    if (nameParts.length > 1) {
      final lastName = nameParts[0];
      final initials = nameParts
          .sublist(1)
          .where((part) => part.isNotEmpty)
          .map((part) => '${part[0]}.')
          .join('');
      return '$lastName $initials';
    }
    return fullName;
  }

  /// Обновляет профиль пользователя (текущий или просматриваемый).
  Future<void> _updateProfile(Profile updatedProfile, bool isOwn) async {
    if (isOwn) {
      await ref
          .read(currentUserProfileProvider.notifier)
          .updateCurrentUserProfile(updatedProfile);
    } else {
      await ref.read(profileProvider.notifier).updateProfile(updatedProfile);
    }
  }

  void _editProfile() {
    final theme = Theme.of(context);
    final bool isOwn = widget.userId == null;
    final profile = isOwn
        ? ref.read(currentUserProfileProvider).profile
        : ref.read(profileProvider).profile;
    final bool isAdmin =
        ref.read(permissionServiceProvider).can('users', 'update');
    if (profile != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: theme.colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: ProfileEditForm(
            profile: profile,
            allObjects: _allObjects,
            isAdmin: isAdmin,
            initialEmployeeId: profile.object?['employee_id'] as String?,
            initialRoleId: profile.roleId,
            onSave: (fullName, phone, selectedObjectIds, employeeId, roleId) {
              // Генерируем сокращенное имя
              final shortName = _generateShortName(fullName);

              // Обновляем связь с сотрудником
              final newObject = profile.object == null
                  ? <String, dynamic>{}
                  : Map<String, dynamic>.from(profile.object!);

              if (employeeId != null && employeeId.isNotEmpty) {
                newObject['employee_id'] = employeeId;
              } else {
                newObject.remove('employee_id');
              }

              // ⚠️ ВАЖНО: Если пользователь НЕ админ - НЕ меняем object_ids и roleId!
              final objectIdsToSave =
                  isAdmin ? selectedObjectIds : profile.objectIds ?? [];
              final roleIdToSave = isAdmin ? roleId : profile.roleId;

              final updatedProfile = profile.copyWith(
                fullName: fullName,
                shortName: shortName,
                phone: phone,
                objectIds:
                    objectIdsToSave, // ← Используем оригинальные если не админ
                roleId: roleIdToSave,
                object: newObject,
                updatedAt: DateTime.now(),
              );

              _updateProfile(updatedProfile, isOwn);

              if (context.mounted) {
                Navigator.pop(context);
              }
            },
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
        _AppleMenuItem(
          icon: Icons.edit_outlined,
          iconColor: Colors.blue,
          title: 'Редактировать профиль',
          onTap: _editProfile,
        ),
      );
    }

    if (showLogout) {
      actions.add(
        _AppleMenuItem(
          icon: Icons.logout,
          iconColor: Colors.red,
          title: 'Выйти из аккаунта',
          onTap: _confirmLogout,
        ),
      );
    }

    return _AppleMenuGroup(children: actions);
  }

  Widget _wrapDesktop({
    required bool isDesktop,
    required double contentMaxWidth,
    required Widget child,
  }) {
    if (!isDesktop) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: contentMaxWidth),
        child: child,
      ),
    );
  }

  Widget _buildHeaderSection({
    required ThemeData theme,
    required bool isDesktop,
    required double contentMaxWidth,
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
          placeholderIcon: Icons.person,
          radius: avatarRadius,
        ),
        const SizedBox(height: 16),
        Text(
          profile?.fullName ?? user?.name ?? 'USER',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
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

    return _wrapDesktop(
      isDesktop: isDesktop,
      contentMaxWidth: contentMaxWidth,
      child: header,
    );
  }

  Widget _buildInfoSection({
    required ThemeData theme,
    required bool isDesktop,
    required double contentMaxWidth,
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
        _AppleMenuGroup(
          children: [
            Builder(
              builder: (context) {
                final employeeId = profile?.object?['employee_id'] as String?;
                final hasEmployee = employeeId != null && employeeId.isNotEmpty;

                return _AppleMenuItem(
                  icon: Icons.person_outline,
                  iconColor: Colors.blue,
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
            _AppleMenuItem(
              icon: Icons.email_outlined,
              iconColor: Colors.grey,
              title: profile?.email ?? 'Не указан',
              showChevron: false,
            ),
            if (profile?.phone != null && profile!.phone!.isNotEmpty)
              _AppleMenuItem(
                icon: Icons.phone_outlined,
                iconColor: Colors.green,
                title: profile.phone!,
                showChevron: false,
              ),
          ],
        ),
        const SizedBox(height: 20),
        // Группа: Роль и статус
        _AppleMenuGroup(
          children: [
            _AppleMenuItem(
              icon: Icons.verified_user_outlined,
              iconColor: profile?.roleId != null ? Colors.purple : Colors.grey,
              title: 'Роль',
              trailing: RoleBadge(
                roleId: profile?.roleId,
                fallbackRole: null,
              ),
            ),
            _AppleMenuItem(
              icon: Icons.circle,
              iconColor: profile?.status == true ? Colors.green : Colors.red,
              title: 'Статус',
              subtitle: profile?.status == true ? 'Активен' : 'Не активен',
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
                    await _updateProfile(updatedProfile, isOwn);
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
          _AppleMenuGroup(
            children: [
              _AppleMenuItem(
                icon: Icons.location_city,
                iconColor: Colors.orange,
                title: 'Объекты',
                subtitle: _allObjects
                    .where((obj) => profile!.objectIds!.contains(obj.id))
                    .map((obj) => obj.name)
                    .join(', '),
                showChevron: false,
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        // Группа: Дополнительные разделы
        _AppleMenuGroup(
          children: [
            Builder(builder: (context) {
              final obj = profile?.object;
              final hasSlots = obj != null &&
                  obj.containsKey('slot_times') &&
                  ((obj['slot_times'] as List?) ?? const []).isNotEmpty;

              final notifEnabled =
                  obj != null && obj['notifications_enabled'] is bool
                      ? obj['notifications_enabled'] as bool
                      : hasSlots;

              return _AppleMenuItem(
                icon: Icons.notifications_outlined,
                iconColor: notifEnabled ? Colors.green : Colors.red,
                title: 'Уведомления',
                onTap: () => context.push('/profile/notifications'),
              );
            }),
            _AppleMenuItem(
              icon: Icons.account_balance_wallet_outlined,
              iconColor: Colors.green,
              title: 'Финансовая информация',
              onTap: () => context.push('/profile/financial'),
            ),
            _AppleMenuItem(
              icon: Icons.description_outlined,
              iconColor: Colors.orange,
              title: 'Заявления',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ApplicationsScreen(),
                  ),
                );
              },
            ),
            _AppleMenuItem(
              icon: Icons.inventory_2_outlined,
              iconColor: Colors.brown,
              title: 'Выданное имущество (ТМЦ)',
              onTap: () => context.push('/profile/property'),
            ),
            _AppleMenuItem(
              icon: Icons.help_outline,
              iconColor: Colors.blue,
              title: 'Инструкции',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const InstructionsScreen(),
                  ),
                );
              },
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
          _AppleMenuGroup(
            children: [
              _AppleMenuItem(
                icon: Icons.info_outline,
                iconColor: Colors.grey,
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

    return _wrapDesktop(
      isDesktop: isDesktop,
      contentMaxWidth: contentMaxWidth,
      child: content,
    );
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
        profileState.status == ProfileStatus.loading;

    // Определяем, является ли этот профиль профилем текущего пользователя
    final isCurrentUser = _isCurrentUserProfile();

    final topInset = MediaQuery.of(context).padding.top;
    // Высота нашего кастомного AppBarWidget (см. preferredSize) + небольшой зазор
    const appBarExtra = 24.0;
    final topOverlay = topInset + kToolbarHeight + appBarExtra;
    const double contentMaxWidth = 880;

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.light
          ? const Color(0xFFF2F2F7) // iOS светлый grouped background
          : const Color(0xFF1C1C1E), // iOS темный grouped background
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
                            theme.brightness == Brightness.light
                                ? const Color(0xFFF2F2F7)
                                : const Color(0xFF1C1C1E),
                          ],
                        ),
                      ),
                      child: _buildHeaderSection(
                        theme: theme,
                        isDesktop: isDesktop,
                        contentMaxWidth: contentMaxWidth,
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
                        contentMaxWidth: contentMaxWidth,
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

/// Группа элементов меню в стиле Apple Settings.
///
/// Объединяет несколько [_AppleMenuItem] в одну карточку с закругленными углами.
class _AppleMenuGroup extends StatelessWidget {
  /// Список элементов меню внутри группы.
  final List<Widget> children;

  /// Создаёт группу элементов меню.
  const _AppleMenuGroup({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: _buildChildrenWithDividers(context),
        ),
      ),
    );
  }

  /// Добавляет разделители между элементами списка.
  List<Widget> _buildChildrenWithDividers(BuildContext context) {
    final theme = Theme.of(context);
    final List<Widget> widgets = [];

    for (int i = 0; i < children.length; i++) {
      widgets.add(children[i]);
      if (i < children.length - 1) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 60, right: 16),
            child: Divider(
              height: 1,
              thickness: 1,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
            ),
          ),
        );
      }
    }

    return widgets;
  }
}

/// Элемент меню в стиле Apple Settings.
///
/// Отображает иконку, заголовок, опциональный подзаголовок и стрелку вправо.
class _AppleMenuItem extends StatelessWidget {
  /// Иконка элемента.
  final IconData icon;

  /// Цвет иконки.
  final Color iconColor;

  /// Основной текст элемента.
  final String title;

  /// Дополнительный текст под заголовком (опционально).
  final String? subtitle;

  /// Виджет справа (опционально, вместо стрелки).
  final Widget? trailing;

  /// Показывать ли стрелку вправо.
  final bool showChevron;

  /// Коллбэк при нажатии.
  final VoidCallback? onTap;

  /// Создаёт элемент меню в стиле Apple.
  const _AppleMenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showChevron = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // Иконка в цветном квадратике
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          // Текст
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
          // Trailing виджет или стрелка
          if (trailing != null)
            trailing!
          else if (showChevron)
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              size: 20,
            ),
        ],
      ),
    );

    if (onTap != null) {
      return _IOSTapEffect(
        onTap: onTap!,
        child: content,
      );
    }

    return content;
  }
}

/// Виджет для создания iOS-подобного эффекта затемнения при нажатии.
///
/// При нажатии элемент затемняется серым фоном, как в iOS Settings.
class _IOSTapEffect extends StatefulWidget {
  /// Дочерний виджет.
  final Widget child;

  /// Коллбэк при нажатии.
  final VoidCallback onTap;

  /// Создаёт виджет с iOS-подобным эффектом нажатия.
  const _IOSTapEffect({
    required this.child,
    required this.onTap,
  });

  @override
  State<_IOSTapEffect> createState() => _IOSTapEffectState();
}

/// Состояние для [_IOSTapEffect].
class _IOSTapEffectState extends State<_IOSTapEffect> {
  /// Флаг нажатия.
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _isPressed
            ? theme.colorScheme.onSurface.withValues(alpha: 0.08)
            : Colors.transparent,
        child: widget.child,
      ),
    );
  }
}

/// Форма редактирования профиля пользователя.
///
/// Позволяет изменить ФИО, телефон и список объектов пользователя.
class ProfileEditForm extends ConsumerStatefulWidget {
  /// Профиль для редактирования.
  final Profile profile;

  /// Список всех объектов для выбора.
  final List<ObjectEntity> allObjects;

  /// Признак, что текущий пользователь — администратор.
  final bool isAdmin;

  /// Изначально привязанный employee_id (если есть).
  final String? initialEmployeeId;

  /// Изначально привязанная роль (если есть).
  final String? initialRoleId;

  /// Коллбэк сохранения изменений: (ФИО, телефон, список id объектов, employeeId, roleId).
  final void Function(
      String fullName,
      String phone,
      List<String> selectedObjectIds,
      String? employeeId,
      String? roleId) onSave;

  /// Создаёт форму редактирования профиля.
  const ProfileEditForm({
    required this.profile,
    required this.allObjects,
    required this.isAdmin,
    this.initialEmployeeId,
    this.initialRoleId,
    required this.onSave,
    super.key,
  });

  @override
  ConsumerState<ProfileEditForm> createState() => _ProfileEditFormState();
}

/// Состояние для [ProfileEditForm].
///
/// Управляет контроллерами, обработкой выбора объектов и валидацией формы.
class _ProfileEditFormState extends ConsumerState<ProfileEditForm> {
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late List<String> _selectedObjectIds;
  final _formKey = GlobalKey<FormState>();
  late String _selectedEmployeeId;
  String? _selectedRoleId;
  List<role_entity.Role> _roles = [];

  /// Капитализирует каждое слово в строке (делает первую букву заглавной).
  String _capitalizeWords(String text) {
    if (text.isEmpty) return text;

    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Обрабатывает изменение текста в поле ФИО.
  void _onFullNameChanged(String value) {
    final capitalized = _capitalizeWords(value);
    if (capitalized != value) {
      _fullNameController.value = TextEditingValue(
        text: capitalized,
        selection: TextSelection.collapsed(offset: capitalized.length),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _fullNameController =
        TextEditingController(text: widget.profile.fullName ?? '');
    _phoneController = TextEditingController(text: widget.profile.phone ?? '');
    _selectedObjectIds = List<String>.from(widget.profile.objectIds ?? []);
    _selectedEmployeeId = (widget.initialEmployeeId ?? '').trim();
    _selectedRoleId = widget.initialRoleId;

    if (widget.isAdmin) {
      _loadRoles();
    }
  }

  Future<void> _loadRoles() async {
    try {
      final repo = ref.read(rolesRepositoryProvider);
      final roles = await repo.getAllRoles();
      if (mounted) {
        setState(() {
          _roles = roles;
        });
      }
    } catch (_) {
      // ignore
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Редактирование профиля',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _fullNameController,
            decoration: const InputDecoration(
              labelText: 'ФИО',
              prefixIcon: Icon(Icons.person_outline),
            ),
            onChanged: _onFullNameChanged,
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Пожалуйста, введите ФИО';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Телефон',
              prefixIcon: Icon(Icons.phone_outlined),
              hintText: '+7-(XXX)-XXX-XXXX',
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          if (widget.isAdmin) ...[
            ProfileEmployeeLinkEditField(
              initialEmployeeId:
                  _selectedEmployeeId.isEmpty ? null : _selectedEmployeeId,
              onChanged: (id) {
                setState(() {
                  _selectedEmployeeId = (id ?? '').trim();
                });
              },
            ),
            const SizedBox(height: 16),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Роль',
                prefixIcon: Icon(Icons.security),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedRoleId,
                  isDense: true,
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('Без роли (User)')),
                    ..._roles.map((role) => DropdownMenuItem(
                          value: role.id,
                          child: Text(role.name),
                        )),
                  ],
                  onChanged: (val) => setState(() => _selectedRoleId = val),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (widget.isAdmin) ...[
            Text('Объекты', style: theme.textTheme.bodyLarge),
            SizedBox(
              height: 180,
              child: ListView(
                children: widget.allObjects.map((obj) {
                  return CheckboxListTile(
                    title: Text(obj.name),
                    value: _selectedObjectIds.contains(obj.id),
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _selectedObjectIds.add(obj.id);
                        } else {
                          _selectedObjectIds.remove(obj.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ] else ...[
            const SizedBox(height: 24),
          ],
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                widget.onSave(
                  _fullNameController.text.trim(),
                  _phoneController.text.trim(),
                  _selectedObjectIds,
                  _selectedEmployeeId.isEmpty ? null : _selectedEmployeeId,
                  _selectedRoleId,
                );
              }
            },
            child: const Text('Сохранить'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Отмена'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
