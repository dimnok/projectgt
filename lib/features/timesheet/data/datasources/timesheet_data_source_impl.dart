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
    String? objectId,
  }) async {
    try {
      // Базовый запрос с join
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
          object_id
        )
      ''';
      
      // Выполняем запрос
      final response = await client
          .from(workHoursTable)
          .select(query)
          .order('created_at');
      
      // Получаем результаты и преобразуем их в плоский формат
      var flatResults = response.map<Map<String, dynamic>>((record) {
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
      }).toList();
      
      // Фильтрация на стороне клиента
      if (employeeId != null) {
        flatResults = flatResults.where((record) => 
          record['employee_id'] == employeeId
        ).toList();
      }
      
      // Дополнительная фильтрация по дате и объекту
      if (startDate != null || endDate != null || objectId != null) {
        flatResults = flatResults.where((record) {
          final date = DateTime.tryParse(record['date']);
          
          bool matchesDateRange = true;
          if (date != null) {
            if (startDate != null && date.isBefore(startDate)) {
              matchesDateRange = false;
            }
            if (endDate != null && date.isAfter(endDate)) {
              matchesDateRange = false;
            }
          }
          
          bool matchesObject = true;
          if (objectId != null) {
            matchesObject = record['object_id'] == objectId;
          }
          
          return matchesDateRange && matchesObject;
        }).toList();
      }
      
      return flatResults;
    } catch (e) {
      _logger.e('Ошибка при получении данных табеля: $e');
      rethrow;
    }
  }
} 