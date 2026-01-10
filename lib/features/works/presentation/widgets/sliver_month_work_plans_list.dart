import 'package:flutter/material.dart';
import 'package:projectgt/domain/entities/work_plan.dart';
import 'package:projectgt/features/work_plans/presentation/providers/work_plan_month_groups_provider.dart';
import 'package:projectgt/core/utils/formatters.dart';

/// Виджет для отображения списка планов в развёрнутой группе месяца.
///
/// Показывает планы в виде карточек с информацией о дате, сумме, количестве блоков и специалистов.
class SliverMonthWorkPlansList extends StatelessWidget {
  /// Группа месяца с планами.
  final WorkPlanMonthGroup group;

  /// Коллбэк при выборе плана.
  final Function(WorkPlan)? onPlanSelected;

  /// Цвет для sticky header (опционально).
  final Color? stickyHeaderColor;

  /// Создаёт виджет списка планов.
  const SliverMonthWorkPlansList({
    super.key,
    required this.group,
    this.onPlanSelected,
    this.stickyHeaderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plans = group.workPlans ?? [];

    if (plans.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'Планы не найдены',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final plan = plans[index];
        return _buildPlanCard(context, theme, plan);
      }, childCount: plans.length),
    );
  }

  /// Строит карточку плана работ, аналогично карточке смены.
  Widget _buildPlanCard(BuildContext context, ThemeData theme, WorkPlan plan) {
    // Подсчитываем уникальных специалистов
    final Set<String> uniqueWorkers = {};
    for (final block in plan.workBlocks) {
      uniqueWorkers.addAll(block.workerIds);
    }
    final workersCount = uniqueWorkers.length;

    return Hero(
      tag: 'plan_card_${plan.id}',
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Синий индикатор статуса слева (для планов)
                Container(width: 4, color: Colors.blue),
                // Контент карточки
                Expanded(
                  child: InkWell(
                    onTap: () => onPlanSelected?.call(plan),
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Левая колонка: Дата и Количество специалистов
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  GtFormatters.formatRuDate(plan.date),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Специалистов: $workersCount',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Правая колонка: Объект и Сумма плана
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  plan.objectName ?? 'Без названия',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                    height: 1.2,
                                  ),
                                  textAlign: TextAlign.right,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  GtFormatters.formatCurrency(
                                    plan.totalPlannedCost,
                                  ),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.blue,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
