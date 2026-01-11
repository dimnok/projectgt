import 'package:projectgt/domain/entities/work_plan.dart';
import 'package:projectgt/core/common/models/base_month_group.dart';

/// Модель группы планов работ, сгруппированных по месяцу.
///
/// Используется для отображения планов с группировкой по месяцам.
class WorkPlanMonthGroup extends BaseMonthGroup<WorkPlan> {
  /// Количество планов в этом месяце.
  int get plansCount => count;

  /// Общая запланированная стоимость всех планов в месяце.
  double get totalPlannedCost => total;

  /// Список планов месяца.
  List<WorkPlan>? get workPlans => items;
  set workPlans(List<WorkPlan>? value) => items = value;

  /// Создаёт группу планов по месяцу.
  WorkPlanMonthGroup({
    required super.month,
    required int plansCount,
    required double totalPlannedCost,
    super.isExpanded,
    List<WorkPlan>? workPlans,
  }) : super(count: plansCount, total: totalPlannedCost, items: workPlans);

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
