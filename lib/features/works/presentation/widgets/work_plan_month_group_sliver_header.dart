import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import 'package:projectgt/features/work_plans/data/models/work_plan_month_group.dart';

/// Делегат прилипающего заголовка месяца в списке планов работ.
///
/// Переиспользуется и на десктопе, и на мобильном. В отличие от заголовка смен,
/// при «прилипании» подсвечивается синим цветом, характерным для модуля планов.
class WorkPlanMonthGroupSliverHeader extends SliverPersistentHeaderDelegate {
  /// Создаёт делегат заголовка планов.
  WorkPlanMonthGroupSliverHeader({
    required this.group,
    required this.onTap,
    this.backgroundColor,
  });

  /// Группа месяца, которую описывает заголовок.
  final WorkPlanMonthGroup group;

  /// Обработчик тапа по заголовку.
  final VoidCallback onTap;

  /// Цвет заливки «прилипшего» фона.
  final Color? backgroundColor;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    final isDesktop = ResponsiveUtils.isDesktop(context);

    final rawStuckAmount =
        (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final stuckAmount = group.isExpanded ? rawStuckAmount : 0.0;

    final textScale = 1.0 + (stuckAmount * 0.15);
    final targetColor = Colors.blue.shade600;
    final titleColor = Color.lerp(
      theme.colorScheme.onSurface,
      targetColor,
      stuckAmount,
    );
    final subtitleColor = Color.lerp(
      theme.colorScheme.onSurfaceVariant,
      targetColor.withValues(alpha: 0.7),
      stuckAmount * 0.5,
    );
    final isStuck = stuckAmount > 0.1;

    return Container(
      color: backgroundColor ?? theme.colorScheme.surface,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: isDesktop ? 4 : 16,
                vertical: 4,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(12),
                  hoverColor:
                      theme.colorScheme.onSurface.withValues(alpha: 0.05),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Transform.scale(
                                scale: textScale,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  group.monthName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: titleColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${group.plansCount} ${_pluralizePlans(group.plansCount)} • ${GtFormatters.formatCurrency(group.totalPlannedCost)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: subtitleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedRotation(
                          turns: group.isExpanded ? 0.25 : 0,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          child: Icon(
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

  /// Возвращает правильную форму слова «план» в зависимости от количества.
  String _pluralizePlans(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'план';
    } else if ([2, 3, 4].contains(count % 10) &&
        ![12, 13, 14].contains(count % 100)) {
      return 'плана';
    } else {
      return 'планов';
    }
  }

  @override
  double get maxExtent => 100.0;

  @override
  double get minExtent => 80.0;

  @override
  bool shouldRebuild(covariant WorkPlanMonthGroupSliverHeader oldDelegate) {
    return oldDelegate.group != group ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
