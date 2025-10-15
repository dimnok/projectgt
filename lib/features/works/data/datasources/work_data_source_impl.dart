import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../models/work_model.dart';
import '../models/month_group.dart';
import 'work_data_source.dart';

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
      // Эти поля вычисляются автоматически при изменении work_items и work_hours.
      // Если их оставить в JSON, они перезапишут рассчитанные триггерами значения!
      workJson.remove('total_amount');
      workJson.remove('items_count');
      workJson.remove('employees_count');

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
  ///
  /// Использует SQL-агрегацию через RPC-функцию для максимальной производительности.
  @override
  Future<List<MonthGroup>> getMonthsHeaders() async {
    try {
      // Вызываем RPC-функцию PostgreSQL для группировки на стороне БД
      // Это в 100x быстрее чем загружать все смены и группировать на клиенте!
      final response = await client.rpc('get_months_summary');

      // Преобразуем результат в MonthGroup
      final groups = (response as List).map<MonthGroup>((json) {
        final month = DateTime.parse(json['month'] as String);
        final worksCount = (json['works_count'] as num).toInt();
        final totalAmount = (json['total_amount_sum'] as num).toDouble();

        return MonthGroup(
          month: month,
          worksCount: worksCount,
          totalAmount: totalAmount,
          isExpanded: false, // ВСЕ месяцы свёрнуты - загрузка только по клику
          works: null, // Будут загружены лениво при раскрытии
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
      // Начало месяца
      final startDate = DateTime(month.year, month.month, 1);
      // Начало следующего месяца
      final endDate = DateTime(month.year, month.month + 1, 1);

      // Загружаем смены месяца с пагинацией
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
}
