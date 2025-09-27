import '../../entities/work_plan.dart';
import '../../repositories/work_plan_repository.dart';

/// UseCase для получения списка планов работ с фильтрами.
class GetWorkPlansUseCase {
  /// Репозиторий планов работ.
  final WorkPlanRepository repository;

  /// Создаёт экземпляр [GetWorkPlansUseCase] с репозиторием [repository].
  GetWorkPlansUseCase(this.repository);

  /// Возвращает список планов работ с возможными фильтрами.
  ///
  /// [limit] — максимальное количество записей (по умолчанию 50).
  /// [offset] — смещение для пагинации (по умолчанию 0).
  /// [dateFrom] — фильтр по дате от.
  /// [dateTo] — фильтр по дате до.
  Future<List<WorkPlan>> call({
    int limit = 50,
    int offset = 0,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    return await repository.getWorkPlans(
      limit: limit,
      offset: offset,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
  }
}
