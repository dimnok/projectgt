import 'package:projectgt/data/datasources/work_plan_data_source.dart';
import 'package:projectgt/data/models/work_plan_model.dart';
import 'package:projectgt/domain/entities/work_plan.dart';
import 'package:projectgt/domain/repositories/work_plan_repository.dart';

/// Имплементация [WorkPlanRepository] для работы с планами работ через data source.
///
/// Инкапсулирует преобразование моделей и делегирует вызовы data-слою.
class WorkPlanRepositoryImpl implements WorkPlanRepository {
  /// Data source для работы с планами работ.
  final WorkPlanDataSource dataSource;

  /// Создаёт [WorkPlanRepositoryImpl] с указанным [dataSource].
  WorkPlanRepositoryImpl(this.dataSource);

  @override
  Future<List<WorkPlan>> getWorkPlans({
    int limit = 50,
    int offset = 0,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final models = await dataSource.getWorkPlans(
      limit: limit,
      offset: offset,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
    return models.map((model) => model.toDomain()).toList();
  }

  @override
  Future<WorkPlan> createWorkPlan(WorkPlan workPlan) async {
    final model =
        await dataSource.createWorkPlan(WorkPlanModel.fromDomain(workPlan));
    return model.toDomain();
  }

  @override
  Future<WorkPlan> updateWorkPlan(WorkPlan workPlan) async {
    final model =
        await dataSource.updateWorkPlan(WorkPlanModel.fromDomain(workPlan));
    return model.toDomain();
  }

  @override
  Future<void> deleteWorkPlan(String id) async {
    await dataSource.deleteWorkPlan(id);
  }
}
