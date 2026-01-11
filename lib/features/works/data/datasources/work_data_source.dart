import '../../domain/entities/work_summaries.dart';
import '../models/month_group.dart';
import '../models/light_work_model.dart';
import '../models/work_model.dart';

/// Интерфейс источника данных для работы со сменами.
abstract class WorkDataSource {
  /// Возвращает список всех смен.
  Future<List<WorkModel>> getWorks();

  /// Возвращает смену по идентификатору [id].
  Future<WorkModel?> getWork(String id);

  /// Добавляет новую смену [work] и возвращает созданную модель.
  Future<WorkModel> addWork(WorkModel work);

  /// Обновляет данные смены [work] и возвращает обновлённую модель.
  Future<WorkModel> updateWork(WorkModel work);

  /// Удаляет смену по идентификатору [id].
  Future<void> deleteWork(String id);

  /// Возвращает заголовки групп месяцев с агрегированными данными.
  Future<List<MonthGroup>> getMonthsHeaders();

  /// Возвращает смены конкретного месяца с пагинацией.
  Future<List<WorkModel>> getMonthWorks(
    DateTime month, {
    int offset = 0,
    int limit = 30,
  });

  /// Проверяет, есть ли у пользователя открытая смена в данной компании.
  Future<bool> hasOpenWork(String userId);

  /// Возвращает полные данные по выработке за месяц для графика.
  Future<List<LightWorkModel>> getMonthWorksForChart(DateTime month);

  /// Возвращает полную статистику по объектам за месяц.
  Future<List<ObjectSummary>> getObjectsSummary(DateTime month);

  /// Возвращает полную статистику по системам за месяц.
  Future<List<SystemSummary>> getSystemsSummary(DateTime month);

  /// Возвращает общее количество часов за месяц.
  Future<MonthHoursSummary> getTotalHours(DateTime month);

  /// Возвращает количество уникальных сотрудников за месяц.
  Future<MonthEmployeesSummary> getTotalEmployees(DateTime month);
}
