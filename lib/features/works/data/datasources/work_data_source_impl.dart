import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../models/work_model.dart';
import '../models/month_group.dart';
import '../models/light_work_model.dart';
import '../../domain/entities/work_summaries.dart';
import 'work_data_source.dart';

// ignore_for_file: override_on_non_overriding_member
/// Реализация источника данных для работы со сменами через Supabase.
class WorkDataSourceImpl implements WorkDataSource {
  /// Клиент Supabase для доступа к базе данных.
  final SupabaseClient client;

  /// Название таблицы смен.
  static const String table = 'works';

  /// Логгер для вывода ошибок.
  final Logger _logger = Logger();

  /// Создаёт источник данных для работы со сменами.
  WorkDataSourceImpl(this.client);

  /// Возвращает список всех смен.
  @override
  Future<List<WorkModel>> getWorks() async {
    try {
      final response = await client
          .from(table)
          .select('*')
          .order('created_at', ascending: false);
      return response
          .map<WorkModel>((json) => WorkModel.fromJson(json))
          .toList();
    } catch (e) {
      _logger.e('Ошибка получения списка смен: $e');
      rethrow;
    }
  }

  /// Возвращает смену по идентификатору [id].
  @override
  Future<WorkModel?> getWork(String id) async {
    try {
      final response =
          await client.from(table).select('*').eq('id', id).maybeSingle();
      if (response == null) return null;
      return WorkModel.fromJson(response);
    } catch (e) {
      _logger.e('Ошибка получения смены: $e');
      rethrow;
    }
  }

  /// Добавляет новую смену [work] и возвращает созданную модель.
  @override
  Future<WorkModel> addWork(WorkModel work) async {
    try {
      final now = DateTime.now().toIso8601String();
      final workJson = work.toJson();
      workJson['created_at'] = now;
      workJson['updated_at'] = now;
      workJson.remove('id');

      final response =
          await client.from(table).insert(workJson).select().single();
      return WorkModel.fromJson(response);
    } catch (e) {
      _logger.e('Ошибка создания смены: $e');
      rethrow;
    }
  }

  /// Обновляет данные смены [work] и возвращает обновлённую модель.
  @override
  Future<WorkModel> updateWork(WorkModel work) async {
    try {
      final now = DateTime.now().toIso8601String();
      final workJson = work.toJson();
      workJson['updated_at'] = now;

      // КРИТИЧНО: Удаляем агрегатные поля, которые управляются триггерами БД.
      workJson.remove('total_amount');
      workJson.remove('items_count');
      workJson.remove('employees_count');

      // ЗАЩИТА: Если поля были NULL при загрузке, не перезаписываем их на NULL в БД.
      final nullableFields = {
        'photo_url',
        'evening_photo_url',
        'telegram_message_id'
      };
      workJson.removeWhere(
          (key, value) => value == null && nullableFields.contains(key));

      final response = await client
          .from(table)
          .update(workJson)
          .eq('id', work.id!)
          .select()
          .single();
      return WorkModel.fromJson(response);
    } catch (e) {
      _logger.e('Ошибка обновления смены: $e');
      rethrow;
    }
  }

  /// Удаляет смену по идентификатору [id].
  @override
  Future<void> deleteWork(String id) async {
    try {
      await client.from(table).delete().eq('id', id);
    } catch (e) {
      _logger.e('Ошибка удаления смены: $e');
      rethrow;
    }
  }

  /// Возвращает заголовки групп месяцев с агрегированными данными.
  @override
  Future<List<MonthGroup>> getMonthsHeaders() async {
    try {
      final response = await client.rpc('get_months_summary');

      final groups = (response as List).map<MonthGroup>((json) {
        final month = DateTime.parse(json['month'] as String);
        final worksCount = (json['works_count'] as num).toInt();
        final totalAmount = (json['total_amount_sum'] as num).toDouble();

        return MonthGroup(
          month: month,
          worksCount: worksCount,
          totalAmount: totalAmount,
          isExpanded: false,
          works: null,
        );
      }).toList();

      return groups;
    } catch (e) {
      _logger.e('Ошибка получения заголовков месяцев: $e');
      rethrow;
    }
  }

  /// Возвращает смены конкретного месяца с пагинацией.
  @override
  Future<List<WorkModel>> getMonthWorks(
    DateTime month, {
    int offset = 0,
    int limit = 30,
  }) async {
    try {
      final startDate = DateTime(month.year, month.month, 1);
      final endDate = DateTime(month.year, month.month + 1, 1);

      final response = await client
          .from(table)
          .select('*')
          .gte('date', startDate.toIso8601String())
          .lt('date', endDate.toIso8601String())
          .order('date', ascending: false)
          .range(offset, offset + limit - 1);

      return response
          .map<WorkModel>((json) => WorkModel.fromJson(json))
          .toList();
    } catch (e) {
      _logger.e('Ошибка получения смен месяца: $e');
      rethrow;
    }
  }

  /// Возвращает полные данные по выработке за месяц для графика.
  @override
  Future<List<LightWorkModel>> getMonthWorksForChart(DateTime month) async {
    try {
      final startDate = DateTime(month.year, month.month, 1);
      final endDate = DateTime(month.year, month.month + 1, 1);

      final response = await client
          .from(table)
          .select('id, date, total_amount, employees_count')
          .gte('date', startDate.toIso8601String())
          .lt('date', endDate.toIso8601String())
          .order('date', ascending: false);

      return response
          .map<LightWorkModel>((json) => LightWorkModel.fromJson(json))
          .toList();
    } catch (e) {
      _logger.e('Ошибка получения смен месяца для графика: $e');
      rethrow;
    }
  }

  /// Возвращает полную статистику по объектам за месяц.
  @override
  Future<List<ObjectSummary>> getObjectsSummary(DateTime month) async {
    try {
      final monthStr =
          '${month.year}-${month.month.toString().padLeft(2, '0')}-01';

      final response = await client.rpc('get_month_objects_summary', params: {
        'p_month': monthStr,
      });

      return (response as List).map((json) {
        return ObjectSummary(
          objectId: json['object_id'] as String? ?? '',
          objectName: json['object_name'] as String? ?? 'Неизвестный объект',
          worksCount: (json['works_count'] as num?)?.toInt() ?? 0,
          totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
        );
      }).toList();
    } catch (e) {
      _logger.e('Ошибка получения статистики по объектам: $e');
      rethrow;
    }
  }

  /// Возвращает полную статистику по системам за месяц.
  @override
  Future<List<SystemSummary>> getSystemsSummary(DateTime month) async {
    try {
      final monthStr =
          '${month.year}-${month.month.toString().padLeft(2, '0')}-01';

      final response = await client.rpc('get_month_systems_summary', params: {
        'p_month': monthStr,
      });

      return (response as List).map((json) {
        return SystemSummary(
          system: json['system'] as String? ?? 'Неизвестная система',
          worksCount: (json['works_count'] as num?)?.toInt() ?? 0,
          itemsCount: (json['items_count'] as num?)?.toInt() ?? 0,
          totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
        );
      }).toList();
    } catch (e) {
      _logger.e('Ошибка получения статистики по системам: $e');
      rethrow;
    }
  }

  /// Возвращает общее количество часов за месяц.
  @override
  Future<MonthHoursSummary> getTotalHours(DateTime month) async {
    try {
      final monthStr =
          '${month.year}-${month.month.toString().padLeft(2, '0')}-01';

      final response = await client.rpc('get_month_hours_summary', params: {
        'p_month': monthStr,
      });

      final json = (response is List)
          ? (response.isEmpty ? {} : response.first)
          : response;

      return MonthHoursSummary(
        totalHours: (json['total_hours'] as num?)?.toDouble() ?? 0,
      );
    } catch (e) {
      _logger.e('Ошибка получения часов за месяц: $e');
      rethrow;
    }
  }

  /// Возвращает количество уникальных сотрудников за месяц.
  @override
  Future<MonthEmployeesSummary> getTotalEmployees(DateTime month) async {
    try {
      final monthStr =
          '${month.year}-${month.month.toString().padLeft(2, '0')}-01';

      final response = await client.rpc('get_month_employees_summary', params: {
        'p_month': monthStr,
      });

      final json = (response is List)
          ? (response.isEmpty ? {} : response.first)
          : response;

      return MonthEmployeesSummary(
        totalEmployees: (json['total_employees'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      _logger.e('Ошибка получения сотрудников за месяц: $e');
      rethrow;
    }
  }
}
