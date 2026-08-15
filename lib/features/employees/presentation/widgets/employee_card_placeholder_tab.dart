import 'package:flutter/material.dart';

/// Заглушка вкладки карточки сотрудника до реализации содержимого.
class EmployeeCardPlaceholderTab extends StatelessWidget {
  /// Название раздела для подписи на заглушке.
  final String title;

  /// Иконка раздела.
  final IconData icon;

  /// Создаёт заглушку вкладки с [title] и [icon].
  const EmployeeCardPlaceholderTab({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 36,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Раздел в разработке',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
