import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/work_item_model.dart';
import 'work_item_data_source.dart';

/// Реализация источника данных для работы с работами в смене через Supabase.
class WorkItemDataSourceImpl implements WorkItemDataSource {
  /// Клиент Supabase для доступа к базе данных.
  final SupabaseClient client;

  /// ID текущей активной компании для фильтрации данных (Multi-tenancy).
  final String activeCompanyId;

  /// Название таблицы работ.
  static const String table = 'work_items';

  /// Логгер удалён.

  /// Создаёт источник данных для работы с работами в смене.
  WorkItemDataSourceImpl(this.client, this.activeCompanyId);

  @override
  Future<WorkItemModel?> fetchWorkItemById(String workItemId) async {
    if (workItemId.isEmpty) return null;
    try {
      final response = await client
          .from(table)
          .select('*, estimates!estimate_id(number)')
          .eq('id', workItemId)
          .eq('company_id', activeCompanyId)
          .maybeSingle();
      if (response == null) return null;
      return _mapWithEstimateNumber(WorkItemModel.fromJson(response), response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Set<String>> fetchEstimateIdsForCombo({
    required String workId,
    required String section,
    required String floor,
    required String system,
    required String subsystem,
    String? contractorId,
  }) async {
    if (workId.isEmpty) return {};
    try {
      var query = client
          .from(table)
          .select('estimate_id')
          .eq('work_id', workId)
          .eq('company_id', activeCompanyId)
          .eq('section', section)
          .eq('floor', floor)
          .eq('system', system)
          .eq('subsystem', subsystem);

      query = contractorId == null
          ? query.isFilter('contractor_id', null)
          : query.eq('contractor_id', contractorId);

      final response = await query;
      return response
          .map((row) => row['estimate_id'] as String?)
          .whereType<String>()
          .toSet();
    } catch (e) {
      rethrow;
    }
  }

  /// Возвращает список работ для смены по идентификатору [workId].
  ///
  /// Номер позиции присоединяется LEFT JOIN к `estimates` (поле `number`),
  /// поэтому приезжает сразу вместе с работой — без отдельной загрузки смет.
  @override
  Future<List<WorkItemModel>> fetchWorkItems(String workId) async {
    if (workId.isEmpty) {
      return [];
    }
    try {
      final response = await client
          .from(table)
          .select('*, estimates!estimate_id(number)')
          .eq('work_id', workId)
          .eq('company_id', activeCompanyId)
          .order('created_at');
      return response.map<WorkItemModel>((json) {
        try {
          return _mapWithEstimateNumber(WorkItemModel.fromJson(json), json);
        } catch (e) {
          rethrow;
        }
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Достаёт номер позиции из вложенного объекта JOIN'а `estimates` и проставляет его в модель.
  ///
  /// PostgREST возвращает родителя (estimates) объектом при many-to-one, но на случай
  /// разных конфигураций обрабатываем и List, и Map, и отсутствие данных.
  WorkItemModel _mapWithEstimateNumber(
    WorkItemModel model,
    Map<String, dynamic> row,
  ) {
    final est = row['estimates'];
    String? number;
    if (est is Map<String, dynamic>) {
      number = est['number'] as String?;
    } else if (est is List && est.isNotEmpty) {
      final first = est.first;
      if (first is Map<String, dynamic>) {
        number = first['number'] as String?;
      }
    }
    return model.copyWith(number: number);
  }

  /// Пакетно добавляет несколько работ [items] в смену одним запросом.
  @override
  Future<void> addWorkItems(List<WorkItemModel> items) async {
    try {
      if (items.isEmpty) return;
      final now = DateTime.now().toIso8601String();
      final payload = items.map((it) {
        final json = it.toJson();
        if ((json['work_id'] as String?)?.isEmpty ?? true) {
          throw ArgumentError('workId не может быть пустым');
        }
        json['created_at'] = now;
        json['updated_at'] = now;
        json['company_id'] = activeCompanyId;
        return json;
      }).toList();
      await client.from(table).insert(payload);
    } catch (e) {
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
      itemJson['company_id'] = activeCompanyId;

      await client
          .from(table)
          .update(itemJson)
          .eq('id', item.id)
          .eq('company_id', activeCompanyId);
    } catch (e) {
      rethrow;
    }
  }

  /// Удаляет работу по идентификатору [id].
  @override
  Future<void> deleteWorkItem(String id) async {
    try {
      await client
          .from(table)
          .delete()
          .eq('id', id)
          .eq('company_id', activeCompanyId);
    } catch (e) {
      rethrow;
    }
  }
}
