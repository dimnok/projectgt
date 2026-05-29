import '../entities/timesheet_load_result.dart';

/// Интерфейс репозитория для работы с данными табеля рабочего времени.
abstract class TimesheetRepository {
  /// Загружает записи табеля и справочник сотрудников за период.
  ///
  /// [startDate] — начало периода, [endDate] — конец.
  /// [employeeId] — только для точечных запросов (диалог посещаемости).
  Future<TimesheetLoadResult> loadTimesheet({
    DateTime? startDate,
    DateTime? endDate,
    String? employeeId,
  });
}
