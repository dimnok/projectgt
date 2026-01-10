import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Компактный переключатель месяцев для десктопа.
///
/// Отображает месяц в формате "Янв-25" с кнопками перехода влево/вправо.
class GTMonthPicker extends StatelessWidget {
  /// Текущая выбранная дата.
  final DateTime selectedDate;

  /// Callback при нажатии на кнопку "Назад".
  final VoidCallback? onPrevious;

  /// Callback при нажатии на кнопку "Вперед".
  final VoidCallback? onNext;

  /// Callback при нажатии на текст (например, для открытия выбора месяца).
  final VoidCallback? onTap;

  /// Создаёт компактный переключатель месяцев.
  const GTMonthPicker({
    super.key,
    required this.selectedDate,
    this.onPrevious,
    this.onNext,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Форматируем месяц: "Янв-25"
    final monthStr = DateFormat('MMM-yy', 'ru')
        .format(selectedDate)
        .replaceAll('.', '') // Убираем точки, если есть
        .toLowerCase();

    return Container(
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
            onPressed: onPrevious,
            tooltip: 'Предыдущий месяц',
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                constraints: const BoxConstraints(minWidth: 80),
                alignment: Alignment.center,
                child: Text(
                  monthStr,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
          _ArrowButton(
            icon: Icons.chevron_right_rounded,
            onPressed: onNext,
            tooltip: 'Следующий месяц',
          ),
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;

  const _ArrowButton({
    required this.icon,
    this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
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
