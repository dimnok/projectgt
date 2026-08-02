import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/work_plan.dart';
import '../../domain/usecases/work_plan/get_work_plans_usecase.dart';
import '../../domain/usecases/work_plan/delete_work_plan_usecase.dart';

/// Состояние для управления списком и деталями планов работ.
class WorkPlanState {
  /// Список всех планов работ.
  final List<WorkPlan> workPlans;

  /// Текущий выбранный план работ (детали).
  final WorkPlan? selectedWorkPlan;

  /// Флаг загрузки данных.
  final bool isLoading;

  /// Сообщение об ошибке, если есть.
  final String? error;

  /// Создаёт экземпляр [WorkPlanState].
  WorkPlanState({
    this.workPlans = const [],
    this.selectedWorkPlan,
    this.isLoading = false,
    this.error,
  });

  /// Копирует состояние с возможностью переопределения отдельных полей.
  WorkPlanState copyWith({
    List<WorkPlan>? workPlans,
    WorkPlan? selectedWorkPlan,
    bool? isLoading,
    String? error,
  }) {
    return WorkPlanState(
      workPlans: workPlans ?? this.workPlans,
      selectedWorkPlan: selectedWorkPlan ?? this.selectedWorkPlan,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// StateNotifier для управления состоянием планов работ через usecase-слой.
class WorkPlanNotifier extends StateNotifier<WorkPlanState> {
  /// UseCase для получения всех планов работ.
  final GetWorkPlansUseCase getWorkPlansUseCase;

  /// UseCase для удаления плана работ.
  final DeleteWorkPlanUseCase deleteWorkPlanUseCase;

  /// Создаёт экземпляр [WorkPlanNotifier].
  WorkPlanNotifier({
    required this.getWorkPlansUseCase,
    required this.deleteWorkPlanUseCase,
  }) : super(WorkPlanState());

  /// Загружает список планов работ с возможными фильтрами.
  Future<void> loadWorkPlans({
    int limit = 50,
    int offset = 0,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final workPlans = await getWorkPlansUseCase(
        limit: limit,
        offset: offset,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
      state = state.copyWith(
        workPlans: workPlans,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Удалён метод loadUserWorkPlans как неиспользуемый

  /// Удаляет план работ.
  Future<bool> deleteWorkPlan(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await deleteWorkPlanUseCase(id);
      // Удаляем план из списка
      final updatedWorkPlans =
          state.workPlans.where((wp) => wp.id != id).toList();
      state = state.copyWith(
        workPlans: updatedWorkPlans,
        selectedWorkPlan:
            state.selectedWorkPlan?.id == id ? null : state.selectedWorkPlan,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }
}
