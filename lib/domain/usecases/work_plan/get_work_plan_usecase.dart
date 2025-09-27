import '../../entities/work_plan.dart';
import '../../repositories/work_plan_repository.dart';

/// UseCase для получения плана работ по ID.
class GetWorkPlanUseCase {
  /// Репозиторий планов работ.
  final WorkPlanRepository repository;

  /// Создаёт экземпляр [GetWorkPlanUseCase] с репозиторием [repository].
  GetWorkPlanUseCase(this.repository);

  /// Возвращает план работ по его ID.
  ///
  /// [id] — уникальный идентификатор плана работ.
  /// Возвращает план работ или null, если не найден.
  Future<WorkPlan?> call(String id) async {
    return await repository.getWorkPlan(id);
  }
}
