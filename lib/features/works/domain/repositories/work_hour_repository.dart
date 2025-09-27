import '../entities/work_hour.dart';

/// Абстрактный репозиторий для работы с часами сотрудников в смене.
///
/// Определяет методы для получения, добавления, обновления и удаления записей о часах для конкретной смены.
abstract class WorkHourRepository {
  /// Возвращает список записей о часах для смены по идентификатору [workId].
  Future<List<WorkHour>> fetchWorkHours(String workId);

  /// Добавляет новую запись о часах [hour] в смену.
  Future<void> addWorkHour(WorkHour hour);

  /// Обновляет запись о часах [hour] в смене.
  Future<void> updateWorkHour(WorkHour hour);

  /// Удаляет запись о часах по идентификатору [id].
  Future<void> deleteWorkHour(String id);

  /// Получить все work_hours по сотруднику и периоду (месяцу)
  Future<List<WorkHour>> fetchWorkHoursByEmployeeAndPeriod(
      String employeeId, DateTime monthStart, DateTime monthEnd);

  /// Массовое обновление часов одним действием
  Future<void> updateWorkHoursBulk(List<WorkHour> hours);
}
