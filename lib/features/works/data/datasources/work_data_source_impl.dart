import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../models/work_model.dart';
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
}
