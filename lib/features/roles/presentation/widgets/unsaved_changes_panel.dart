import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:projectgt/features/roles/presentation/models/permission_ui_model.dart';
import 'package:projectgt/features/roles/domain/entities/role.dart' as domain;
import 'package:projectgt/features/roles/domain/entities/module.dart' as domain;

/// Панель со списком несохраненных изменений.
class UnsavedChangesPanel extends StatelessWidget {
  /// Выбранная роль.
  final domain.Role role;

  /// Список модулей.
  final List<domain.Module> modules;

  /// Текущая тема.
  final ThemeData theme;

  /// Темная тема или нет.
  final bool isDark;

  /// Текущие права роли (оригинальные).
  final Map<String, Map<String, bool>> rolePermissions;

  /// Временные изменения прав.
  final Map<String, Map<String, bool>> tempPermissions;

  /// Коллбэк отмены одного изменения.
  final Function(String moduleId, String permissionId) onRevertChange;

  /// Коллбэк отмены всех изменений.
  final VoidCallback onRevertAll;

  /// Конструктор виджета.
  const UnsavedChangesPanel({
    super.key,
    required this.role,
    required this.modules,
    required this.theme,
    required this.isDark,
    required this.rolePermissions,
    required this.tempPermissions,
    required this.onRevertChange,
    required this.onRevertAll,
  });

  @override
  Widget build(BuildContext context) {
    final changes = <Widget>[];

    // Собираем все изменения
    tempPermissions.forEach((moduleCode, permissions) {
      final module = modules.firstWhere((m) => m.code == moduleCode,
          orElse: () => domain.Module(
                id: '',
                code: moduleCode,
                name: 'Неизвестный модуль',
                iconKey: 'cube_box',
              ));
      final originalPermissions = rolePermissions[moduleCode] ?? {};

      permissions.forEach((permId, newValue) {
        final perm = permissionsList.firstWhere(
          (p) => p.id == permId,
          orElse: () => PermissionUiModel(
            id: permId,
            name: 'Неизвестно ($permId)',
            code: permId,
            icon: CupertinoIcons.question_circle,
          ),
        );
        final oldValue = originalPermissions[permId] ?? false;

        if (oldValue != newValue) {
          changes.insert(
            0,
            TweenAnimationBuilder<double>(
              key: ValueKey('change-$moduleCode-$permId'),
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, (1 - value) * -10),
                  child: Opacity(
                    opacity: value,
                    child: Material(
                      color: Colors.transparent,
                      child: Tooltip(
                        message: 'Нажмите, чтобы отменить изменение',
                        child: InkWell(
                          onTap: () => onRevertChange(moduleCode, permId),
                          borderRadius: BorderRadius.circular(8),
                          hoverColor: theme.hoverColor.withValues(alpha: 0.1),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  newValue
                                      ? CupertinoIcons.plus_circle_fill
                                      : CupertinoIcons.minus_circle_fill,
                                  size: 16,
                                  color: newValue
                                      ? CupertinoColors.systemGreen
                                      : CupertinoColors.systemRed,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        module.name,
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${perm.name}: ${newValue ? "включено" : "выключено"}',
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: newValue
                                              ? CupertinoColors.systemGreen
                                              : CupertinoColors.systemRed,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
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
              },
            ),
          );
        }
      });
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Изменения',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyMedium?.color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            TweenAnimationBuilder<double>(
              key: ValueKey('count-${changes.length}'),
              tween: Tween(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${changes.length}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: CupertinoColors.systemBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Отменить все изменения',
              child: InkWell(
                onTap: onRevertAll,
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    CupertinoIcons.xmark_circle_fill,
                    size: 20,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: changes.isEmpty
                  ? [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'Нет изменений',
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ),
                      ),
                    ]
                  : changes,
            ),
          ),
        ),
      ],
    );
  }
}
