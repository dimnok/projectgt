import 'package:projectgt/domain/entities/work_plan.dart';

/// Абстракция репозитория для работы с планами работ.
abstract class WorkPlanRepository {
  /// Получить список планов работ с фильтрами.
  ///
  /// [limit] — максимальное количество записей (по умолчанию 50).
  /// [offset] — смещение для пагинации (по умолчанию 0).
  /// [dateFrom] — фильтр по дате от.
  /// [dateTo] — фильтр по дате до.
  /// Возвращает список [WorkPlan]. Бросает [Exception] при ошибке.
  Future<List<WorkPlan>> getWorkPlans({
    int limit = 50,
    int offset = 0,
    DateTime? dateFrom,
    DateTime? dateTo,
  });

  /// Создать новый план работ [workPlan].
  ///
  /// Возвращает созданный [WorkPlan]. Бросает [Exception] при ошибке.
  Future<WorkPlan> createWorkPlan(WorkPlan workPlan);

  /// Обновить план работ [workPlan].
  ///
  /// Возвращает обновлённый [WorkPlan]. Бросает [Exception] при ошибке.
  Future<WorkPlan> updateWorkPlan(WorkPlan workPlan);

  /// Удалить план работ по [id].
  ///
  /// Возвращает void. Бросает [Exception] при ошибке.
  Future<void> deleteWorkPlan(String id);
}
