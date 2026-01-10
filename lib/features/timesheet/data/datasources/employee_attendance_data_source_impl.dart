import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../models/employee_attendance_model.dart';
import 'employee_attendance_data_source.dart';

/// Реализация источника данных для посещаемости сотрудников с использованием Supabase.
class EmployeeAttendanceDataSourceImpl implements EmployeeAttendanceDataSource {
  /// Клиент Supabase для работы с базой данных.
  final SupabaseClient client;

  /// ID активной компании.
  final String activeCompanyId;

  /// Логгер для отладки и отслеживания ошибок.
  final Logger _logger = Logger();

  /// Название таблицы
  static const String tableName = 'employee_attendance';

  /// Создает экземпляр [EmployeeAttendanceDataSourceImpl].
  EmployeeAttendanceDataSourceImpl(this.client, this.activeCompanyId);

  @override
  Future<List<EmployeeAttendanceModel>> getAttendanceRecords({
    DateTime? startDate,
    DateTime? endDate,
    String? employeeId,
    String? objectId,
  }) async {
    try {
      // Создаём начальный query builder
      var queryBuilder = client.from(tableName).select().eq('company_id', activeCompanyId);

      // Фильтрация по сотруднику
      if (employeeId != null) {
        queryBuilder = queryBuilder.eq('employee_id', employeeId);
      }

      // Фильтрация по объекту
      if (objectId != null) {
        queryBuilder = queryBuilder.eq('object_id', objectId);
      }

      // Фильтрация по дате (начало периода)
      if (startDate != null) {
        final startDateStr = startDate.toIso8601String().split('T')[0];
        queryBuilder = queryBuilder.gte('date', startDateStr);
      }

      // Фильтрация по дате (конец периода)
      if (endDate != null) {
        final endDateStr = endDate.toIso8601String().split('T')[0];
        queryBuilder = queryBuilder.lte('date', endDateStr);
      }

      // Выполняем запрос с сортировкой
      final response = await queryBuilder.order('date', ascending: true);

      return (response as List)
          .map((item) => EmployeeAttendanceModel.fromJson(item))
          .toList();
    } catch (e) {
      _logger.e('Ошибка при получении записей посещаемости: $e');
      rethrow;
    }
  }

  @override
  Future<EmployeeAttendanceModel> createAttendance(
      EmployeeAttendanceModel model) async {
    try {
      final data = model.toJson();
      data.remove('id'); // ID генерируется автоматически
      data.remove('created_at'); // Устанавливается автоматически
      data.remove('updated_at'); // Устанавливается автоматически

      final response =
          await client.from(tableName).insert(data).select().single();

      return EmployeeAttendanceModel.fromJson(response);
    } catch (e) {
      _logger.e('Ошибка при создании записи посещаемости: $e');
      rethrow;
    }
  }

  @override
  Future<EmployeeAttendanceModel> updateAttendance(
      EmployeeAttendanceModel model) async {
    try {
      final data = model.toJson();
      data.remove('created_at'); // Не обновляем дату создания
      data.remove('updated_at'); // Обновляется автоматически триггером

      final response = await client
          .from(tableName)
          .update(data)
          .eq('id', model.id)
          .select()
          .single();

      return EmployeeAttendanceModel.fromJson(response);
    } catch (e) {
      _logger.e('Ошибка при обновлении записи посещаемости: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteAttendance(String id) async {
    try {
      await client.from(tableName).delete().eq('id', id);
    } catch (e) {
      _logger.e('Ошибка при удалении записи посещаемости: $e');
      rethrow;
    }
  }

  @override
  Future<EmployeeAttendanceModel?> getAttendanceById(String id) async {
    try {
      final response = await client
          .from(tableName)
          .select()
          .eq('id', id)
          .eq('company_id', activeCompanyId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return EmployeeAttendanceModel.fromJson(response);
    } catch (e) {
      _logger.e('Ошибка при получении записи посещаемости по ID: $e');
      rethrow;
    }
  }

  @override
  Future<void> batchUpsertAttendance(
      List<EmployeeAttendanceModel> models) async {
    try {
      // Обрабатываем каждую запись отдельно для надёжности
      for (final model in models) {
        final employeeId = model.employeeId;
        final objectId = model.objectId;
        final date = model.date;

        // Проверяем, существует ли запись
        final existing = await client
            .from(tableName)
            .select('id')
            .eq('employee_id', employeeId)
            .eq('company_id', activeCompanyId)
            .eq('object_id', objectId)
            .eq('date', date)
            .maybeSingle();

        final data = model.toJson();
        data.remove('created_at');
        data.remove('updated_at');
        data.remove('created_by');

        if (existing != null) {
          // Запись существует - обновляем
          data.remove('id'); // Не обновляем id
          await client
              .from(tableName)
              .update(data)
              .eq('employee_id', employeeId)
              .eq('company_id', activeCompanyId)
              .eq('object_id', objectId)
              .eq('date', date);
        } else {
          // Записи нет - вставляем новую
          data.remove('id'); // Пусть БД сгенерирует id
          data['company_id'] = activeCompanyId;
          await client.from(tableName).insert(data);
        }
      }
    } catch (e) {
      _logger.e('Ошибка при массовом обновлении записей посещаемости: $e');
      rethrow;
    }
  }
}
