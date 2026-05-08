import 'package:flutter/material.dart';

import 'package:projectgt/features/works/data/models/month_group.dart';
import 'package:projectgt/features/works/presentation/widgets/month_group_header.dart';

/// Делегат прилипающего заголовка месяца в списке смен.
///
/// Используется и десктопным, и мобильным экраном модуля работ. Высота
/// заголовка анимируется: в развёрнутом состоянии — 100 pt, в свёрнутом/прилипшем
/// — 80 pt. Передаваемый [backgroundColor] позволяет согласовать «прилипание»
/// с фоном контейнера (белая карточка на десктопе, прозрачный фон на мобильном).
class WorkMonthGroupSliverHeader extends SliverPersistentHeaderDelegate {
  /// Создаёт делегат заголовка.
  WorkMonthGroupSliverHeader({
    required this.group,
    required this.onTap,
    this.onMobileLongPress,
    this.backgroundColor,
  });

  /// Группа месяца, которую описывает заголовок.
  final MonthGroup group;

  /// Обработчик тапа по заголовку (обычно — разворачивание/сворачивание месяца).
  final VoidCallback onTap;

  /// Обработчик длинного тапа на мобильном (открытие экрана статистики месяца).
  final VoidCallback? onMobileLongPress;

  /// Цвет заливки «прилипшего» фона.
  final Color? backgroundColor;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    final isExpanded = group.isExpanded;

    final rawStuckAmount =
        (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final stuckAmount = isExpanded ? rawStuckAmount : 0.0;
    final isStuck = stuckAmount > 0.1;

    return Container(
      color: backgroundColor ?? theme.colorScheme.surface,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: MonthGroupHeader(
              group: group,
              onTap: onTap,
              onMobileLongPress: onMobileLongPress,
              stuckAmount: stuckAmount,
            ),
          ),
          if (isStuck)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Divider(
                height: 1,
                thickness: 1,
                color: theme.colorScheme.outline.withValues(
                  alpha: 0.1 * stuckAmount,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 100.0;

  @override
  double get minExtent => 80.0;

  @override
  bool shouldRebuild(covariant WorkMonthGroupSliverHeader oldDelegate) {
    return oldDelegate.group != group ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
