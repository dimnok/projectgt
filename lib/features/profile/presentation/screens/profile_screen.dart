import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/presentation/state/auth_state.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:projectgt/presentation/widgets/photo_picker_avatar.dart';
import 'package:projectgt/features/profile/presentation/widgets/profile_status_switch.dart';
import 'package:projectgt/domain/entities/object.dart';
import 'package:projectgt/domain/entities/profile.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/profile/presentation/widgets/profile_employee_link_info.dart';
import 'package:projectgt/features/profile/presentation/widgets/profile_employee_link_edit_field.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileIfNeeded();
      _loadObjects();
    });
  }

  @override
  void dispose() {
    super.dispose();
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

    // Администратор может редактировать любой профиль
    if (authUser?.role == 'admin') {
      return true;
    }

    return authUser?.id == profile?.id;
  }

  /// Капитализирует каждое слово в строке (делает первую букву заглавной).
  String _capitalizeWords(String text) {
    if (text.isEmpty) return text;

    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  void _editProfile() {
    final theme = Theme.of(context);
    final bool isOwn = widget.userId == null;
    final profile = isOwn
        ? ref.read(currentUserProfileProvider).profile
        : ref.read(profileProvider).profile;
    final currentUser = ref.read(authProvider).user;
    final currentProfile = ref.read(currentUserProfileProvider).profile;
    final bool isAdmin =
        (currentUser?.role == 'admin') || (currentProfile?.role == 'admin');
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
            initialEmployeeId: (profile.object != null)
                ? (profile.object!['employee_id'] as String?)
                : null,
            onSave: (fullName, phone, selectedObjectIds, employeeId) {
              // Капитализируем ФИО перед обработкой
              final capitalizedFullName = _capitalizeWords(fullName);

              // Генерируем сокращенное имя из полного в формате "Фамилия И.О."
              String? shortName;
              if (capitalizedFullName.isNotEmpty) {
                final nameParts = capitalizedFullName.split(' ');
                if (nameParts.length > 1) {
                  String lastName = nameParts[0];
                  String initials = nameParts
                      .sublist(1)
                      .where((part) => part.isNotEmpty)
                      .map((part) => '${part[0]}.')
                      .join('');
                  shortName = '$lastName $initials';
                } else {
                  shortName = capitalizedFullName;
                }
              }
              // Временно сохраняем связь в object.employee_id, не меняя схему
              final Map<String, dynamic> baseObject = profile.object == null
                  ? <String, dynamic>{}
                  : Map<String, dynamic>.from(profile.object!);
              final Map<String, dynamic> newObject = {...baseObject};
              if (employeeId != null && employeeId.isNotEmpty) {
                newObject['employee_id'] = employeeId;
              } else {
                newObject.remove('employee_id');
              }

              final updatedProfile = profile.copyWith(
                fullName: capitalizedFullName,
                shortName: shortName,
                phone: phone,
                objectIds: selectedObjectIds,
                object: newObject,
                updatedAt: DateTime.now(),
              );
              if (isOwn) {
                ref
                    .read(currentUserProfileProvider.notifier)
                    .updateCurrentUserProfile(updatedProfile);
              } else {
                ref
                    .read(profileProvider.notifier)
                    .updateProfile(updatedProfile);
              }
              Navigator.pop(context);
            },
          ),
        ),
      );
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Подтвердить выход'),
        content: const Text('Вы действительно хотите выйти из аккаунта?'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) context.goNamed('login');
    }
  }

  Widget _buildEditButton(ThemeData theme) {
    return FilledButton(
      onPressed: _editProfile,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        minimumSize: const Size(0, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.edit_outlined, size: 18),
          SizedBox(width: 8),
          Text('Редактировать'),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(ThemeData theme) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: theme.colorScheme.error,
        foregroundColor: theme.colorScheme.onError,
        shape: const CircleBorder(),
        padding: EdgeInsets.zero,
        minimumSize: const Size(56, 56),
      ),
      onPressed: _confirmLogout,
      child: const Icon(Icons.logout, size: 24),
    );
  }

  Widget _buildBottomActions(ThemeData theme,
      {required bool showLogout, required bool showEdit}) {
    if (!showLogout && !showEdit) return const SizedBox.shrink();
    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showEdit)
            Align(
              alignment: Alignment.centerRight,
              child: _buildEditButton(theme),
            ),
          if (showLogout)
            Align(
              alignment: Alignment.centerLeft,
              child: _buildLogoutButton(theme),
            ),
        ],
      ),
    );
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
              if (isOwn) {
                await ref
                    .read(currentUserProfileProvider.notifier)
                    .updateCurrentUserProfile(updatedProfile);
              } else {
                await ref
                    .read(profileProvider.notifier)
                    .updateProfile(updatedProfile);
              }
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
    final infoItems = <Widget>[
      _ProfileInfoItem(
        icon: Icons.person_outline,
        title: 'ФИО',
        value: profile?.fullName ?? 'Не указано',
      ),
      _ProfileInfoItem(
        icon: Icons.email_outlined,
        title: 'Email',
        value: profile?.email ?? 'Не указан',
      ),
      _ProfileInfoItem(
        icon: Icons.phone_outlined,
        title: 'Телефон',
        value: profile?.phone ?? 'Не указан',
      ),
      _ProfileInfoItem(
        icon: Icons.verified_user_outlined,
        title: 'Роль',
        value: profile?.role == 'admin' ? 'ADMIN' : 'USER',
        valueColor: profile?.role == 'admin'
            ? Colors.purple
            : theme.colorScheme.onSurface.withValues(alpha: 0.7),
      ),
      _ProfileInfoItem(
        icon: Icons.circle,
        title: 'Статус',
        valueWidget: ProfileStatusSwitch(
          value: profile?.status == true,
          canToggle: ref.read(authProvider).user?.role == 'admin',
          isBusy: profileState.status == ProfileStatus.loading,
          onChanged: (v) async {
            final p = profile!;
            if (isOwn) {
              await ref
                  .read(currentUserProfileProvider.notifier)
                  .updateCurrentUserProfile(
                    p.copyWith(status: v, updatedAt: DateTime.now()),
                  );
            } else {
              await ref.read(profileProvider.notifier).updateProfile(
                    p.copyWith(status: v, updatedAt: DateTime.now()),
                  );
            }
          },
        ),
      ),
      if ((profile?.objectIds?.isNotEmpty ?? false) && _allObjects.isNotEmpty)
        _ProfileInfoItem(
          icon: Icons.location_city,
          title: 'Объекты',
          valueWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _allObjects
                .where((obj) => profile!.objectIds!.contains(obj.id))
                .toList()
                .asMap()
                .entries
                .map((entry) => Text(
                      '${entry.key + 1}. ${entry.value.name}',
                      style: theme.textTheme.titleMedium,
                    ))
                .toList(),
          ),
        ),
      // Отображение привязанного сотрудника — только для админа
      if (ref.read(authProvider).user?.role == 'admin')
        _ProfileInfoItem(
          icon: Icons.badge_outlined,
          title: 'Привязанный сотрудник',
          valueWidget: ProfileLinkedEmployeeInfo(profile: profile),
        ),
    ];

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProfileInfoCard(title: 'Личная информация', items: infoItems),
        const SizedBox(height: 12),
        // Кнопка перехода к настройкам уведомлений в стиле контейнера
        Builder(builder: (context) {
          // Определяем, включены ли уведомления
          final obj = profile?.object;
          final hasSlots = (obj != null && obj.containsKey('slot_times'))
              ? (((obj['slot_times'] as List?) ?? const [])).isNotEmpty
              : false;
          final bool notifEnabled =
              (obj != null && obj['notifications_enabled'] is bool)
                  ? (obj['notifications_enabled'] as bool)
                  : hasSlots;
          final iconData = notifEnabled
              ? Icons.notifications_active_outlined
              : Icons.notifications_off_outlined;
          final iconColor = notifEnabled ? Colors.green : Colors.red;
          return InkWell(
            onTap: () => context.push('/profile/notifications'),
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  width: 1,
                ),
                color: theme.colorScheme.surface,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(iconData, color: iconColor, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Уведомления',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox.shrink(),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        // Кнопка "Финансовая информация" в том же стиле, под уведомлениями
        InkWell(
          onTap: () => context.push('/profile/financial'),
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                width: 1,
              ),
              color: theme.colorScheme.surface,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Финансовая информация',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox.shrink(),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildBottomActions(
          theme,
          showLogout: (widget.userId == null ||
              ref.read(authProvider).user?.id == profile?.id),
          showEdit: isCurrentUser,
        ),
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
      backgroundColor: theme.colorScheme.surface,
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
                            theme.colorScheme.surface,
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

class _ProfileInfoCard extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _ProfileInfoCard({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...items,
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? value;
  final Widget? valueWidget;
  final Color? valueColor;

  const _ProfileInfoItem({
    required this.icon,
    required this.title,
    this.value,
    this.valueWidget,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                if (valueWidget != null)
                  valueWidget!
                else if (value != null)
                  Text(
                    value!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: valueColor ?? theme.colorScheme.onSurface,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Удалён _ProfileActionCard как неиспользуемый

// Удалён _ProfileActionItem как неиспользуемый

/// Форма редактирования профиля пользователя.
///
/// Позволяет изменить ФИО, телефон и список объектов пользователя.
class ProfileEditForm extends StatefulWidget {
  /// Профиль для редактирования.
  final Profile profile;

  /// Список всех объектов для выбора.
  final List<ObjectEntity> allObjects;

  /// Признак, что текущий пользователь — администратор.
  final bool isAdmin;

  /// Изначально привязанный employee_id (если есть).
  final String? initialEmployeeId;

  /// Коллбэк сохранения изменений: (ФИО, телефон, список id объектов, employeeId).
  final void Function(String fullName, String phone,
      List<String> selectedObjectIds, String? employeeId) onSave;

  /// Создаёт форму редактирования профиля.
  const ProfileEditForm({
    required this.profile,
    required this.allObjects,
    required this.isAdmin,
    this.initialEmployeeId,
    required this.onSave,
    super.key,
  });

  @override
  State<ProfileEditForm> createState() => _ProfileEditFormState();
}

/// Состояние для [ProfileEditForm].
///
/// Управляет контроллерами, обработкой выбора объектов и валидацией формы.
class _ProfileEditFormState extends State<ProfileEditForm> {
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late List<String> _selectedObjectIds;
  final _formKey = GlobalKey<FormState>();
  late String _selectedEmployeeId;

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
          ],
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
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                widget.onSave(
                  _capitalizeWords(_fullNameController.text.trim()),
                  _phoneController.text.trim(),
                  _selectedObjectIds,
                  _selectedEmployeeId.isEmpty ? null : _selectedEmployeeId,
                );
              }
            },
            child: const Text('Сохранить'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// удалено: валидатор времени уведомлений (перенос настроек в отдельный экран)
