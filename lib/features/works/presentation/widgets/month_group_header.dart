import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projectgt/features/works/data/models/month_group.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';

/// Виджет заголовка группы смен, сгруппированных по месяцу.
///
/// Минималистичный строгий дизайн:
/// - Чёткая типографическая иерархия
/// - Монохромная цветовая схема
/// - Отсутствие градиентов и теней
/// - Акцент на функциональности и читаемости
class MonthGroupHeader extends StatelessWidget {
  /// Группа месяца для отображения.
  final MonthGroup group;

  /// Колбэк при нажатии на заголовок (раскрыть/свернуть).
  final VoidCallback onTap;

  /// Создаёт виджет заголовка группы месяца.
  const MonthGroupHeader({
    super.key,
    required this.group,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final formatter = NumberFormat('#,##0', 'ru_RU');
    final isCurrentMonth = group.isCurrentMonth;

    // Формируем название месяца с точкой-разделителем
    const months = [
      'ЯНВАРЬ',
      'ФЕВРАЛЬ',
      'МАРТ',
      'АПРЕЛЬ',
      'МАЙ',
      'ИЮНЬ',
      'ИЮЛЬ',
      'АВГУСТ',
      'СЕНТЯБРЬ',
      'ОКТЯБРЬ',
      'НОЯБРЬ',
      'ДЕКАБРЬ'
    ];
    final monthName = '${months[group.month.month - 1]} • ${group.month.year}';

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isDesktop ? 0 : 16,
        vertical: isDesktop ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(
          color: isCurrentMonth
              ? theme.colorScheme.onSurface
              : theme.colorScheme.outlineVariant,
          width: isCurrentMonth ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 20 : 16,
              vertical: isDesktop ? 16 : 14,
            ),
            child: Row(
              children: [
                // Минималистичная иконка календаря
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: theme.colorScheme.onSurface,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: theme.colorScheme.onSurface,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),

                // Информация о месяце
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Название месяца
                      Text(
                        monthName,
                        style: (isDesktop
                                ? theme.textTheme.titleMedium
                                : theme.textTheme.titleSmall)
                            ?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Статистика (текст без декора)
                      Text(
                        '${group.worksCount} ${_pluralizeWorks(group.worksCount)} • ${formatter.format(group.totalAmount)} ₽',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // Индикатор раскрытия
                AnimatedRotation(
                  turns: group.isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more,
                    color: theme.colorScheme.onSurface,
                    size: 24,
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
