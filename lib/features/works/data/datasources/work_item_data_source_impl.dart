import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../models/work_item_model.dart';
import 'work_item_data_source.dart';

/// Реализация источника данных для работы с работами в смене через Supabase.
class WorkItemDataSourceImpl implements WorkItemDataSource {
  /// Клиент Supabase для доступа к базе данных.
  final SupabaseClient client;
  /// Название таблицы работ.
  static const String table = 'work_items';
  /// Логгер для вывода ошибок.
  final Logger _logger = Logger();

  /// Создаёт источник данных для работы с работами в смене.
  WorkItemDataSourceImpl(this.client);

  /// Возвращает список работ для смены по идентификатору [workId].
  @override
  Future<List<WorkItemModel>> fetchWorkItems(String workId) async {
    if (workId.isEmpty) {
      _logger.w('fetchWorkItems: workId пустой, возвращаю пустой список');
      return [];
    }
    try {
      final response = await client
          .from(table)
          .select()
          .eq('work_id', workId)
          .order('created_at');
      return response.map<WorkItemModel>((json) {
        try {
          return WorkItemModel.fromJson(json);
        } catch (e) {
          _logger.e('Ошибка fromJson для work_items: $json');
          rethrow;
        }
      }).toList();
    } catch (e) {
      _logger.e('Ошибка получения списка работ: $e');
      rethrow;
    }
  }

  /// Добавляет новую работу [item] в смену.
  @override
  Future<void> addWorkItem(WorkItemModel item) async {
    try {
      if (item.workId.isEmpty) {
        _logger.e('addWorkItem: workId пустой! Работа не будет добавлена.');
        throw ArgumentError('workId не может быть пустым');
      }
      final now = DateTime.now().toIso8601String();
      final itemJson = item.toJson();
      itemJson['created_at'] = now;
      itemJson['updated_at'] = now;
      await client.from(table).insert(itemJson);
    } catch (e) {
      _logger.e('Ошибка добавления работы: $e');
      rethrow;
    }
  }

  /// Обновляет работу [item] в смене.
  @override
  Future<void> updateWorkItem(WorkItemModel item) async {
    try {
      final now = DateTime.now().toIso8601String();
      final itemJson = item.toJson();
      itemJson['updated_at'] = now;
      
      await client.from(table).update(itemJson).eq('id', item.id);
    } catch (e) {
      _logger.e('Ошибка обновления работы: $e');
      rethrow;
    }
  }

  /// Удаляет работу по идентификатору [id].
  @override
  Future<void> deleteWorkItem(String id) async {
    try {
      await client.from(table).delete().eq('id', id);
    } catch (e) {
      _logger.e('Ошибка удаления работы: $e');
      rethrow;
    }
  }
  
  /// Возвращает список всех работ из всех смен.
  @override
  Future<List<WorkItemModel>> getAllWorkItems() async {
    try {
      final response = await client
          .from(table)
          .select()
          .order('created_at');
      return response.map<WorkItemModel>((json) {
        try {
          return WorkItemModel.fromJson(json);
        } catch (e) {
          _logger.e('Ошибка fromJson для work_items: $json');
          rethrow;
        }
      }).toList();
    } catch (e) {
      _logger.e('Ошибка получения всех работ: $e');
      rethrow;
    }
  }
} 