import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/work_plan.dart';
import '../../domain/usecases/work_plan/get_work_plans_usecase.dart';
import '../../domain/usecases/work_plan/get_work_plan_usecase.dart';
import '../../domain/usecases/work_plan/create_work_plan_usecase.dart';
import '../../domain/usecases/work_plan/update_work_plan_usecase.dart';
import '../../domain/usecases/work_plan/delete_work_plan_usecase.dart';
// Удалён импорт неиспользуемого use-case get_user_work_plans_usecase.dart

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

  /// UseCase для получения одного плана работ.
  final GetWorkPlanUseCase getWorkPlanUseCase;

  /// UseCase для создания плана работ.
  final CreateWorkPlanUseCase createWorkPlanUseCase;

  /// UseCase для обновления плана работ.
  final UpdateWorkPlanUseCase updateWorkPlanUseCase;

  /// UseCase для удаления плана работ.
  final DeleteWorkPlanUseCase deleteWorkPlanUseCase;

  // Удалён неиспользуемый use-case получения пользовательских планов работ

  /// Создаёт экземпляр [WorkPlanNotifier].
  WorkPlanNotifier({
    required this.getWorkPlansUseCase,
    required this.getWorkPlanUseCase,
    required this.createWorkPlanUseCase,
    required this.updateWorkPlanUseCase,
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

  /// Загружает детали конкретного плана работ.
  Future<void> loadWorkPlanDetails(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final workPlan = await getWorkPlanUseCase(id);
      state = state.copyWith(
        selectedWorkPlan: workPlan,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Создаёт новый план работ.
  Future<WorkPlan?> createWorkPlan(WorkPlan workPlan) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final createdWorkPlan = await createWorkPlanUseCase(workPlan);
      // Добавляем созданный план в список
      final updatedWorkPlans = [...state.workPlans, createdWorkPlan];
      state = state.copyWith(
        workPlans: updatedWorkPlans,
        isLoading: false,
      );
      return createdWorkPlan;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Обновляет существующий план работ.
  Future<WorkPlan?> updateWorkPlan(WorkPlan workPlan) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final updatedWorkPlan = await updateWorkPlanUseCase(workPlan);
      // Обновляем план в списке
      final updatedWorkPlans = state.workPlans.map((wp) {
        return wp.id == workPlan.id ? updatedWorkPlan : wp;
      }).toList();
      state = state.copyWith(
        workPlans: updatedWorkPlans,
        selectedWorkPlan: updatedWorkPlan,
        isLoading: false,
      );
      return updatedWorkPlan;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

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

  /// Очищает выбранный план работ.
  void clearSelectedWorkPlan() {
    state = state.copyWith(selectedWorkPlan: null);
  }

  /// Очищает ошибку.
  void clearError() {
    state = state.copyWith(error: null);
  }
}
