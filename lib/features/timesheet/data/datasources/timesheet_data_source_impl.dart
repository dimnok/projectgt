import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'timesheet_data_source.dart';

/// Реализация источника данных для табеля рабочего времени с использованием Supabase.
class TimesheetDataSourceImpl implements TimesheetDataSource {
  /// Клиент Supabase для работы с базой данных.
  final SupabaseClient client;

  /// Логгер для отладки и отслеживания ошибок.
  final Logger _logger = Logger();

  /// Название таблицы с часами работ.
  static const String workHoursTable = 'work_hours';

  /// Название таблицы с работами.
  static const String worksTable = 'works';

  /// Создает экземпляр [TimesheetDataSourceImpl].
  TimesheetDataSourceImpl(this.client);

  @override
  Future<List<Map<String, dynamic>>> getTimesheetEntries({
    DateTime? startDate,
    DateTime? endDate,
    String? employeeId,
    List<String>? objectIds,
    List<String>? positions,
  }) async {
    try {
      // Базовый запрос с join для получения данных из связанных таблиц
      String query = '''
        id,
        work_id,
        employee_id,
        hours,
        comment,
        created_at,
        updated_at,
        works:work_id (
          date,
          object_id,
          status
        ),
        employees:employee_id (
          position
        )
      ''';

      // Строим запрос с серверной фильтрацией
      var queryBuilder = client.from(workHoursTable).select(query);

      // Серверная фильтрация по employeeId (прямое поле в work_hours)
      if (employeeId != null) {
        queryBuilder = queryBuilder.eq('employee_id', employeeId);
      }

      // Серверная фильтрация только закрытых смен (через works)
      queryBuilder = queryBuilder.eq('works.status', 'closed');

      // Выполняем запрос с сортировкой
      final response = await queryBuilder.order('created_at');

      // Преобразуем результаты в плоский формат
      var flatResults = response
          .where((record) => record['works'] != null)
          .map<Map<String, dynamic>>((record) {
        final works = record['works'] as Map<String, dynamic>;
        final employees = record['employees'] as Map<String, dynamic>?;

        return {
          'id': record['id'],
          'work_id': record['work_id'],
          'employee_id': record['employee_id'],
          'hours': record['hours'],
          'comment': record['comment'],
          'date': works['date'],
          'object_id': works['object_id'],
          'employee_position': employees?['position'],
          'created_at': record['created_at'],
          'updated_at': record['updated_at'],
        };
      }).toList();

      // Клиентская фильтрация по диапазону дат
      if (startDate != null) {
        flatResults = flatResults.where((record) {
          final date = DateTime.tryParse(record['date'] ?? '');
          return date != null && !date.isBefore(startDate);
        }).toList();
      }

      if (endDate != null) {
        flatResults = flatResults.where((record) {
          final date = DateTime.tryParse(record['date'] ?? '');
          return date != null && !date.isAfter(endDate);
        }).toList();
      }

      // Клиентская фильтрация по объектам (мультивыбор)
      if (objectIds != null && objectIds.isNotEmpty) {
        flatResults = flatResults
            .where((record) => objectIds.contains(record['object_id']))
            .toList();
      }

      // Клиентская фильтрация по должностям
      if (positions != null && positions.isNotEmpty) {
        flatResults = flatResults.where((record) {
          final position = record['employee_position'];
          return position != null && positions.contains(position);
        }).toList();
      }

      return flatResults;
    } catch (e) {
      _logger.e('Ошибка при получении данных табеля: $e');
      rethrow;
    }
  }
}
