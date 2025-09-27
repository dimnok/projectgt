import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../models/work_hour_model.dart';
import 'work_hour_data_source.dart';

/// Реализация источника данных для работы с часами сотрудников в смене через Supabase.
class WorkHourDataSourceImpl implements WorkHourDataSource {
  /// Клиент Supabase для доступа к базе данных.
  final SupabaseClient client;

  /// Название таблицы учёта часов.
  static const String table = 'work_hours';

  /// Логгер для вывода ошибок.
  final Logger _logger = Logger();

  /// Создаёт источник данных для работы с часами сотрудников в смене.
  WorkHourDataSourceImpl(this.client);

  /// Возвращает список записей о часах для смены по идентификатору [workId].
  @override
  Future<List<WorkHourModel>> fetchWorkHours(String workId) async {
    try {
      final response = await client
          .from(table)
          .select()
          .eq('work_id', workId)
          .order('created_at');

      return response
          .map<WorkHourModel>((json) => WorkHourModel.fromJson(json))
          .toList();
    } catch (e) {
      _logger.e('Ошибка получения списка часов: $e');
      rethrow;
    }
  }

  /// Добавляет новую запись о часах [hour] в смену.
  @override
  Future<void> addWorkHour(WorkHourModel hour) async {
    try {
      final now = DateTime.now().toIso8601String();
      final hourJson = hour.toJson();
      hourJson['created_at'] = now;
      hourJson['updated_at'] = now;

      await client.from(table).insert(hourJson);
    } catch (e) {
      _logger.e('Ошибка добавления часов: $e');
      rethrow;
    }
  }

  /// Обновляет запись о часах [hour] в смене.
  @override
  Future<void> updateWorkHour(WorkHourModel hour) async {
    try {
      final now = DateTime.now().toIso8601String();
      final hourJson = hour.toJson();
      hourJson['updated_at'] = now;

      await client.from(table).update(hourJson).eq('id', hour.id);
    } catch (e) {
      _logger.e('Ошибка обновления часов: $e');
      rethrow;
    }
  }

  /// Удаляет запись о часах по идентификатору [id].
  @override
  Future<void> deleteWorkHour(String id) async {
    try {
      await client.from(table).delete().eq('id', id);
    } catch (e) {
      _logger.e('Ошибка удаления часов: $e');
      rethrow;
    }
  }

  @override
  Future<List<WorkHourModel>> fetchWorkHoursByEmployeeAndPeriod(
      String employeeId, DateTime monthStart, DateTime monthEnd) async {
    try {
      final response = await client
          .from(table)
          .select()
          .eq('employee_id', employeeId)
          .gte('created_at', monthStart.toIso8601String())
          .lt('created_at', monthEnd.toIso8601String());
      return response
          .map<WorkHourModel>((json) => WorkHourModel.fromJson(json))
          .toList();
    } catch (e) {
      _logger.e('Ошибка получения work_hours по сотруднику и периоду: $e');
      rethrow;
    }
  }

  /// Массовое обновление/вставка часов в один запрос (upsert по id)
  @override
  Future<void> updateWorkHoursBulk(List<WorkHourModel> hours) async {
    if (hours.isEmpty) return;
    try {
      final now = DateTime.now().toIso8601String();
      final payload = hours.map((h) {
        final map = h.toJson();
        map['updated_at'] = now;
        return map;
      }).toList();

      await client.from(table).upsert(payload);
    } catch (e) {
      _logger.e('Ошибка массового обновления часов: $e');
      rethrow;
    }
  }
}
