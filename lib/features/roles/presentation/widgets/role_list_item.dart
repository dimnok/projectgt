import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:projectgt/features/roles/domain/entities/role.dart' as domain;

/// Виджет карточки роли в списке ролей.
class RoleListItem extends StatelessWidget {
  /// Роль для отображения.
  final domain.Role role;

  /// Выбрана ли эта роль.
  final bool isSelected;

  /// Обработчик нажатия на роль.
  final VoidCallback onTap;

  /// Текущая тема приложения.
  final ThemeData theme;

  /// Темная тема или нет.
  final bool isDark;

  /// Конструктор виджета.
  const RoleListItem({
    super.key,
    required this.role,
    required this.isSelected,
    required this.onTap,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 4),
      child: Material(
        color: isSelected
            ? (isDark ? Colors.grey[800] : Colors.grey[200])
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  role.isSystem
                      ? CupertinoIcons.shield
                      : CupertinoIcons.person_2,
                  size: 20,
                  color: isSelected
                      ? Colors.blue
                      : (role.isSystem ? Colors.orange : theme.iconTheme.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            role.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected ? Colors.blue : null,
                            ),
                          ),
                          if (role.isSystem) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Системная',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '0 пользователей', // TODO: Реализовать подсчет пользователей
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? Colors.blue.withValues(alpha: 0.8)
                              : theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.6),
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
    );
  }
}
