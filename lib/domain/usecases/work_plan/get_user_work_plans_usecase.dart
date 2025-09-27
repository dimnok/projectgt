import '../../entities/work_plan.dart';
import '../../repositories/work_plan_repository.dart';

/// UseCase для получения планов работ пользователя с дополнительной информацией.
class GetUserWorkPlansUseCase {
  /// Репозиторий планов работ.
  final WorkPlanRepository repository;

  /// Создаёт экземпляр [GetUserWorkPlansUseCase] с репозиторием [repository].
  GetUserWorkPlansUseCase(this.repository);

  /// Возвращает планы работ пользователя с дополнительной информацией об объектах.
  ///
  /// Использует оптимизированные запросы для получения связанных данных.
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
    return await repository.getUserWorkPlans(
      limit: limit,
      offset: offset,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
  }
}
