import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../timesheet_company_scope.dart';
import 'timesheet_data_source.dart';

/// Реализация источника данных для табеля рабочего времени с использованием Supabase.
class TimesheetDataSourceImpl implements TimesheetDataSource {
  /// Клиент Supabase для работы с базой данных.
  final SupabaseClient client;

  /// ID активной компании (`null` — компания не выбрана).
  final String? activeCompanyId;

  /// Логгер для отладки и отслеживания ошибок.
  final Logger _logger = Logger();

  /// Название таблицы с часами работ.
  static const String workHoursTable = 'work_hours';

  /// Максимум строк в одном ответе PostgREST; без пагинации остальные строки отбрасываются.
  static const int _postgrestPageSize = 1000;

  /// Создает экземпляр [TimesheetDataSourceImpl].
  TimesheetDataSourceImpl(this.client, this.activeCompanyId);

  String get _scopedCompanyId {
    final id = activeCompanyId;
    if (!timesheetHasActiveCompany(id)) {
      throw const TimesheetCompanyNotSelectedException();
    }
    return id!;
  }

  /// Строит запрос `work_hours` с join и фильтрами без сортировки и [PostgrestFilterBuilder.range].
  dynamic _timesheetRowsQuery({
    required String selectQuery,
    String? employeeId,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? objectIds,
  }) {
    var queryBuilder = client
        .from(workHoursTable)
        .select(selectQuery)
        .eq('company_id', _scopedCompanyId);

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

    if (objectIds != null && objectIds.isNotEmpty) {
      queryBuilder = queryBuilder.inFilter('works.object_id', objectIds);
    }

    return queryBuilder;
  }

  /// Плоская строка `work_hours` + поля смены (`works`).
  Map<String, dynamic> _flattenWorkHourRow(Map<String, dynamic> record) {
    final works = record['works'] as Map<String, dynamic>;

    return {
      'id': record['id'],
      'work_id': record['work_id'],
      'employee_id': record['employee_id'],
      'hours': record['hours'],
      'comment': record['comment'],
      'date': works['date'],
      'object_id': works['object_id'],
      'created_at': record['created_at'],
      'updated_at': record['updated_at'],
    };
  }

  /// Загружает все строки табеля из смен, обходя лимит PostgREST на размер ответа.
  Future<List<Map<String, dynamic>>> _fetchAllTimesheetWorkHourRows({
    required String selectQuery,
    String? employeeId,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? objectIds,
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
        objectIds: objectIds,
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
  }) async {
    if (!timesheetHasActiveCompany(activeCompanyId)) {
      return [];
    }
    try {
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
        )
      ''';

      final response = await _fetchAllTimesheetWorkHourRows(
        selectQuery: selectQuery,
        employeeId: employeeId,
        startDate: startDate,
        endDate: endDate,
        objectIds: objectIds,
      );

      return response.map(_flattenWorkHourRow).toList();
    } catch (e) {
      _logger.e('Ошибка при получении данных табеля: $e');
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getShiftWorkHoursForEmployee({
    required String employeeId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!timesheetHasActiveCompany(activeCompanyId)) {
      return [];
    }
    try {
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
        )
      ''';

      final response = await _fetchAllTimesheetWorkHourRows(
        selectQuery: selectQuery,
        employeeId: employeeId,
        startDate: startDate,
        endDate: endDate,
      );

      return response.map(_flattenWorkHourRow).toList();
    } catch (e) {
      _logger.e(
        'Ошибка при получении сменных часов сотрудника $employeeId: $e',
      );
      rethrow;
    }
  }
}
