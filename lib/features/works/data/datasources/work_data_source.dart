import '../models/work_model.dart';
import '../models/month_group.dart';
import 'work_data_source_impl.dart';

/// Абстрактный источник данных для работы со сменами.
///
/// Определяет методы для получения, создания, обновления и удаления смен.
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

  /// Возвращает полную статистику по объектам за месяц.
  Future<List<ObjectSummary>> getObjectsSummary(DateTime month);

  /// Возвращает полную статистику по системам за месяц.
  Future<List<SystemSummary>> getSystemsSummary(DateTime month);

  /// Возвращает общее количество часов за месяц.
  Future<MonthHoursSummary> getTotalHours(DateTime month);

  /// Возвращает общее количество специалистов за месяц.
  Future<MonthEmployeesSummary> getTotalEmployees(DateTime month);
}
