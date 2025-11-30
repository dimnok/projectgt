import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/domain/entities/profile.dart';
import 'package:projectgt/domain/entities/object.dart';
import 'package:projectgt/features/profile/presentation/widgets/profile_edit_form.dart';
import 'package:projectgt/features/profile/presentation/widgets/profile_employee_link_info.dart';
import 'package:projectgt/features/profile/presentation/widgets/profile_status_switch.dart';
import 'package:projectgt/features/roles/application/permission_service.dart';
import 'package:projectgt/features/profile/utils/profile_utils.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/presentation/state/profile_state.dart';
import 'package:projectgt/features/profile/presentation/widgets/content_constrained_box.dart';
import 'package:projectgt/features/roles/presentation/providers/roles_provider.dart';

/// Экран списка пользователей для мобильных устройств.
class UsersListMobileScreen extends ConsumerStatefulWidget {
  /// Список профилей.
  final List<Profile> profiles;

  /// Все объекты (для редактирования).
  final List<ObjectEntity> allObjects;

  /// Статус загрузки.
  final bool isLoading;

  /// Статус ошибки.
  final bool isError;

  /// Сообщение об ошибке.
  final String? errorMessage;

  /// Создаёт экран списка пользователей для мобильных устройств.
  const UsersListMobileScreen({
    super.key,
    required this.profiles,
    required this.allObjects,
    required this.isLoading,
    required this.isError,
    this.errorMessage,
  });

  @override
  ConsumerState<UsersListMobileScreen> createState() =>
      _UsersListMobileScreenState();
}

class _UsersListMobileScreenState extends ConsumerState<UsersListMobileScreen> {
  @override
  void initState() {
    super.initState();
    // Загружаем роли для отображения названий
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rolesNotifierProvider.notifier).loadRoles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ContentConstrainedBox(
      child: Column(
        children: [
          Expanded(
            child: Builder(
              builder: (context) {
                if (widget.isLoading && widget.profiles.isEmpty) {
                  return const Center(child: CupertinoActivityIndicator());
                }

                if (widget.isError) {
                  return Center(
                    child: Text(
                        'Ошибка: ${widget.errorMessage ?? "Неизвестная ошибка"}'),
                  );
                }

                if (widget.profiles.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.person_badge_minus_fill,
                          size: 48,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Пользователи не найдены',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.only(
                      left: 16, right: 16, top: 16, bottom: 80),
                  itemCount: widget.profiles.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final profile = widget.profiles[index];
                    return _UserListTile(
                      profile: profile,
                      onEdit: () => _showEditModal(context, ref, profile),
                      isBusy: widget.isLoading,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showEditModal(BuildContext context, WidgetRef ref, Profile profile) {
    final isAdmin = ref.read(permissionServiceProvider).can('users', 'update');

    final isDesktop = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;

    Widget buildContent(BuildContext ctx) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Статус блокировки
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(ctx)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Статус аккаунта',
                  style: Theme.of(ctx).textTheme.titleSmall,
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final profileState = ref.watch(profileProvider);
                    final currentProfile = profileState.profiles.firstWhere(
                      (p) => p.id == profile.id,
                      orElse: () => profile,
                    );

                    return ProfileStatusSwitch(
                      value: currentProfile.status == true,
                      canToggle: isAdmin,
                      isBusy: false,
                      onChanged: (value) {
                        ref.read(profileProvider.notifier).updateProfile(
                            currentProfile.copyWith(
                                status: value, updatedAt: DateTime.now()));
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Основная форма
          ProfileEditForm(
            profile: profile,
            allObjects: widget.allObjects,
            isAdmin: isAdmin,
            initialEmployeeId: profile.object?['employee_id'] as String?,
            initialRoleId: profile.roleId,
            onSave: (fullName, phone, selectedObjectIds, employeeId, roleId) {
              final updatedProfile = ProfileUtils.prepareProfileForUpdate(
                originalProfile: profile,
                fullName: fullName,
                phone: phone,
                selectedObjectIds: selectedObjectIds,
                employeeId: employeeId,
                roleId: roleId,
                isAdmin: isAdmin,
              );

              ref.read(profileProvider.notifier).updateProfile(updatedProfile);
            },
            onSuccess: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    }

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: DesktopDialogContent(
            title: 'Редактирование',
            child: buildContent(context),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        constraints: const BoxConstraints(maxWidth: 640),
        useSafeArea: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => MobileBottomSheetContent(
          title: 'Редактирование',
          child: buildContent(context),
        ),
      );
    }
  }
}

class _UserListTile extends ConsumerWidget {
  final Profile profile;
  final VoidCallback onEdit;
  final bool isBusy;

  const _UserListTile({
    required this.profile,
    required this.onEdit,
    required this.isBusy,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isActive = profile.status == true;
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final rolesState = ref.watch(rolesNotifierProvider);
    final roleName = rolesState.valueOrNull
            ?.where((r) => r.id == profile.roleId)
            .firstOrNull
            ?.name ??
        'ROLE';

    // Используем onSurfaceVariant для второстепенного текста
    final subtitleColor = colorScheme.onSurfaceVariant;
    // Используем стандартную прозрачность для отключенных элементов
    final disabledColor = colorScheme.onSurface.withValues(alpha: 0.38);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: colorScheme.primaryContainer,
                      backgroundImage: profile.photoUrl != null
                          ? NetworkImage(profile.photoUrl!)
                          : null,
                      child: profile.photoUrl == null
                          ? Icon(
                              CupertinoIcons.person_fill,
                              color: colorScheme.onPrimaryContainer,
                              size: 24,
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
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              profile.fullName?.isNotEmpty == true
                                  ? profile.fullName!
                                  : 'Без имени',
                              style: textTheme.titleMedium?.copyWith(
                                color: !isActive
                                    ? disabledColor
                                    : colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (profile.roleId != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorScheme.tertiaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                roleName,
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onTertiaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          profile.email,
                          if (profile.phone != null) profile.phone
                        ].join(' • '),
                        style: textTheme.bodySmall?.copyWith(
                          color: subtitleColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (profile.object?['employee_id'] != null) ...[
                        const SizedBox(height: 8),
                        ProfileLinkedEmployeeInfo(
                          employeeId: profile.object!['employee_id'],
                          compact: true,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 20,
                  color: colorScheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
