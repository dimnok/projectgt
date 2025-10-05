/// Интерфейс источника данных для табеля рабочего времени.
abstract class TimesheetDataSource {
  /// Получает записи табеля.
  ///
  /// [startDate] - начальная дата для фильтрации
  /// [endDate] - конечная дата для фильтрации
  /// [employeeId] - ID сотрудника для фильтрации
  /// [objectIds] - список ID объектов для фильтрации (мультивыбор)
  /// [positions] - список должностей для фильтрации
  Future<List<Map<String, dynamic>>> getTimesheetEntries({
    DateTime? startDate,
    DateTime? endDate,
    String? employeeId,
    List<String>? objectIds,
    List<String>? positions,
  });
}
