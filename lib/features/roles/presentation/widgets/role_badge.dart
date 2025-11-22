import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/features/roles/presentation/providers/roles_provider.dart';

/// Виджет для отображения названия роли пользователя.
/// Загружает название роли по ID, либо использует fallback (старое поле role).
class RoleBadge extends ConsumerWidget {
  final String? roleId;
  final String? fallbackRole;
  final TextStyle? style;
  final Color? color;

  const RoleBadge({
    super.key,
    this.roleId,
    this.fallbackRole,
    this.style,
    this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync =
        roleId != null ? ref.watch(roleByIdProvider(roleId!)) : null;

    return roleAsync?.when(
          data: (role) => _buildBadge(
              context, role?.name ?? _formatFallback(fallbackRole), true),
          loading: () => _buildBadge(context, '...', false),
          error: (_, __) =>
              _buildBadge(context, _formatFallback(fallbackRole), false),
        ) ??
        _buildBadge(context, _formatFallback(fallbackRole), false);
  }

  String _formatFallback(String? role) {
    return 'Без роли';
  }

  Widget _buildBadge(BuildContext context, String text, bool isNewRole) {
    final theme = Theme.of(context);

    // Цвета: админ (или новая роль) - фиолетовый/синий, юзер - серый
    // Если роль новая (загружена из БД), считаем её важной (фиолетовый).
    // Если fallback 'user' - синий.
    final Color badgeColor =
        color ?? ((text == 'ADMIN' || isNewRole) ? Colors.purple : Colors.blue);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: style ??
            theme.textTheme.bodySmall?.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
