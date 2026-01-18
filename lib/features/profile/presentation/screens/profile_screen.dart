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
import 'package:projectgt/presentation/widgets/photo_picker_avatar.dart';
import 'package:projectgt/features/profile/presentation/widgets/content_constrained_box.dart';
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
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/features/fot/presentation/providers/balance_providers.dart';

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
  const ProfileScreen({super.key, this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

/// Состояние для [ProfileScreen].
///
/// Управляет загрузкой, редактированием, обновлением и отображением профиля пользователя.
class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  /// Флаг для отслеживания первичной загрузки профиля.
  bool _isInitialLoaded = false;

  /// Информация о версии приложения.
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileIfNeeded();
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
      // Для текущего пользователя загрузкой занимается CurrentUserProfileNotifier.
      final userId = widget.userId;
      if (userId != null) {
        ref.read(profileProvider.notifier).getProfile(userId);
      }
      _isInitialLoaded = true;
    }
  }

  // Проверяем, является ли текущий профиль профилем авторизованного пользователя
  // или текущий пользователь - администратор
  bool _isCurrentUserProfile() {
    final authUser = ref.read(authProvider).user;
    final isOwn = widget.userId == null;
    final profile = isOwn
        ? ref.read(currentUserProfileProvider).profile
        : ref.read(profileProvider).profile;

    if (isOwn) {
      return true; // Если userId не передан, значит это экран текущего пользователя
    }

    // Администратор (с правом users.update) может редактировать любой профиль
    if (ref.read(permissionServiceProvider).can('users', 'update')) {
      return true;
    }

    return authUser?.id == profile?.id;
  }

  /// Обновляет профиль пользователя (текущий или просматриваемый).
  Future<void> _updateProfile(
    Profile updatedProfile,
    bool isOwn, {
    String? newRoleId,
    bool? newStatus,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      // Обновляем таблицу profiles
      if (isOwn) {
        await ref
            .read(currentUserProfileProvider.notifier)
            .updateCurrentUserProfile(updatedProfile);
      } else {
        // [RBAC v3] Если это чужой профиль и мы админы - обновляем его через основной провайдер
        await ref.read(profileProvider.notifier).updateProfile(updatedProfile);
      }

      // [RBAC v3] Если роль или статус были изменены админом, обновляем их в company_members
      // Это работает для любого пользователя (включая себя), если есть права
      if ((newRoleId != null || newStatus != null) &&
          updatedProfile.lastCompanyId != null) {
        await ref
            .read(profileProvider.notifier)
            .updateMember(
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

  void _editProfile(List<ObjectEntity> allObjects) {
    final bool isOwn = widget.userId == null;
    final profile = isOwn
        ? ref.read(currentUserProfileProvider).profile
        : ref.read(profileProvider).profile;
    final bool isAdmin = ref
        .read(permissionServiceProvider)
        .can('users', 'update');

    if (profile == null) return;

    final isDesktop =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;

    void onSave(
      String fullName,
      String phone,
      List<String> selectedObjectIds,
      String? employeeId,
      String? roleId,
    ) async {
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
      final String? changedRoleId = (isAdmin && roleId != profile.roleId)
          ? roleId
          : null;

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
              allObjects: allObjects,
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
            allObjects: allObjects,
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
    required List<ObjectEntity> allObjects,
  }) {
    if (!showLogout && !showEdit) return const SizedBox.shrink();

    final actions = <Widget>[];

    if (showEdit) {
      actions.add(
        AppleMenuItem(
          icon: CupertinoIcons.pencil,
          iconColor: CupertinoColors.systemBlue,
          title: 'Редактировать профиль',
          onTap: () => _editProfile(allObjects),
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
    double? balance,
  }) {
    if (!isDesktop) {
      // Мобильная версия: Единый блок (аватар + инфо) с кнопкой назад и эффектом парения
      return ContentConstrainedBox(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          decoration: BoxDecoration(
            // Градиентный фон для глубины
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.brightness == Brightness.dark
                    ? theme.colorScheme.surfaceContainerHighest
                    : const Color(0xFFF2F2F7),
                theme.brightness == Brightness.dark
                    ? theme.colorScheme.surfaceContainerHigh.withValues(
                        alpha: 0.8,
                      )
                    : const Color(0xFFE5E5EA),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            // Эффект парения: множественные тени для глубины
            boxShadow: [
              // Основная тень (глубина и объем)
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.45 : 0.25,
                ),
                blurRadius: 40,
                offset: const Offset(0, 20),
                spreadRadius: -8,
              ),
              // Вторичная тень (акцент на нижнем крае)
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.25 : 0.1,
                ),
                blurRadius: 16,
                offset: const Offset(0, 6),
                spreadRadius: 0,
              ),
              // Тонкая внутренняя тень (soft glow effect)
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 2),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Кнопка назад + ФИО + индикатор статуса в одну строку
                  Row(
                    children: [
                      _FloatingIconButton(
                        icon: CupertinoIcons.back,
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.goNamed('home');
                          }
                        },
                      ),
                      const SizedBox(width: 12),
                      // Индикатор статуса (точка)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: profile?.status == true
                              ? const Color(0xFF34C759) // systemGreen
                              : const Color(0xFFFF3B30), // systemRed
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: profile?.status == true
                                  ? const Color(
                                      0xFF34C759,
                                    ).withValues(alpha: 0.4)
                                  : const Color(
                                      0xFFFF3B30,
                                    ).withValues(alpha: 0.4),
                              blurRadius: 4,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // ФИО
                      Expanded(
                        child: Text(
                          profile?.fullName ?? user?.name ?? 'USER',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            height: 1.1,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: theme.brightness == Brightness.dark
                                  ? 0.12
                                  : 0.18,
                            ),
                            width: 1.0,
                          ),
                          boxShadow: [
                            // Основная тень (глубина)
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: theme.brightness == Brightness.dark
                                    ? 0.5
                                    : 0.35,
                              ),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                              spreadRadius: -6,
                            ),
                            // Вторичная тень (акцент на объеме)
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: theme.brightness == Brightness.dark
                                    ? 0.3
                                    : 0.15,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: PhotoPickerAvatar(
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
                          radius: 44, // Уменьшенный размер аватара
                          isSquare: true,
                          borderRadius: 16,
                          showCameraOverlay: false,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Роль над телефоном
                            RoleBadge(
                              roleId: profile?.roleId,
                              systemRole: profile?.systemRole,
                              fallbackRole: null,
                            ),
                            if (profile?.phone != null &&
                                profile!.phone!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                formatPhone(profile.phone),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.8,
                                  ),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                            const SizedBox(height: 2),
                            Text(
                              profile?.email ?? user?.email ?? 'Не указан',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (balance != null)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Баланс',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF34C759).withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        formatCurrency(balance),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF34C759),
                          letterSpacing: -0.2,
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

    // Десктопная версия (без изменений)
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
    required List<ObjectEntity> allObjects,
  }) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isDesktop) ...[
          // Группа: Основная информация (только для Desktop)
          AppleMenuGroup(
            children: [
              Builder(
                builder: (context) {
                  final employeeId = profile?.object?['employee_id'] as String?;
                  final hasEmployee =
                      employeeId != null && employeeId.isNotEmpty;

                  return AppleMenuItem(
                    icon: CupertinoIcons.person,
                    iconColor: CupertinoColors.systemBlue,
                    title: profile?.fullName ?? 'Не указано',
                    showChevron: hasEmployee,
                    onTap: hasEmployee
                        ? () {
                            context.pushNamed(
                              'employee_details',
                              pathParameters: {'employeeId': employeeId},
                            );
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
                  title: formatPhone(profile.phone),
                  showChevron: false,
                ),
            ],
          ),
          const SizedBox(height: 20),
        ] else ...[
          // Группа: Email удалена из мобильной версии, так как вынесена в хедер
          const SizedBox(height: 0),
        ],
        if ((profile?.objectIds?.isNotEmpty ?? false) &&
            allObjects.isNotEmpty) ...[
          const SizedBox(height: 20),
          // Группа: Объекты
          AppleMenuGroup(
            children: [
              AppleMenuItem(
                icon: CupertinoIcons.house_alt,
                iconColor: CupertinoColors.systemOrange,
                title: 'Объекты',
                subtitle: allObjects
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
          showLogout:
              widget.userId == null ||
              ref.read(authProvider).user?.id == profile?.id,
          showEdit: isCurrentUser,
          allObjects: allObjects,
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
    final bool isDesktop =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;
    final double avatarRadius = isDesktop ? 120.0 : 88.0;

    final isLoading =
        authState.status == AuthStatus.loading ||
        profileState.status == ProfileStatus.loading ||
        (profileState.status == ProfileStatus.initial && profile == null);

    // Определяем, является ли этот профиль профилем текущего пользователя
    final isCurrentUser = _isCurrentUserProfile();

    final allObjects = ref.watch(objectProvider).objects;
    final empId = profile?.object?['employee_id'] as String?;
    final balance = (empId != null)
        ? ref.watch(singleEmployeeBalanceProvider(empId)).valueOrNull
        : null;

    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: isDesktop
          ? AppBarWidget(
              title: 'Профиль',
              leading: Builder(
                builder: (context) => BackButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.goNamed('home');
                    }
                  },
                ),
              ),
              showThemeSwitch: false,
            )
          : null,
      body: isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Верхний блок с градиентом
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.only(
                      top: isDesktop ? (topInset + 24.0) : (topInset + 8.0),
                      bottom: 24,
                      left: isDesktop ? 0 : 16,
                      right: isDesktop ? 0 : 16,
                    ),
                    decoration: BoxDecoration(
                      color: isDesktop ? null : theme.scaffoldBackgroundColor,
                      gradient: isDesktop
                          ? LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                theme.colorScheme.primary.withValues(
                                  alpha: 0.05,
                                ),
                                theme.scaffoldBackgroundColor,
                              ],
                            )
                          : null,
                    ),
                    child: _buildHeaderSection(
                      theme: theme,
                      isDesktop: isDesktop,
                      avatarRadius: avatarRadius,
                      isLoading: isLoading,
                      profile: profile,
                      user: user,
                      isOwn: isOwn,
                      balance: balance,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildInfoSection(
                      theme: theme,
                      isDesktop: isDesktop,
                      profile: profile,
                      profileState: profileState,
                      isCurrentUser: isCurrentUser,
                      user: user,
                      isOwn: isOwn,
                      allObjects: allObjects,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Минималистичная плавающая кнопка для мобильного интерфейса.
class _FloatingIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _FloatingIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? theme.colorScheme.surface.withValues(alpha: 0.8)
            : theme.colorScheme.surface.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 0.5,
        ),
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.all(8),
        onPressed: onPressed,
        minimumSize: const Size(40, 40),
        child: Icon(
          icon,
          color: theme.colorScheme.onSurface,
          size: 22, // Чуть уменьшен размер для изящности
        ),
      ),
    );
  }
}
