import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Индикатор загрузки данных табеля: Cupertino-спиннер и короткая подпись.
class TimesheetHoursLoadingIndicator extends StatelessWidget {
  /// Создаёт индикатор с [message] под спиннером.
  const TimesheetHoursLoadingIndicator({
    super.key,
    this.message = 'Загрузка часов...',
  });

  /// Текст под индикатором.
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CupertinoActivityIndicator(),
          const SizedBox(height: 12),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}
