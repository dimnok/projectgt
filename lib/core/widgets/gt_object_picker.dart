import 'package:flutter/material.dart';

/// Компактный переключатель объектов для десктопа.
///
/// Отображает название текущего объекта с кнопками переключения влево/вправо.
class GTObjectPicker extends StatelessWidget {
  /// Название текущего выбранного объекта.
  final String objectName;

  /// Callback при нажатии на кнопку "Назад".
  final VoidCallback? onPrevious;

  /// Callback при нажатии на кнопку "Вперед".
  final VoidCallback? onNext;

  /// Callback при нажатии на текст (например, для открытия полного списка).
  final VoidCallback? onTap;

  /// Флаг активности переключателя.
  final bool enabled;

  /// Создаёт компактный переключатель объектов.
  const GTObjectPicker({
    super.key,
    required this.objectName,
    this.onPrevious,
    this.onNext,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Container(
          height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ArrowButton(
            icon: Icons.chevron_left_rounded,
            onTap: onPrevious,
            tooltip: 'Предыдущий объект',
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                constraints: const BoxConstraints(minWidth: 120, maxWidth: 200),
                alignment: Alignment.center,
                child: Text(
                  objectName,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          _ArrowButton(
            icon: Icons.chevron_right_rounded,
            onTap: onNext,
            tooltip: 'Следующий объект',
          ),
        ],
      ),
    ),
    ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;

  const _ArrowButton({
    required this.icon,
    this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

