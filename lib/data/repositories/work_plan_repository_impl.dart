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
  Future<WorkPlan?> getWorkPlan(String id) async {
    final model = await dataSource.getWorkPlan(id);
    return model?.toDomain();
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

  @override
  Future<List<WorkPlan>> getUserWorkPlans({
    int limit = 50,
    int offset = 0,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final models = await dataSource.getUserWorkPlans(
      limit: limit,
      offset: offset,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
    return models.map((model) => model.toDomain()).toList();
  }

  @override
  Future<WorkPlan?> getWorkPlanDetails(String id) async {
    final model = await dataSource.getWorkPlanDetails(id);
    return model?.toDomain();
  }

  @override
  Future<List<WorkPlan>> getWorkPlansByObject(String objectId) async {
    final models = await dataSource.getWorkPlans();

    // Фильтруем по objectId
    final filteredModels =
        models.where((model) => model.objectId == objectId).toList();
    return filteredModels.map((model) => model.toDomain()).toList();
  }

  @override
  Future<List<WorkPlan>> getWorkPlansBySystem(String system) async {
    final models = await dataSource.getWorkPlans();

    // Фильтруем по system в блоках
    final filteredModels = models
        .where(
            (model) => model.workBlocks.any((block) => block.system == system))
        .toList();
    return filteredModels.map((model) => model.toDomain()).toList();
  }

  @override
  Future<Map<String, int>> getWorkPlansStatistics() async {
    final models = await dataSource.getWorkPlans();

    final stats = <String, int>{
      'total': models.length,
    };

    return stats;
  }

  @override
  Future<bool> workPlanExists({
    required String objectId,
    required String system,
    required DateTime date,
    String? excludeId,
  }) async {
    final models = await dataSource.getWorkPlans(
      dateFrom: date,
      dateTo: date,
    );

    return models.any((model) =>
        model.objectId == objectId &&
        model.workBlocks.any((block) => block.system == system) &&
        (excludeId == null || model.id != excludeId));
  }
}
