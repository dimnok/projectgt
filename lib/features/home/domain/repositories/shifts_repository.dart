/// Абстрактный репозиторий для работы с данными календаря смен.
abstract class ShiftsRepository {
  /// Получает агрегированные данные смен за месяц.
  Future<List<Map<String, dynamic>>> getShiftsForMonth(DateTime month);

  /// Получает детали смен за конкретный день.
  Future<Map<String, dynamic>> getShiftsForDate(DateTime date);

  /// Получает сводку по сменам за конкретный день (объекты, ИТР, монтажники).
  Future<Map<String, dynamic>> getShiftsSummaryForDate(DateTime date);
}
