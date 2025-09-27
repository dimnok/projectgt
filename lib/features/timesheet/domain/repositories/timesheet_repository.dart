import '../entities/timesheet_entry.dart';
import '../entities/timesheet_summary.dart';

/// Интерфейс репозитория для работы с данными табеля рабочего времени.
abstract class TimesheetRepository {
  /// Получает записи табеля с возможностью фильтрации.
  ///
  /// [startDate] - начальная дата для фильтрации
  /// [endDate] - конечная дата для фильтрации
  /// [employeeId] - ID сотрудника для фильтрации
  /// [objectId] - ID объекта для фильтрации
  Future<List<TimesheetEntry>> getTimesheetEntries({
    DateTime? startDate,
    DateTime? endDate,
    String? employeeId,
    String? objectId,
  });

  /// Получает сводные данные по часам сотрудников.
  ///
  /// [startDate] - начальная дата для фильтрации
  /// [endDate] - конечная дата для фильтрации
  /// [employeeIds] - список ID сотрудников для фильтрации
  /// [objectIds] - список ID объектов для фильтрации
  Future<List<TimesheetSummary>> getTimesheetSummary({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? employeeIds,
    List<String>? objectIds,
  });
}
