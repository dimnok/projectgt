import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'timesheet_data_source.dart';

/// Реализация источника данных для табеля рабочего времени с использованием Supabase.
class TimesheetDataSourceImpl implements TimesheetDataSource {
  /// Клиент Supabase для работы с базой данных.
  final SupabaseClient client;

  /// ID активной компании.
  final String activeCompanyId;

  /// Логгер для отладки и отслеживания ошибок.
  final Logger _logger = Logger();

  /// Название таблицы с часами работ.
  static const String workHoursTable = 'work_hours';

  /// Максимум строк в одном ответе PostgREST; без пагинации остальные строки отбрасываются.
  static const int _postgrestPageSize = 1000;

  /// Создает экземпляр [TimesheetDataSourceImpl].
  TimesheetDataSourceImpl(this.client, this.activeCompanyId);

  /// Строит запрос `work_hours` с join и фильтрами без сортировки и [PostgrestFilterBuilder.range].
  dynamic _timesheetRowsQuery({
    required String selectQuery,
    String? employeeId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    var queryBuilder = client
        .from(workHoursTable)
        .select(selectQuery)
        .eq('company_id', activeCompanyId);

    if (employeeId != null) {
      queryBuilder = queryBuilder.eq('employee_id', employeeId);
    }

    queryBuilder = queryBuilder.eq('works.status', 'closed');

    if (startDate != null) {
      final startDateStr = startDate.toIso8601String().split('T')[0];
      queryBuilder = queryBuilder.gte('works.date', startDateStr);
    }

    if (endDate != null) {
      final endDateStr = endDate.toIso8601String().split('T')[0];
      queryBuilder = queryBuilder.lte('works.date', endDateStr);
    }

    return queryBuilder;
  }

  /// Загружает все строки табеля из смен, обходя лимит PostgREST на размер ответа.
  Future<List<Map<String, dynamic>>> _fetchAllTimesheetWorkHourRows({
    required String selectQuery,
    String? employeeId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final all = <Map<String, dynamic>>[];
    var offset = 0;
    var hasMore = true;

    while (hasMore) {
      final response = await _timesheetRowsQuery(
        selectQuery: selectQuery,
        employeeId: employeeId,
        startDate: startDate,
        endDate: endDate,
      )
          .order('created_at', ascending: true)
          .order('id', ascending: true)
          .range(offset, offset + _postgrestPageSize - 1);

      if (response.isEmpty) {
        break;
      }

      for (final row in response) {
        all.add(Map<String, dynamic>.from(row as Map));
      }

      if (response.length < _postgrestPageSize) {
        hasMore = false;
      } else {
        offset += _postgrestPageSize;
      }
    }

    return all;
  }

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
      // Используем !inner для works, чтобы фильтрация по дате отсекала строки work_hours
      const selectQuery = '''
        id,
        work_id,
        employee_id,
        hours,
        comment,
        created_at,
        updated_at,
        works!inner (
          date,
          object_id,
          status,
          company_id
        ),
        employees:employee_id (
          position,
          company_id
        )
      ''';

      final response = await _fetchAllTimesheetWorkHourRows(
        selectQuery: selectQuery,
        employeeId: employeeId,
        startDate: startDate,
        endDate: endDate,
      );

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
