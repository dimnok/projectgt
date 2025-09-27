import '../../entities/work_plan.dart';
import '../../repositories/work_plan_repository.dart';

/// UseCase для обновления плана работ.
class UpdateWorkPlanUseCase {
  /// Репозиторий планов работ.
  final WorkPlanRepository repository;

  /// Создаёт экземпляр [UpdateWorkPlanUseCase] с репозиторием [repository].
  UpdateWorkPlanUseCase(this.repository);

  /// Обновляет существующий план работ.
  ///
  /// [workPlan] — план работ с обновлёнными данными (ID обязателен).
  /// Возвращает обновлённый план работ.
  Future<WorkPlan> call(WorkPlan workPlan) async {
    return await repository.updateWorkPlan(workPlan);
  }
}
