import '../../domain/entities/work_hour.dart';
import '../../domain/repositories/work_hour_repository.dart';
import '../datasources/work_hour_data_source.dart';
import '../models/work_hour_model.dart';

/// Реализация репозитория для работы с часами сотрудников в смене через источник данных [WorkHourDataSource].
class WorkHourRepositoryImpl implements WorkHourRepository {
  /// Источник данных для учёта часов сотрудников.
  final WorkHourDataSource dataSource;

  /// Создаёт репозиторий для работы с часами сотрудников в смене.
  WorkHourRepositoryImpl(this.dataSource);

  /// Возвращает список записей о часах для смены по идентификатору [workId].
  @override
  Future<List<WorkHour>> fetchWorkHours(String workId) async {
    final models = await dataSource.fetchWorkHours(workId);
    return models.map((e) => WorkHour.fromJson(e.toJson())).toList();
  }

  /// Добавляет новую запись о часах [hour] в смену.
  @override
  Future<void> addWorkHour(WorkHour hour) async {
    await dataSource.addWorkHour(WorkHourModel.fromJson(hour.toJson()));
  }

  /// Обновляет запись о часах [hour] в смене.
  @override
  Future<void> updateWorkHour(WorkHour hour) async {
    await dataSource.updateWorkHour(WorkHourModel.fromJson(hour.toJson()));
  }

  /// Удаляет запись о часах по идентификатору [id].
  @override
  Future<void> deleteWorkHour(String id) async {
    await dataSource.deleteWorkHour(id);
  }

  @override
  Future<List<WorkHour>> fetchWorkHoursByEmployeeAndPeriod(String employeeId, DateTime monthStart, DateTime monthEnd) async {
    final models = await dataSource.fetchWorkHoursByEmployeeAndPeriod(employeeId, monthStart, monthEnd);
    return models.map((e) => WorkHour.fromJson(e.toJson())).toList();
  }
} 