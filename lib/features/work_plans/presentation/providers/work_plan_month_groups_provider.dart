import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/domain/entities/work_plan.dart';
import 'package:projectgt/presentation/state/work_plan_state.dart';
import 'package:projectgt/core/di/providers.dart';

/// Модель группы планов работ, сгруппированных по месяцу.
///
/// Используется для отображения планов с группировкой по месяцам.
class WorkPlanMonthGroup {
  /// Дата начала месяца (первое число).
  final DateTime month;

  /// Количество планов в этом месяце.
  final int plansCount;

  /// Общая запланированная стоимость всех планов в месяце.
  final double totalPlannedCost;

  /// Флаг, показывающий развёрнута ли группа.
  bool isExpanded;

  /// Список планов месяца.
  ///
  /// null - планы ещё не загружены (группа не раскрывалась).
  /// [] - планы загружены, но список пустой.
  /// [WorkPlan, ...] - загруженные планы.
  List<WorkPlan>? workPlans;

  /// Создаёт группу планов по месяцу.
  WorkPlanMonthGroup({
    required this.month,
    required this.plansCount,
    required this.totalPlannedCost,
    this.isExpanded = false,
    this.workPlans,
  });

  /// Создаёт копию группы с изменёнными полями.
  WorkPlanMonthGroup copyWith({
    DateTime? month,
    int? plansCount,
    double? totalPlannedCost,
    bool? isExpanded,
    List<WorkPlan>? workPlans,
  }) {
    return WorkPlanMonthGroup(
      month: month ?? this.month,
      plansCount: plansCount ?? this.plansCount,
      totalPlannedCost: totalPlannedCost ?? this.totalPlannedCost,
      isExpanded: isExpanded ?? this.isExpanded,
      workPlans: workPlans ?? this.workPlans,
    );
  }

  /// Возвращает название месяца в формате "Октябрь 2025".
  String get monthName {
    const months = [
      'Январь',
      'Февраль',
      'Март',
      'Апрель',
      'Май',
      'Июнь',
      'Июль',
      'Август',
      'Сентябрь',
      'Октябрь',
      'Ноябрь',
      'Декабрь'
    ];
    return '${months[month.month - 1]} ${month.year}';
  }

  /// Возвращает true, если это текущий месяц.
  bool get isCurrentMonth {
    final now = DateTime.now();
    return month.year == now.year && month.month == now.month;
  }

  @override
  String toString() {
    return 'WorkPlanMonthGroup(month: $month, plansCount: $plansCount, totalPlannedCost: $totalPlannedCost, isExpanded: $isExpanded, workPlans: ${workPlans?.length ?? 'null'})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkPlanMonthGroup && other.month == month;
  }

  @override
  int get hashCode => month.hashCode;
}

/// Состояние для управления группами месяцев планов работ.
class WorkPlanMonthGroupsState {
  /// Список групп месяцев планов.
  final List<WorkPlanMonthGroup> groups;

  /// Флаг загрузки.
  final bool isLoading;

  /// Сообщение об ошибке (если есть).
  final String? error;

  /// Создаёт состояние для групп месяцев планов.
  const WorkPlanMonthGroupsState({
    this.groups = const [],
    this.isLoading = false,
    this.error,
  });

  /// Создаёт копию состояния с изменёнными полями.
  WorkPlanMonthGroupsState copyWith({
    List<WorkPlanMonthGroup>? groups,
    bool? isLoading,
    String? error,
  }) {
    return WorkPlanMonthGroupsState(
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// StateNotifier для управления группами месяцев планов работ.
///
/// Управляет загрузкой групп месяцев, раскрытием/сворачиванием групп
/// и отображением планов при раскрытии группы.
class WorkPlanMonthGroupsNotifier
    extends StateNotifier<WorkPlanMonthGroupsState> {
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
      final groups = groupedByMonth.entries
          .map((entry) {
            final plans = entry.value;
            final totalCost =
                plans.fold(0.0, (sum, plan) => sum + plan.totalPlannedCost);

            return WorkPlanMonthGroup(
              month: entry.key,
              plansCount: plans.length,
              totalPlannedCost: totalCost,
              isExpanded: false,
              workPlans: null, // Загружаются при раскрытии
            );
          })
          .toList()
        ..sort((a, b) => b.month.compareTo(a.month)); // Сортируем по убыванию

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
    // Находим группу
    final groupIndex = state.groups.indexWhere((g) => g.month == month);
    if (groupIndex == -1) return;

    final group = state.groups[groupIndex];

    // Если уже развёрнута, ничего не делаем
    if (group.isExpanded) return;

    // Создаем обновленный список групп
    final updatedGroups = List<WorkPlanMonthGroup>.from(state.groups);

    // Сворачиваем все остальные группы
    for (int i = 0; i < updatedGroups.length; i++) {
      if (i != groupIndex && updatedGroups[i].isExpanded) {
        updatedGroups[i] = updatedGroups[i].copyWith(
          isExpanded: false,
          workPlans: null,
        );
      }
    }

    // Обновляем целевую группу: развёрнута и загружаем планы
    final workPlans = _workPlanNotifier.state.workPlans
        .where((plan) {
          final planMonth = DateTime(plan.date.year, plan.date.month, 1);
          return planMonth == month;
        })
        .toList();

    updatedGroups[groupIndex] =
        group.copyWith(isExpanded: true, workPlans: workPlans);
    state = state.copyWith(groups: updatedGroups);
  }

  /// Сворачивает группу месяца.
  ///
  /// [month] — дата начала месяца для сворачивания.
  void collapseMonth(DateTime month) {
    final groupIndex = state.groups.indexWhere((g) => g.month == month);
    if (groupIndex == -1) return;

    final group = state.groups[groupIndex];

    // Если уже свёрнута, ничего не делаем
    if (!group.isExpanded) return;

    // Обновляем состояние: группа свёрнута, планы очищены
    final updatedGroups = List<WorkPlanMonthGroup>.from(state.groups);
    updatedGroups[groupIndex] = group.copyWith(
      isExpanded: false,
      workPlans: null,
    );
    state = state.copyWith(groups: updatedGroups);
  }

  /// Переключает состояние группы (раскрыть/свернуть).
  ///
  /// [month] — дата начала месяца.
  Future<void> toggleMonth(DateTime month) async {
    final group = state.groups.firstWhere((g) => g.month == month);
    if (group.isExpanded) {
      collapseMonth(month);
    } else {
      await expandMonth(month);
    }
  }

  /// Проверяет, раскрыта ли группа месяца.
  bool isMonthExpanded(DateTime month) {
    for (final group in state.groups) {
      if (group.month == month) {
        return group.isExpanded;
      }
    }
    return false;
  }

  /// Обновляет список планов (вызывается при изменении планов).
  Future<void> refresh() async {
    await loadMonths();
  }
}

/// Провайдер для управления группами месяцев планов работ.
final workPlanMonthGroupsProvider = StateNotifierProvider<
    WorkPlanMonthGroupsNotifier,
    WorkPlanMonthGroupsState>((ref) {
  final workPlanNotifier = ref.watch(workPlanNotifierProvider.notifier);
  final notifier = WorkPlanMonthGroupsNotifier(workPlanNotifier);

  // Автоматически загружаем месяцы при создании провайдера
  notifier.loadMonths();

  return notifier;
});
