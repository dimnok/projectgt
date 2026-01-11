import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/domain/entities/work_plan.dart';
import 'package:projectgt/presentation/state/work_plan_state.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/features/work_plans/data/models/work_plan_month_group.dart';
import 'package:projectgt/core/common/month_group_controller.dart';

/// StateNotifier для управления группами месяцев планов работ.
///
/// Управляет загрузкой групп месяцев, раскрытием/сворачиванием групп
/// и отображением планов при раскрытии группы.
class WorkPlanMonthGroupsNotifier
    extends StateNotifier<WorkPlanMonthGroupsState>
    with MonthGroupController<WorkPlanMonthGroup> {
  /// StateNotifier для работы с планами работ.
  final WorkPlanNotifier _workPlanNotifier;

  /// Создаёт notifier для групп месяцев планов.
  WorkPlanMonthGroupsNotifier(this._workPlanNotifier)
    : super(const WorkPlanMonthGroupsState());

  /// Загружает и группирует планы по месяцам.
  ///
  /// Группирует уже загруженные планы из [_workPlanNotifier].
  Future<void> loadMonths() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Получаем планы из notifier (они уже загружены через workPlanNotifierProvider)
      final workPlans = _workPlanNotifier.state.workPlans;

      // Группируем планы по месяцам
      final Map<DateTime, List<WorkPlan>> groupedByMonth = {};

      for (final plan in workPlans) {
        // Берём первое число месяца плана
        final monthKey = DateTime(plan.date.year, plan.date.month, 1);
        groupedByMonth.putIfAbsent(monthKey, () => []).add(plan);
      }

      // Создаём MonthGroup объекты
      final groups =
          groupedByMonth.entries.map((entry) {
            final plans = entry.value;
            final totalCost = plans.fold(
              0.0,
              (sum, plan) => sum + plan.totalPlannedCost,
            );

            return WorkPlanMonthGroup(
              month: entry.key,
              plansCount: plans.length,
              totalPlannedCost: totalCost,
              isExpanded: false,
              workPlans: null, // Загружаются при раскрытии
            );
          }).toList()..sort(
            (a, b) => b.month.compareTo(a.month),
          ); // Сортируем по убыванию

      state = state.copyWith(groups: groups, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Ошибка загрузки групп планов: $e',
      );
    }
  }

  /// Раскрывает группу месяца.
  ///
  /// [month] — дата начала месяца для раскрытия.
  Future<void> expandMonth(DateTime month) async {
    final updatedGroups = expandInList(
      state.groups,
      month,
      copyWith: (group, isExpanded) {
        if (!isExpanded) {
          return group.copyWith(isExpanded: false, workPlans: null);
        }

        // Если раскрываем, находим соответствующие планы
        final workPlans = _workPlanNotifier.state.workPlans.where((plan) {
          final planMonth = DateTime(plan.date.year, plan.date.month, 1);
          return planMonth == month;
        }).toList();

        return group.copyWith(isExpanded: true, workPlans: workPlans);
      },
    );

    if (updatedGroups == state.groups) return;
    state = state.copyWith(groups: updatedGroups);
  }

  /// Сворачивает группу месяца.
  ///
  /// [month] — дата начала месяца для сворачивания.
  void collapseMonth(DateTime month) {
    final updatedGroups = collapseInList(
      state.groups,
      month,
      copyWith: (group, isExpanded) =>
          group.copyWith(isExpanded: false, workPlans: null),
    );

    if (updatedGroups == state.groups) return;
    state = state.copyWith(groups: updatedGroups);
  }

  /// Переключает состояние группы (раскрыть/свернуть).
  ///
  /// [month] — дата начала месяца.
  Future<void> toggleMonth(DateTime month) async {
    if (isMonthExpanded(month)) {
      collapseMonth(month);
    } else {
      await expandMonth(month);
    }
  }

  /// Проверяет, раскрыта ли группа месяца.
  bool isMonthExpanded(DateTime month) {
    return isExpanded(state.groups, month);
  }

  /// Обновляет список планов (вызывается при изменении планов).
  Future<void> refresh() async {
    await loadMonths();
  }
}

/// Провайдер для управления группами месяцев планов работ.
final workPlanMonthGroupsProvider =
    StateNotifierProvider<
      WorkPlanMonthGroupsNotifier,
      WorkPlanMonthGroupsState
    >((ref) {
      final workPlanNotifier = ref.watch(workPlanNotifierProvider.notifier);
      final notifier = WorkPlanMonthGroupsNotifier(workPlanNotifier);

      // Автоматически загружаем месяцы при создании провайдера
      notifier.loadMonths();

      return notifier;
    });
