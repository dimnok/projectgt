import '../entities/timesheet_entry.dart';

/// Интерфейс репозитория для работы с данными табеля рабочего времени.
abstract class TimesheetRepository {
  /// Получает записи табеля с возможностью фильтрации.
  ///
  /// [startDate] - начальная дата для фильтрации
  /// [endDate] - конечная дата для фильтрации
  /// [employeeId] - ID сотрудника для фильтрации
  /// [objectIds] - список ID объектов для фильтрации (мультивыбор)
  /// [positions] - список должностей для фильтрации
  Future<List<TimesheetEntry>> getTimesheetEntries({
    DateTime? startDate,
    DateTime? endDate,
    String? employeeId,
    List<String>? objectIds,
    List<String>? positions,
  });
}
