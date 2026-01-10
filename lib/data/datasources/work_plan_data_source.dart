import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projectgt/data/models/work_plan_model.dart';

/// Абстракция источника данных для работы с планами работ [WorkPlanModel].
/// Определяет базовые CRUD-операции для реализации в конкретных источниках.
abstract class WorkPlanDataSource {
  /// Получить список планов работ с фильтрами.
  ///
  /// [limit] — максимальное количество записей.
  /// [offset] — смещение для пагинации.
  /// [dateFrom] — фильтр по дате от.
  /// [dateTo] — фильтр по дате до.
  /// Возвращает [List<WorkPlanModel>].
  Future<List<WorkPlanModel>> getWorkPlans({
    int? limit,
    int? offset,
    DateTime? dateFrom,
    DateTime? dateTo,
  });

  /// Получить план работ по идентификатору.
  ///
  /// [id] — уникальный идентификатор плана работ.
  /// Возвращает [WorkPlanModel], либо null, если не найден.
  Future<WorkPlanModel?> getWorkPlan(String id);

  /// Создать новый план работ.
  ///
  /// [workPlan] — данные нового плана работ.
  /// Возвращает созданный [WorkPlanModel] с присвоенным идентификатором.
  Future<WorkPlanModel> createWorkPlan(WorkPlanModel workPlan);

  /// Обновить существующий план работ.
  ///
  /// [workPlan] — план работ с обновлёнными данными (id обязателен).
  /// Возвращает обновлённый [WorkPlanModel].
  Future<WorkPlanModel> updateWorkPlan(WorkPlanModel workPlan);

  /// Удалить план работ по идентификатору.
  ///
  /// [id] — уникальный идентификатор плана работ.
  /// Возвращает true, если план успешно удалён.
  Future<bool> deleteWorkPlan(String id);

  /// Получить планы работ с дополнительной информацией об объектах.
  ///
  /// Использует функцию get_user_work_plans из базы данных.
  Future<List<WorkPlanModel>> getUserWorkPlans({
    int limit = 50,
    int offset = 0,
    DateTime? dateFrom,
    DateTime? dateTo,
  });

  /// Получить детальную информацию о плане работ.
  ///
  /// [id] — уникальный идентификатор плана работ.
  /// Возвращает [WorkPlanModel] с дополнительной информацией.
  Future<WorkPlanModel?> getWorkPlanDetails(String id);
}

/// Реализация [WorkPlanDataSource] для Supabase.
/// Использует [SupabaseClient] для взаимодействия с таблицей work_plans.
class SupabaseWorkPlanDataSource implements WorkPlanDataSource {
  /// Клиент Supabase для работы с БД.
  final SupabaseClient client;

  /// ID текущей активной компании для фильтрации данных (Multi-tenancy).
  final String activeCompanyId;

  /// Создаёт экземпляр с переданным [client] и [activeCompanyId].
  SupabaseWorkPlanDataSource(this.client, this.activeCompanyId);

  Map<String, dynamic> _transformEmbedded(Map<String, dynamic> src) {
    final result = Map<String, dynamic>.from(src);
    
    // Переименовываем ключ блоков для соответствия WorkPlanModel (work_blocks)
    if (result.containsKey('work_plan_blocks')) {
      result['work_blocks'] = result['work_plan_blocks'];
      result.remove('work_plan_blocks');
    }
    
    return result;
  }

  @override
  Future<List<WorkPlanModel>> getWorkPlans({
    int? limit,
    int? offset,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final query = client
        .from('work_plans')
        .select(
            'id, created_at, updated_at, created_by, date, object_id, company_id, '
            'work_plan_blocks(id, system, section, floor, responsible_id, worker_ids, company_id, '
            'work_plan_items(estimate_id, name, unit, price, planned_quantity, actual_quantity, company_id))')
        .eq('company_id', activeCompanyId);

    if (dateFrom != null) {
      query.gte('date', dateFrom.toIso8601String().split('T')[0]);
    }

    if (dateTo != null) {
      query.lte('date', dateTo.toIso8601String().split('T')[0]);
    }

    final response = await query
        .order('created_at', ascending: false)
        .limit(limit ?? 50)
        .range(offset ?? 0, (offset ?? 0) + (limit ?? 50) - 1);

    final data = response as List<dynamic>;
    return data
        .map<WorkPlanModel>((json) => WorkPlanModel.fromJson(
            _transformEmbedded(Map<String, dynamic>.from(json))))
        .toList();
  }

  @override
  Future<WorkPlanModel?> getWorkPlan(String id) async {
    final response = await client
        .from('work_plans')
        .select('id, created_at, updated_at, created_by, date, object_id, company_id, '
            'work_plan_blocks(id, system, section, floor, responsible_id, worker_ids, company_id, '
            'work_plan_items(estimate_id, name, unit, price, planned_quantity, actual_quantity, company_id))')
        .eq('id', id)
        .eq('company_id', activeCompanyId)
        .maybeSingle();

    if (response == null) return null;
    return WorkPlanModel.fromJson(
        _transformEmbedded(Map<String, dynamic>.from(response)));
  }

  @override
  Future<WorkPlanModel> createWorkPlan(WorkPlanModel workPlan) async {
    // 1) Вставляем базовую запись плана без JSON-поля work_blocks
    final baseInsert = {
      'created_by': workPlan.createdBy,
      'date': workPlan.date.toIso8601String().split('T')[0],
      'object_id': workPlan.objectId,
      'company_id': activeCompanyId,
    };

    final insertedPlan =
        await client.from('work_plans').insert(baseInsert).select().single();

    final planId = insertedPlan['id'] as String;

    try {
      // 2) Вставляем блоки
      for (final block in workPlan.workBlocks) {
        final blockInsert = {
          'work_plan_id': planId,
          'system': block.system,
          'section': block.section,
          'floor': block.floor,
          'responsible_id': block.responsibleId,
          'worker_ids': block.workerIds,
          'company_id': activeCompanyId,
        };

        final insertedBlock = await client
            .from('work_plan_blocks')
            .insert(blockInsert)
            .select()
            .single();

        final blockId = insertedBlock['id'] as String;

        if (block.selectedWorks.isEmpty) continue;

        // 3) Вставляем работы блоком
        final itemsInsert = block.selectedWorks.map((item) => {
              'block_id': blockId,
              'estimate_id': item.estimateId,
              'name': item.name,
              'unit': item.unit,
              'price': item.price,
              'planned_quantity': item.plannedQuantity,
              'actual_quantity': item.actualQuantity,
              'company_id': activeCompanyId,
            });

        await client.from('work_plan_items').insert(itemsInsert.toList());
      }
    } catch (e) {
      // При ошибке пробуем откатить созданный план
      try {
        await client
            .from('work_plans')
            .delete()
            .eq('id', planId)
            .eq('company_id', activeCompanyId);
      } catch (_) {}
      rethrow;
    }

    // Возвращаем доменную модель из объединённых таблиц
    final refreshed = await client
        .from('work_plans')
        .select('id, created_at, updated_at, created_by, date, object_id, company_id, '
            'work_plan_blocks(id, system, section, floor, responsible_id, worker_ids, company_id, '
            'work_plan_items(estimate_id, name, unit, price, planned_quantity, actual_quantity, company_id))')
        .eq('id', planId)
        .eq('company_id', activeCompanyId)
        .maybeSingle();
    return WorkPlanModel.fromJson(
        _transformEmbedded(Map<String, dynamic>.from(refreshed as Map)));
  }

  @override
  Future<WorkPlanModel> updateWorkPlan(WorkPlanModel workPlan) async {
    assert(
        workPlan.id != null, 'WorkPlan ID cannot be null for update operation');

    final planId = workPlan.id!;

    // 1) Обновляем базовые поля в work_plans
    final baseUpdate = {
      'date': workPlan.date.toIso8601String().split('T')[0],
      'object_id': workPlan.objectId,
    };

    await client
        .from('work_plans')
        .update(baseUpdate)
        .eq('id', planId)
        .eq('company_id', activeCompanyId);

    // 2) Пересоздаём блоки и их элементы (простая и надёжная стратегия)
    await client
        .from('work_plan_blocks')
        .delete()
        .eq('work_plan_id', planId)
        .eq('company_id', activeCompanyId);

    for (final block in workPlan.workBlocks) {
      final blockInsert = {
        'work_plan_id': planId,
        'system': block.system,
        'section': block.section,
        'floor': block.floor,
        'responsible_id': block.responsibleId,
        'worker_ids': block.workerIds,
        'company_id': activeCompanyId,
      };

      final insertedBlock = await client
          .from('work_plan_blocks')
          .insert(blockInsert)
          .select()
          .single();

      final blockId = insertedBlock['id'] as String;

      if (block.selectedWorks.isEmpty) continue;

      final itemsInsert = block.selectedWorks.map((item) => {
            'block_id': blockId,
            'estimate_id': item.estimateId,
            'name': item.name,
            'unit': item.unit,
            'price': item.price,
            'planned_quantity': item.plannedQuantity,
            'actual_quantity': item.actualQuantity,
            'company_id': activeCompanyId,
          });

      await client.from('work_plan_items').insert(itemsInsert.toList());
    }

    // 3) Возвращаем свежие данные из объединённых таблиц
    final refreshed = await client
        .from('work_plans')
        .select('id, created_at, updated_at, created_by, date, object_id, company_id, '
            'work_plan_blocks(id, system, section, floor, responsible_id, worker_ids, company_id, '
            'work_plan_items(estimate_id, name, unit, price, planned_quantity, actual_quantity, company_id))')
        .eq('id', planId)
        .eq('company_id', activeCompanyId)
        .maybeSingle();
    return WorkPlanModel.fromJson(
        _transformEmbedded(Map<String, dynamic>.from(refreshed as Map)));
  }

  @override
  Future<bool> deleteWorkPlan(String id) async {
    await client
        .from('work_plans')
        .delete()
        .eq('id', id)
        .eq('company_id', activeCompanyId);
    return true;
  }

  @override
  Future<List<WorkPlanModel>> getUserWorkPlans({
    int limit = 50,
    int offset = 0,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final query = client
        .from('work_plans')
        .select(
            'id, created_at, updated_at, created_by, date, object_id, company_id, '
            'work_plan_blocks(id, system, section, floor, responsible_id, worker_ids, company_id, '
            'work_plan_items(estimate_id, name, unit, price, planned_quantity, actual_quantity, company_id))')
        .eq('company_id', activeCompanyId);

    if (dateFrom != null) {
      query.gte('date', dateFrom.toIso8601String().split('T')[0]);
    }

    if (dateTo != null) {
      query.lte('date', dateTo.toIso8601String().split('T')[0]);
    }

    final response = await query
        .order('created_at', ascending: false)
        .limit(limit)
        .range(offset, offset + limit - 1);

    final data = response as List<dynamic>;
    return data
        .map<WorkPlanModel>((json) => WorkPlanModel.fromJson(
            _transformEmbedded(Map<String, dynamic>.from(json))))
        .toList();
  }

  @override
  Future<WorkPlanModel?> getWorkPlanDetails(String id) async {
    final response = await client
        .from('work_plans')
        .select('id, created_at, updated_at, created_by, date, object_id, company_id, '
            'work_plan_blocks(id, system, section, floor, responsible_id, worker_ids, company_id, '
            'work_plan_items(estimate_id, name, unit, price, planned_quantity, actual_quantity, company_id))')
        .eq('id', id)
        .eq('company_id', activeCompanyId)
        .maybeSingle();

    if (response == null) return null;
    return WorkPlanModel.fromJson(
        _transformEmbedded(Map<String, dynamic>.from(response)));
  }
}
