import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:projectgt/features/work_plans/presentation/providers/work_plan_month_groups_provider.dart';
import 'package:projectgt/features/works/presentation/widgets/sliver_month_work_plans_list.dart';
import 'package:projectgt/features/works/presentation/widgets/work_plan_month_group_sliver_header.dart';

/// Мобильный список планов работ в модуле «Работы» (сгруппирован по месяцам).
///
/// Создание плана — круглая кнопка в хедере родительского [WorksListMobileScreen]
/// (как «Открыть смену» в режиме смен).
///
/// Используется внутри [WorksListMobileScreen] при переключении на режим «Планы».
class WorksListMobilePlansView extends ConsumerWidget {
  /// Создаёт виджет списка планов.
  const WorksListMobilePlansView({
    super.key,
    required this.onRefresh,
  });

  /// Pull-to-refresh: перезагрузка групп месяцев планов.
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workPlanMonthGroupsState = ref.watch(workPlanMonthGroupsProvider);
    final groups = workPlanMonthGroupsState.groups;
    final isLoading =
        workPlanMonthGroupsState.isLoading && groups.isEmpty;

    if (isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        slivers: [
          if (groups.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('Планы не найдены')),
            )
          else
            for (final group in groups) ...[
              SliverPersistentHeader(
                key: ValueKey('plan_header_${group.month}'),
                pinned: group.isExpanded,
                delegate: WorkPlanMonthGroupSliverHeader(
                  group: group,
                  backgroundColor: Colors.transparent,
                  onTap: () => ref
                      .read(workPlanMonthGroupsProvider.notifier)
                      .toggleMonth(group.month),
                ),
              ),
              if (group.isExpanded)
                SliverMonthWorkPlansList(
                  key: ValueKey('plan_list_${group.month}'),
                  group: group,
                )
              else
                const SliverToBoxAdapter(child: SizedBox.shrink()),
            ],
        ],
      ),
    );
  }
}

/// Чип возврата к списку смен с экрана планов (тот же стиль, что у фильтров смен).
class WorksListMobilePlansChipsBar extends StatelessWidget {
  /// Создаёт полосу с действием «Смены».
  const WorksListMobilePlansChipsBar({
    super.key,
    required this.scheme,
    required this.onShiftsTap,
  });

  /// Цветовая схема темы для текста чипа.
  final ColorScheme scheme;

  /// Переключение обратно на список смен.
  final VoidCallback onShiftsTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
        child: Row(
          children: [
            _PlansNavTextChip(
              scheme: scheme,
              label: 'Смены',
              selected: true,
              onTap: () async {
                onShiftsTap();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PlansNavTextChip extends StatelessWidget {
  const _PlansNavTextChip({
    required this.scheme,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final ColorScheme scheme;
  final String label;
  final bool selected;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;

    return InkWell(
      onTap: () async {
        await onTap();
      },
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            letterSpacing: 0.1,
            height: 1.35,
            decoration: selected
                ? TextDecoration.underline
                : TextDecoration.none,
            decorationColor: scheme.primary,
            decorationThickness: 2,
            decorationStyle: TextDecorationStyle.solid,
          ),
        ),
      ),
    );
  }
}
