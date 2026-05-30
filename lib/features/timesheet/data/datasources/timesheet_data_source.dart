/// Интерфейс источника данных для табеля рабочего времени.
abstract class TimesheetDataSource {
  /// Записи табеля из закрытых смен (`work_hours` + `works`).
  ///
  /// [objectIds] — при непустом списке только смены на этих объектах.
  Future<List<Map<String, dynamic>>> getTimesheetEntries({
    DateTime? startDate,
    DateTime? endDate,
    String? employeeId,
    List<String>? objectIds,
  });

  /// Часы из закрытых смен для одного сотрудника (без join на `employees`).
  Future<List<Map<String, dynamic>>> getShiftWorkHoursForEmployee({
    required String employeeId,
    DateTime? startDate,
    DateTime? endDate,
  });
}
