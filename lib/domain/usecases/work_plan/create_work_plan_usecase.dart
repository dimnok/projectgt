import '../../entities/work_plan.dart';
import '../../repositories/work_plan_repository.dart';

/// UseCase для создания нового плана работ.
class CreateWorkPlanUseCase {
  /// Репозиторий планов работ.
  final WorkPlanRepository repository;

  /// Создаёт экземпляр [CreateWorkPlanUseCase] с репозиторием [repository].
  CreateWorkPlanUseCase(this.repository);

  /// Создаёт новый план работ.
  ///
  /// [workPlan] — данные плана работ для создания.
  /// Возвращает созданный план работ с присвоенным ID.
  Future<WorkPlan> call(WorkPlan workPlan) async {
    return await repository.createWorkPlan(workPlan);
  }
}
