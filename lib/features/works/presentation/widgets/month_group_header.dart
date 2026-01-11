import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:projectgt/features/works/data/models/month_group.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';

/// Виджет заголовка группы смен, сгруппированных по месяцу.
///
/// Минималистичный современный дизайн:
/// - Без тяжелых рамок и фонов
/// - Чёткая типографика
/// - Плавная анимация шеврона
class MonthGroupHeader extends StatelessWidget {
  /// Группа месяца для отображения.
  final MonthGroup group;

  /// Колбэк при нажатии на заголовок (раскрыть/свернуть).
  final VoidCallback onTap;

  /// Колбэк при долгом нажатии на заголовок (используется только на мобильных).
  final VoidCallback? onMobileLongPress;

  /// Степень "прилипания" заголовка (0.0 - в списке, 1.0 - прилип).
  final double stuckAmount;

  /// Создаёт виджет заголовка группы месяца.
  const MonthGroupHeader({
    super.key,
    required this.group,
    required this.onTap,
    this.onMobileLongPress,
    this.stuckAmount = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final isMobile = ResponsiveUtils.isMobile(context);

    final monthName = group.monthName;

    // Анимация текста
    // Увеличение размера: 1.0 -> 1.15
    final textScale = 1.0 + (stuckAmount * 0.15);

    // Цвет: от стандартного к синему
    final targetColor = Colors.blue.shade600;
    final titleColor = Color.lerp(
      theme.colorScheme.onSurface,
      targetColor,
      stuckAmount,
    );

    // Цвет подзаголовка тоже можно немного подкрасить или оставить серым
    final subtitleColor = Color.lerp(
      theme.colorScheme.onSurfaceVariant,
      targetColor.withValues(alpha: 0.7),
      stuckAmount * 0.5, // Менее интенсивно
    );

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isDesktop ? 4 : 16,
        vertical: 4,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: isMobile ? onMobileLongPress : null,
          borderRadius: BorderRadius.circular(12),
          hoverColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Row(
              children: [
                // Информация о месяце
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Месяц и год
                      Transform.scale(
                        scale: textScale,
                        alignment:
                            Alignment.centerLeft, // Увеличиваем от левого края
                        child: Text(
                          monthName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Статистика (мелким шрифтом)
                      Text(
                        '${group.worksCount} ${_pluralizeWorks(group.worksCount)} • ${formatCurrency(group.totalAmount)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Индикатор раскрытия
                AnimatedRotation(
                  turns: group.isExpanded
                      ? 0.25
                      : 0, // Поворот на 90 градусов (0.25 оборота) для шеврона вправо -> вниз
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: Icon(
                    // Используем Cupertino шеврон
                    // По умолчанию chevron_right смотрит вправо. При повороте будет смотреть вниз.
                    CupertinoIcons.chevron_right,
                    color: subtitleColor,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Возвращает правильную форму слова "смена" в зависимости от количества.
  String _pluralizeWorks(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'смена';
    } else if ([2, 3, 4].contains(count % 10) &&
        ![12, 13, 14].contains(count % 100)) {
      return 'смены';
    } else {
      return 'смен';
    }
  }
}
