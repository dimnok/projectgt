import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:projectgt/core/utils/formatters.dart';
import '../../domain/entities/light_work.dart';

/// График ежедневной выработки в виде столбиков.
///
/// Отображает:
/// - Ось X: Число месяца
/// - Ось Y (Столбик): Сумма выработки за день
/// - При наведении/нажатии: Tooltip с точной суммой
class DailyWorkChart extends StatelessWidget {
  /// Список облегченных смен для построения графика.
  final List<LightWork> works;

  /// Месяц, за который отображается график.
  final DateTime month;

  /// Флаг отображения в десктопном режиме.
  final bool isDesktop;

  /// Создаёт виджет графика ежедневной выработки.
  const DailyWorkChart({
    super.key,
    required this.works,
    required this.month,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dailySums = _calculateDailySums();
    
    // Определяем активные дни (где была выработка)
    final activeDays = dailySums.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => a.value.compareTo(b.value)); // Сортировка по возрастанию суммы

    final maxAmount = activeDays.isEmpty ? 0.0 : activeDays.last.value;
    
    // Определяем день с максимальной выработкой
    final maxDay = activeDays.isEmpty ? -1 : activeDays.last.key;
    
    // Определяем 5 дней с самой низкой выработкой (исключая день с максимальной)
    final lowestDays = <int>{};
    for (var entry in activeDays) {
      if (lowestDays.length >= 5) break;
      if (entry.key != maxDay) {
        lowestDays.add(entry.key);
      }
    }

    // Дней в месяце
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Динамика выработки',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (maxAmount > 0)
                Text(
                  'Макс: ${formatCurrency(maxAmount)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final barWidth = (constraints.maxWidth / daysInMonth) - 4;
                // Ограничиваем ширину столбика
                final effectiveBarWidth = barWidth.clamp(4.0, 16.0);

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(daysInMonth, (index) {
                    final day = index + 1;
                    final amount = dailySums[day] ?? 0.0;
                    
                    // Используем квадратный корень для нормализации, чтобы маленькие значения были видны
                    final heightFactor = maxAmount > 0 ? math.sqrt(amount / maxAmount) : 0.0;
                    
                    // Логика цвета
                    Color barColor;
                    if (amount == 0) {
                      barColor = theme.colorScheme.surfaceContainerHighest;
                    } else if (day == maxDay) {
                      barColor = CupertinoColors.activeGreen;
                    } else if (lowestDays.contains(day)) {
                      barColor = CupertinoColors.destructiveRed;
                    } else {
                      barColor = CupertinoColors.activeBlue;
                    }
                    
                    final isToday = _isToday(day);
                    
                    return _ChartBar(
                      day: day,
                      amount: amount,
                      heightFactor: heightFactor,
                      width: effectiveBarWidth,
                      isToday: isToday,
                      maxHeight: constraints.maxHeight - 20, // Место под подпись
                      theme: theme,
                      color: barColor,
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Map<int, double> _calculateDailySums() {
    final map = <int, double>{};
    for (final work in works) {
      final day = work.date.day;
      map[day] = (map[day] ?? 0) + work.totalAmount;
    }
    return map;
  }
  
  bool _isToday(int day) {
    final now = DateTime.now();
    return now.year == month.year && now.month == month.month && now.day == day;
  }
}

class _ChartBar extends StatelessWidget {
  final int day;
  final double amount;
  final double heightFactor;
  final double width;
  final bool isToday;
  final double maxHeight;
  final ThemeData theme;
  final Color color;

  const _ChartBar({
    required this.day,
    required this.amount,
    required this.heightFactor,
    required this.width,
    required this.isToday,
    required this.maxHeight,
    required this.theme,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Если есть сумма > 0, то минимальная высота 12, иначе 4
    final minHeight = amount > 0 ? 12.0 : 4.0;
    final barHeight = (maxHeight * heightFactor).clamp(minHeight, maxHeight);

    return Tooltip(
      message: '$day ${_getMonthName()}\n${formatCurrency(amount)}',
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.inverseSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onInverseSurface,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: barHeight),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutQuart,
            builder: (context, value, child) {
              return Container(
                width: width,
                height: value,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(width / 2)),
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          if (width > 8 || day % 5 == 0 || isToday)
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: width > 16 ? 16 : width,
              height: width > 16 ? 16 : width,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: width > 12 ? 9 : 7,
                    color: amount == 0
                        ? theme.colorScheme.onSurfaceVariant
                        : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  String _getMonthName() {
    return '';
  }
}
