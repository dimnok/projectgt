import '../models/work_hour_model.dart';

/// Абстрактный источник данных для работы с часами сотрудников в смене.
///
/// Определяет методы для получения, добавления, обновления и удаления записей о часах для конкретной смены.
abstract class WorkHourDataSource {
  /// Возвращает список записей о часах для смены по идентификатору [workId].
  Future<List<WorkHourModel>> fetchWorkHours(String workId);

  /// Добавляет новую запись о часах [hour] в смену.
  Future<void> addWorkHour(WorkHourModel hour);

  /// Обновляет запись о часах [hour] в смене.
  Future<void> updateWorkHour(WorkHourModel hour);

  /// Удаляет запись о часах по идентификатору [id].
  Future<void> deleteWorkHour(String id);

  /// Получить все work_hours по сотруднику и периоду (месяцу)
  Future<List<WorkHourModel>> fetchWorkHoursByEmployeeAndPeriod(
      String employeeId, DateTime monthStart, DateTime monthEnd);

  /// Выполняет массовое обновление часов за один запрос.
  ///
  /// Использует upsert по первичному ключу `id`.
  Future<void> updateWorkHoursBulk(List<WorkHourModel> hours);
}
