import 'package:flutter/material.dart';

/// Виджет заголовка раздела в стиле проекта.
///
/// Используется для единообразного отображения заголовков таблиц и блоков.
class GTSectionTitle extends StatelessWidget {
  /// Текст заголовка.
  final String title;

  /// Создаёт заголовок раздела.
  const GTSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title.toUpperCase(),
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }
}
