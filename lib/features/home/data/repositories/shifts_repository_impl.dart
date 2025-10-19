import '../../domain/repositories/shifts_repository.dart';
import '../datasources/shifts_data_source.dart';

/// Реализация репозитория для календаря смен.
class ShiftsRepositoryImpl implements ShiftsRepository {
  /// Источник данных для получения информации о сменах.
  final ShiftsDataSource dataSource;

  /// Создаёт реализацию репозитория календаря смен.
  ShiftsRepositoryImpl({required this.dataSource});

  @override
  Future<List<Map<String, dynamic>>> getShiftsForMonth(DateTime month) async {
    return await dataSource.getShiftsForMonth(month);
  }

  @override
  Future<Map<String, dynamic>> getShiftsForDate(DateTime date) async {
    return await dataSource.getShiftsForDate(date);
  }
}
