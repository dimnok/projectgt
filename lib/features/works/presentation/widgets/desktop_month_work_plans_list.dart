import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/domain/entities/work_plan.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/features/objects/presentation/state/object_state.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/work_plans/data/models/work_plan_month_group.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';

/// Sliver-версия списка планов работ для десктопа (master-detail).
///
/// Обеспечивает компактное отображение планов с подсветкой выбранного элемента.
class DesktopMonthWorkPlansList extends ConsumerWidget {
  /// Группа месяца с планами.
  final WorkPlanMonthGroup group;

  /// Коллбэк при выборе плана.
  final Function(WorkPlan) onPlanSelected;

  /// Выбранный план (для подсветки).
  final WorkPlan? selectedPlan;

  /// Цвет для sticky header (опционально).
  final Color? stickyHeaderColor;

  /// Создаёт виджет списка планов для десктопа.
  const DesktopMonthWorkPlansList({
    super.key,
    required this.group,
    required this.onPlanSelected,
    this.selectedPlan,
    this.stickyHeaderColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final plans = group.workPlans ?? [];

    if (plans.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Планы не найдены',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
        ),
      );
    }

    final objectsState = ref.watch(objectProvider);

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final plan = plans[index];
        return _buildPlanCard(context, ref, theme, plan, objectsState);
      }, childCount: plans.length),
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    WorkPlan plan,
    ObjectState objectsState,
  ) {
    final selected = plan.id == selectedPlan?.id;

    // Получаем название объекта
    String objectName = plan.objectName ?? 'Без названия';
    if ((plan.objectName?.isEmpty ?? true) && objectsState.objects.isNotEmpty) {
      try {
        final obj = objectsState.objects.firstWhere(
          (o) => o.id == plan.objectId,
        );
        if (obj.name.isNotEmpty) {
          objectName = obj.name;
        }
      } catch (_) {}
    }

    // Подсчитываем количество специалистов
    final specialistCount =
        plan.workBlocks.expand((block) => block.workerIds).toSet().length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      elevation: 0,
      color: selected
          ? theme.colorScheme.primary.withValues(alpha: 0.1)
          : theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveUtils.borderRadiusMedium),
      ),
      child: InkWell(
        onTap: () => onPlanSelected(plan),
        borderRadius: BorderRadius.circular(ResponsiveUtils.borderRadiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Синий индикатор статуса слева
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),

              // Инфо
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatRuDate(plan.date),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: selected ? Colors.blue : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            objectName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: selected ? Colors.blue : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                CupertinoIcons.group,
                                size: 12,
                                color: selected
                                    ? Colors.blue
                                    : theme.colorScheme.onSurface.withValues(
                                        alpha: 0.5,
                                      ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$specialistCount ${_pluralizeSpecialists(specialistCount)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: selected
                                      ? Colors.blue
                                      : theme.colorScheme.onSurface.withValues(
                                          alpha: 0.5,
                                        ),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formatCurrency(plan.totalPlannedCost),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.blue : Colors.blue,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Возвращает правильную форму слова "специалист" в зависимости от количества.
  String _pluralizeSpecialists(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'специалист';
    } else if ([2, 3, 4].contains(count % 10) &&
        ![12, 13, 14].contains(count % 100)) {
      return 'специалиста';
    } else {
      return 'специалистов';
    }
  }
}
