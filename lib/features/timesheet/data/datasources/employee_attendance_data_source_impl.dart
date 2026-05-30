import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../models/employee_attendance_model.dart';
import '../timesheet_company_scope.dart';
import 'employee_attendance_data_source.dart';

/// Реализация источника данных для посещаемости сотрудников с использованием Supabase.
class EmployeeAttendanceDataSourceImpl implements EmployeeAttendanceDataSource {
  /// Клиент Supabase для работы с базой данных.
  final SupabaseClient client;

  /// ID активной компании (`null` — компания не выбрана).
  final String? activeCompanyId;

  /// Логгер для отладки и отслеживания ошибок.
  final Logger _logger = Logger();

  /// Название таблицы
  static const String tableName = 'employee_attendance';

  /// Максимум строк в одном ответе PostgREST; без пагинации остальные строки отбрасываются.
  static const int _postgrestPageSize = 1000;

  /// Имя RPC пакетного upsert ([upsert_employee_attendance_batch]).
  static const String batchUpsertRpc = 'upsert_employee_attendance_batch';

  /// Создает экземпляр [EmployeeAttendanceDataSourceImpl].
  EmployeeAttendanceDataSourceImpl(this.client, this.activeCompanyId);

  String get _scopedCompanyId {
    final id = activeCompanyId;
    if (!timesheetHasActiveCompany(id)) {
      throw const TimesheetCompanyNotSelectedException();
    }
    return id!;
  }

  /// Строка для [batchUpsertRpc]: без id и служебных полей.
  Map<String, dynamic> _rowForBatchUpsert(EmployeeAttendanceModel model) {
    final data = model.toJson()
      ..remove('id')
      ..remove('created_at')
      ..remove('updated_at')
      ..remove('created_by');
    data['company_id'] = _scopedCompanyId;
    return data;
  }

  /// Создаёт запрос по таблице посещаемости с фильтрами (без сортировки и [PostgrestFilterBuilder.range]).
  dynamic _attendanceRecordsQuery({
    String? employeeId,
    List<String>? objectIds,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    var queryBuilder =
        client.from(tableName).select().eq('company_id', _scopedCompanyId);

    if (employeeId != null) {
      queryBuilder = queryBuilder.eq('employee_id', employeeId);
    }

    if (objectIds != null && objectIds.isNotEmpty) {
      queryBuilder = queryBuilder.inFilter('object_id', objectIds);
    }

    if (startDate != null) {
      final startDateStr = startDate.toIso8601String().split('T')[0];
      queryBuilder = queryBuilder.gte('date', startDateStr);
    }

    if (endDate != null) {
      final endDateStr = endDate.toIso8601String().split('T')[0];
      queryBuilder = queryBuilder.lte('date', endDateStr);
    }

    return queryBuilder;
  }

  @override
  Future<List<EmployeeAttendanceModel>> getAttendanceRecords({
    DateTime? startDate,
    DateTime? endDate,
    String? employeeId,
    List<String>? objectIds,
  }) async {
    if (!timesheetHasActiveCompany(activeCompanyId)) {
      return [];
    }
    try {
      final allRows = <Map<String, dynamic>>[];
      var offset = 0;
      var hasMore = true;

      while (hasMore) {
        final response = await _attendanceRecordsQuery(
          employeeId: employeeId,
          objectIds: objectIds,
          startDate: startDate,
          endDate: endDate,
        )
            .order('date', ascending: true)
            .order('id', ascending: true)
            .range(offset, offset + _postgrestPageSize - 1);

        if (response.isEmpty) {
          break;
        }

        for (final row in response) {
          allRows.add(Map<String, dynamic>.from(row as Map));
        }

        if (response.length < _postgrestPageSize) {
          hasMore = false;
        } else {
          offset += _postgrestPageSize;
        }
      }

      return allRows
          .map((item) => EmployeeAttendanceModel.fromJson(item))
          .toList();
    } catch (e) {
      _logger.e('Ошибка при получении записей посещаемости: $e');
      rethrow;
    }
  }

  @override
  Future<void> batchUpsertAttendance(
    List<EmployeeAttendanceModel> models,
  ) async {
    if (models.isEmpty) return;
    if (!timesheetHasActiveCompany(activeCompanyId)) {
      throw const TimesheetCompanyNotSelectedException();
    }
    try {
      final rows = models.map(_rowForBatchUpsert).toList();
      await client.rpc(batchUpsertRpc, params: {'p_rows': rows});
    } catch (e) {
      _logger.e('Ошибка при массовом обновлении записей посещаемости: $e');
      rethrow;
    }
  }
}
