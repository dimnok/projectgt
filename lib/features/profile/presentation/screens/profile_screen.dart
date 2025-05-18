import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/presentation/state/auth_state.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:projectgt/presentation/widgets/app_bar_widget.dart';
import 'package:projectgt/presentation/widgets/app_drawer.dart';
import 'package:projectgt/presentation/widgets/photo_picker_avatar.dart';
import 'package:projectgt/domain/entities/object.dart';
import 'package:projectgt/domain/entities/profile.dart';
import 'package:projectgt/core/di/providers.dart';

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
  /// Контроллер для поля ФИО.
  final _fullNameController = TextEditingController();
  /// Контроллер для поля телефона.
  final _phoneController = TextEditingController();
  
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
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Загружает профиль пользователя, если он ещё не был загружен.
  void _loadProfileIfNeeded() {
    // Загружаем профиль только один раз при первом открытии экрана
    if (!_isInitialLoaded) {
      // Если передан userId, загружаем этот профиль, иначе профиль текущего пользователя
      final userId = widget.userId ?? ref.read(authProvider).user?.id;
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

  void _editProfile() {
    final theme = Theme.of(context);
    final profile = ref.read(profileProvider).profile;
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
            onSave: (fullName, phone, selectedObjectIds) {
              // Генерируем сокращенное имя из полного в формате "Фамилия И.О."
              String? shortName;
              if (fullName.isNotEmpty) {
                final nameParts = fullName.split(' ');
                if (nameParts.length > 1) {
                  String lastName = nameParts[0];
                  String initials = nameParts.sublist(1)
                      .where((part) => part.isNotEmpty)
                      .map((part) => '${part[0]}.')
                      .join('');
                  shortName = '$lastName $initials';
                } else {
                  shortName = fullName;
                }
              }
              final updatedProfile = profile.copyWith(
                fullName: fullName,
                shortName: shortName,
                phone: phone,
                objectIds: selectedObjectIds,
                updatedAt: DateTime.now(),
              );
              ref.read(profileProvider.notifier).updateProfile(updatedProfile);
              Navigator.pop(context);
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final profileState = ref.watch(profileProvider);
    final user = authState.user;
    final profile = profileState.profile;
    
    final isLoading = authState.status == AuthStatus.loading || 
                      profileState.status == ProfileStatus.loading;
    
    // Определяем, является ли этот профиль профилем текущего пользователя
    final isCurrentUser = _isCurrentUserProfile();
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const AppBarWidget(
        title: 'Профиль',
      ),
      // Показываем drawer только для профиля текущего пользователя
      drawer: isCurrentUser ? const AppDrawer(activeRoute: AppRoute.profile) : null,
      body: SafeArea(
        child: isLoading 
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async {
                  // Принудительно обновляем профиль при pull-to-refresh
                  final userId = widget.userId ?? ref.read(authProvider).user?.id;
                  if (userId != null) {
                    await ref.read(profileProvider.notifier).refreshProfile(userId);
                  }
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 40),
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
                        child: Column(
                          children: [
                            PhotoPickerAvatar(
                              imageUrl: profile?.photoUrl,
                              localFile: null,
                              label: 'Фото профиля',
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
                                  await ref.read(profileProvider.notifier).updateProfile(updatedProfile);
                                }
                              },
                              placeholderIcon: Icons.person,
                              radius: 60,
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
                            // Показываем кнопку редактирования для собственного профиля или любого профиля, если пользователь админ
                            if (isCurrentUser)
                              ElevatedButton.icon(
                                onPressed: _editProfile,
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                label: const Text('Редактировать'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ProfileInfoCard(
                              title: 'Личная информация',
                              items: [
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
                                  value: profile?.status == true ? 'Активен' : 'Не активен',
                                  valueColor: profile?.status == true 
                                      ? Colors.green 
                                      : Colors.red,
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
                                          .map((entry) => Text('${entry.key + 1}. ${entry.value.name}', style: theme.textTheme.titleMedium))
                                          .toList(),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            // Показываем кнопку выхода только для профиля текущего пользователя 
                            // (не на профилях, которые редактирует администратор)
                            if (widget.userId == null || ref.read(authProvider).user?.id == profile?.id)
                              _ProfileActionCard(
                                title: '',
                                actions: [
                                  _ProfileActionItem(
                                    icon: Icons.logout,
                                    title: 'Выйти из аккаунта',
                                    onTap: () {
                                      ref.read(authProvider.notifier).logout();
                                      context.goNamed('login');
                                    },
                                    isDestructive: true,
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
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

class _ProfileActionCard extends StatelessWidget {
  final String title;
  final List<Widget> actions;

  const _ProfileActionCard({
    required this.title,
    required this.actions,
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
            if (title.isNotEmpty) ...[
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
            ],
            ...actions,
          ],
        ),
      ),
    );
  }
}

class _ProfileActionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ProfileActionItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDestructive ? theme.colorScheme.error : theme.colorScheme.primary;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isDestructive ? theme.colorScheme.error : theme.colorScheme.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Форма редактирования профиля пользователя.
///
/// Позволяет изменить ФИО, телефон и список объектов пользователя.
class ProfileEditForm extends StatefulWidget {
  /// Профиль для редактирования.
  final Profile profile;
  /// Список всех объектов для выбора.
  final List<ObjectEntity> allObjects;
  /// Коллбэк сохранения изменений: (ФИО, телефон, список id объектов).
  final void Function(String fullName, String phone, List<String> selectedObjectIds) onSave;

  /// Создаёт форму редактирования профиля.
  const ProfileEditForm({
    required this.profile,
    required this.allObjects,
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
  
  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.profile.fullName ?? '');
    _phoneController = TextEditingController(text: widget.profile.phone ?? '');
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
          Text('Объекты', style: theme.textTheme.bodyLarge),
          SizedBox(
            height: 180,
            child: ListView(
              children: widget.allObjects.map((obj) {
                return CheckboxListTile(
                  title: Text(obj.name),
                  value: widget.profile.objectIds?.contains(obj.id) ?? false,
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        widget.profile.objectIds?.add(obj.id);
                      } else {
                        widget.profile.objectIds?.remove(obj.id);
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
              if (Form.of(context).validate()) {
                widget.onSave(
                  _fullNameController.text.trim(),
                  _phoneController.text.trim(),
                  widget.profile.objectIds ?? [],
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