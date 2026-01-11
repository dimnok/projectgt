import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/domain/entities/profile.dart';
import 'package:projectgt/features/objects/domain/entities/object.dart';
import 'package:projectgt/features/profile/presentation/widgets/profile_edit_form.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/features/profile/presentation/widgets/profile_status_switch.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';

import 'package:projectgt/features/profile/presentation/widgets/profile_employee_link_info.dart';
import 'package:projectgt/features/roles/presentation/providers/roles_provider.dart';

/// Экран списка пользователей для десктопной версии.
class UsersListDesktopScreen extends ConsumerStatefulWidget {
  /// Список профилей пользователей.
  final List<Profile> profiles;

  /// Список всех доступных объектов.
  final List<ObjectEntity> allObjects;

  /// Флаг загрузки данных.
  final bool isLoading;

  /// Создаёт экран списка пользователей для десктопа.
  const UsersListDesktopScreen({
    super.key,
    required this.profiles,
    required this.allObjects,
    required this.isLoading,
  });

  @override
  ConsumerState<UsersListDesktopScreen> createState() =>
      _UsersListDesktopScreenState();
}

class _UsersListDesktopScreenState
    extends ConsumerState<UsersListDesktopScreen> {
  Profile? _selectedProfile;

  @override
  void initState() {
    super.initState();
    // Загружаем роли, если они еще не загружены, для корректного отображения названий
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rolesNotifierProvider.notifier).loadRoles();
    });
  }

  @override
  void didUpdateWidget(covariant UsersListDesktopScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Если выбранный профиль обновился в списке (например, изменился статус),
    // обновляем его и в _selectedProfile
    if (_selectedProfile != null) {
      try {
        final updatedProfile = widget.profiles.firstWhere(
          (p) => p.id == _selectedProfile!.id,
        );
        if (updatedProfile != _selectedProfile) {
          setState(() {
            _selectedProfile = updatedProfile;
          });
        }
      } catch (_) {
        // Профиль мог быть удален
        setState(() {
          _selectedProfile = null;
        });
      }
    }
  }

  void _showEditDialog(BuildContext context, Profile profile) {
    final isAdmin = ref.read(permissionServiceProvider).can('users', 'update');
    final formKey = GlobalKey<ProfileEditFormState>();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: DesktopDialogContent(
          title: 'Редактирование профиля',
          footer: Row(
            children: [
              Expanded(
                child: GTSecondaryButton(
                  text: 'Отмена',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GTPrimaryButton(
                  text: 'Сохранить',
                  onPressed: () {
                    formKey.currentState?.submit();
                  },
                ),
              ),
            ],
          ),
          child: ProfileEditForm(
            key: formKey,
            profile: profile,
            allObjects: widget.allObjects,
            isAdmin: isAdmin,
            initialEmployeeId: profile.object?['employee_id'] as String?,
            initialRoleId: profile.roleId,
            showButtons: false, // Скрываем кнопки внутри формы
            onSave: (fullName, phone, selectedObjectIds, employeeId, roleId) async {
              // [RBAC v3] В списке пользователей админ обновляет только данные в company_members
              // Мы НЕ вызываем updateProfile, так как это заблокировано RLS для чужих профилей
              if (profile.lastCompanyId != null) {
                try {
                  await ref
                      .read(profileProvider.notifier)
                      .updateMember(
                        userId: profile.id,
                        companyId: profile.lastCompanyId!,
                        roleId: roleId,
                      );

                  // Проверяем состояние после обновления
                  final state = ref.read(profileProvider);
                  if (state.status == ProfileStatus.error && context.mounted) {
                    AppSnackBar.show(
                      context: context,
                      message: 'Ошибка: ${state.errorMessage}',
                      kind: AppSnackBarKind.error,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    AppSnackBar.show(
                      context: context,
                      message: 'Ошибка при обновлении: $e',
                      kind: AppSnackBarKind.error,
                    );
                  }
                }
              }
            },
            onSuccess: () {
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color.fromRGBO(38, 40, 42, 1)
              : const Color.fromRGBO(248, 249, 250, 1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Левая панель - список пользователей
              Container(
                width: 350,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: widget.isLoading && widget.profiles.isEmpty
                    ? const Center(child: CupertinoActivityIndicator())
                    : widget.profiles.isEmpty
                    ? const Center(child: Text('Пользователи не найдены'))
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ListView.separated(
                          itemCount: widget.profiles.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            indent: 72,
                            color: theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          itemBuilder: (context, index) {
                            final profile = widget.profiles[index];
                            final isSelected =
                                _selectedProfile?.id == profile.id;
                            return _UserListTileDesktop(
                              profile: profile,
                              isSelected: isSelected,
                              onTap: () {
                                setState(() {
                                  _selectedProfile = profile;
                                });
                              },
                            );
                          },
                        ),
                      ),
              ),

              // Правая панель - детали
              Expanded(child: _buildDetailPanel(theme)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailPanel(ThemeData theme) {
    if (_selectedProfile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.person_crop_circle,
              size: 64,
              color: theme.colorScheme.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Выберите пользователя из списка',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    final profile = _selectedProfile!;
    final isAdmin = ref.read(permissionServiceProvider).can('users', 'update');

    // Фильтруем только существующие объекты
    final validObjects = widget.allObjects
        .where((o) => profile.objectIds?.contains(o.id) ?? false)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Шапка профиля
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage: profile.photoUrl != null
                      ? NetworkImage(profile.photoUrl!)
                      : null,
                  child: profile.photoUrl == null
                      ? Icon(
                          CupertinoIcons.person_fill,
                          color: theme.colorScheme.onPrimaryContainer,
                          size: 40,
                        )
                      : null,
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.fullName ?? 'Без имени',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (isAdmin)
                        Row(
                          children: [
                            ProfileStatusSwitch(
                              value: profile.status == true,
                              canToggle: isAdmin,
                              isBusy: false,
                              onChanged: (value) async {
                                // [RBAC v3] Обновляем статус в company_members
                                if (profile.lastCompanyId != null) {
                                  await ref
                                      .read(profileProvider.notifier)
                                      .updateMember(
                                        userId: profile.id,
                                        companyId: profile.lastCompanyId!,
                                        isActive: value,
                                      );
                                }
                              },
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (isAdmin)
                  GTPrimaryButton(
                    text: 'Редактировать',
                    icon: CupertinoIcons.pencil,
                    onPressed: () => _showEditDialog(context, profile),
                  ),
              ],
            ),
            const SizedBox(height: 32),

            // Основной контент в две колонки
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Левая колонка - Информация
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Информация', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 24),
                      Consumer(
                        builder: (context, ref, _) {
                          final rolesState = ref.watch(rolesNotifierProvider);
                          String getDisplayRole() {
                            if (profile.systemRole == 'owner') {
                              return 'Владелец';
                            }
                            if (profile.systemRole == 'admin') {
                              return 'Администратор';
                            }

                            final roleName = rolesState.valueOrNull
                                ?.where((r) => r.id == profile.roleId)
                                .firstOrNull
                                ?.name;

                            return roleName ??
                                (profile.roleId != null ? '...' : 'Без роли');
                          }

                          return _buildInfoRow(
                            theme,
                            'Роль',
                            '',
                            customContent: Row(
                              children: [
                                Text(
                                  getDisplayRole(),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (profile.roleId != null ||
                                    profile.systemRole != null) ...[
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () {
                                      context.pushNamed(
                                        'roles',
                                        queryParameters: {
                                          'roleId': profile.roleId!,
                                        },
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(
                                        CupertinoIcons.pencil,
                                        size: 16,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildInfoRow(
                        theme,
                        'Телефон',
                        profile.phone ?? 'Не указан',
                      ),
                      const SizedBox(height: 24),
                      _buildInfoRow(theme, 'Почта', profile.email),
                      if (profile.object?['employee_id'] != null) ...[
                        const SizedBox(height: 24),
                        _buildInfoRow(
                          theme,
                          'Привязанный сотрудник',
                          '', // Пустое значение, так как контент ниже
                          customContent: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: ProfileLinkedEmployeeInfo(
                                  employeeId: profile.object!['employee_id'],
                                  compact: false,
                                  showContainer: false,
                                  showHeader: false,
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  context.pushNamed(
                                    'employee_details',
                                    pathParameters: {
                                      'employeeId':
                                          profile.object!['employee_id'],
                                    },
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    CupertinoIcons.arrow_right_circle,
                                    size: 20,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 32),

                // Правая колонка - Доступные объекты
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Доступные объекты',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 24),
                      if (validObjects.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: validObjects.asMap().entries.map((entry) {
                            final index = entry.key + 1;
                            final obj = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                '$index. ${obj.name}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        )
                      else
                        Text(
                          'Нет доступных объектов',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            if (profile.roleId != null) ...[
              const SizedBox(height: 32),
              Text('Разрешения роли', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              _RolePermissionsWidget(roleId: profile.roleId!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme,
    String label,
    String value, {
    Widget? customContent,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150, // Увеличим ширину лейбла для отступов
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child:
              customContent ??
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
        ),
      ],
    );
  }
}

class _RolePermissionsWidget extends ConsumerWidget {
  final String roleId;

  const _RolePermissionsWidget({required this.roleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final modulesAsync = ref.watch(modulesProvider);
    final permissionsAsync = ref.watch(rolePermissionsProvider(roleId));

    return modulesAsync.when(
      data: (modules) {
        return permissionsAsync.when(
          data: (permissions) {
            if (permissions.isEmpty) {
              return Text(
                'Нет настроенных разрешений',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              );
            }

            // Filter modules that have at least one enabled permission
            final activeModules = modules.where((m) {
              final modulePerms = permissions[m.code];
              return modulePerms?.values.any((isEnabled) => isEnabled) ?? false;
            }).toList();

            if (activeModules.isEmpty) {
              return Text(
                'Нет активных разрешений',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              );
            }

            return Wrap(
              spacing: 24,
              runSpacing: 24,
              children: activeModules.map((module) {
                final modulePerms = permissions[module.code]!;
                final enabledPerms = modulePerms.entries
                    .where((e) => e.value)
                    .map((e) => e.key)
                    .toList();

                return SizedBox(
                  width: 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            module.icon,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              module.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...enabledPerms.map((perm) {
                        String permName = perm;
                        switch (perm) {
                          case 'read':
                            permName = 'Просмотр';
                            break;
                          case 'create':
                            permName = 'Создание';
                            break;
                          case 'update':
                            permName = 'Редактирование';
                            break;
                          case 'delete':
                            permName = 'Удаление';
                            break;
                          case 'export':
                            permName = 'Экспорт';
                            break;
                          case 'import':
                            permName = 'Импорт';
                            break;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4, left: 24),
                          child: Text(
                            permName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const CupertinoActivityIndicator(),
          error: (e, _) => Text('Ошибка: $e'),
        );
      },
      loading: () => const CupertinoActivityIndicator(),
      error: (e, _) => Text('Ошибка: $e'),
    );
  }
}

class _UserListTileDesktop extends StatelessWidget {
  final Profile profile;
  final bool isSelected;
  final VoidCallback onTap;

  const _UserListTileDesktop({
    required this.profile,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = profile.status == true;
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final subtitleColor = isSelected
        ? colorScheme.onPrimary.withValues(alpha: 0.8)
        : colorScheme.onSurfaceVariant;

    final titleColor = isSelected
        ? colorScheme.onPrimary
        : (!isActive
              ? colorScheme.onSurface.withValues(alpha: 0.38)
              : colorScheme.onSurface);

    return Material(
      color: isSelected ? colorScheme.primary : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.primaryContainer,
                    backgroundImage: profile.photoUrl != null
                        ? NetworkImage(profile.photoUrl!)
                        : null,
                    child: profile.photoUrl == null
                        ? Icon(
                            CupertinoIcons.person_fill,
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onPrimaryContainer,
                            size: 20,
                          )
                        : null,
                  ),
                  if (!isActive)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.fullName?.isNotEmpty == true
                          ? profile.fullName!
                          : 'Без имени',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.email,
                      style: textTheme.bodySmall?.copyWith(
                        color: subtitleColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
