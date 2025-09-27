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

  /// Получить план работ по [id].
  ///
  /// Возвращает [WorkPlan] или null, если не найден. Бросает [Exception] при ошибке.
  Future<WorkPlan?> getWorkPlan(String id);

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

  /// Получить планы работ с дополнительной информацией об объектах.
  ///
  /// Использует оптимизированные запросы для получения связанных данных.
  Future<List<WorkPlan>> getUserWorkPlans({
    int limit = 50,
    int offset = 0,
    DateTime? dateFrom,
    DateTime? dateTo,
  });

  /// Получить детальную информацию о плане работ по [id].
  ///
  /// Включает дополнительную информацию об объекте и авторе.
  Future<WorkPlan?> getWorkPlanDetails(String id);

  /// Получить планы работ по объекту.
  ///
  /// [objectId] — идентификатор объекта.
  /// Возвращает список [WorkPlan]. Бросает [Exception] при ошибке.
  Future<List<WorkPlan>> getWorkPlansByObject(String objectId);

  /// Получить планы работ по системе.
  ///
  /// [system] — название системы.
  /// Возвращает список [WorkPlan]. Бросает [Exception] при ошибке.
  Future<List<WorkPlan>> getWorkPlansBySystem(String system);

  /// Получить статистику планов работ.
  ///
  /// Возвращает Map с ключом: total.
  Future<Map<String, int>> getWorkPlansStatistics();

  /// Проверить, существует ли план работ на указанную дату для объекта и системы.
  ///
  /// [objectId] — идентификатор объекта.
  /// [system] — система работ.
  /// [date] — дата плана.
  /// [excludeId] — идентификатор плана для исключения из проверки (для обновления).
  /// Возвращает true, если план существует.
  Future<bool> workPlanExists({
    required String objectId,
    required String system,
    required DateTime date,
    String? excludeId,
  });
}
