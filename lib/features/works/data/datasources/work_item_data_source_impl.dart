import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/work_item_model.dart';
import 'work_item_data_source.dart';
import 'dart:async';

/// Реализация источника данных для работы с работами в смене через Supabase.
class WorkItemDataSourceImpl implements WorkItemDataSource {
  /// Клиент Supabase для доступа к базе данных.
  final SupabaseClient client;

  /// Название таблицы работ.
  static const String table = 'work_items';

  /// Логгер удалён.

  /// Создаёт источник данных для работы с работами в смене.
  WorkItemDataSourceImpl(this.client);

  /// Возвращает список работ для смены по идентификатору [workId].
  @override
  Future<List<WorkItemModel>> fetchWorkItems(String workId) async {
    if (workId.isEmpty) {
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
          rethrow;
        }
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Добавляет новую работу [item] в смену.
  @override
  Future<void> addWorkItem(WorkItemModel item) async {
    try {
      if (item.workId.isEmpty) {
        throw ArgumentError('workId не может быть пустым');
      }
      final now = DateTime.now().toIso8601String();
      final itemJson = item.toJson();
      itemJson['created_at'] = now;
      itemJson['updated_at'] = now;
      await client.from(table).insert(itemJson);
    } catch (e) {
      rethrow;
    }
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

      await client.from(table).update(itemJson).eq('id', item.id);
    } catch (e) {
      rethrow;
    }
  }

  /// Удаляет работу по идентификатору [id].
  @override
  Future<void> deleteWorkItem(String id) async {
    try {
      await client.from(table).delete().eq('id', id);
    } catch (e) {
      rethrow;
    }
  }

  /// Возвращает список всех работ из всех смен.
  @override
  Future<List<WorkItemModel>> getAllWorkItems() async {
    try {
      final response = await client.from(table).select().order('created_at');
      return response.map<WorkItemModel>((json) {
        try {
          return WorkItemModel.fromJson(json);
        } catch (e) {
          rethrow;
        }
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Реалтайм-подписка на изменения работ конкретной смены
  @override
  Stream<List<WorkItemModel>> watchWorkItems(String workId) async* {
    final controller = StreamController<List<WorkItemModel>>();
    if (workId.isEmpty) {
      controller.add(const []);
      yield* controller.stream;
      return;
    }

    List<WorkItemModel> current = [];

    Future<void> syncInitial() async {
      try {
        current = await fetchWorkItems(workId);
        if (!controller.isClosed) controller.add(current);
      } catch (e, st) {
        if (!controller.isClosed) controller.addError(e, st);
      }
    }

    // Отдаём начальные данные после подписки клиента на поток
    // (задержка позволяет подписчику успеть прикрепиться)
    () async {
      await syncInitial();
    }();

    // Топик канала без параметров фильтра — фильтр задаем в onPostgresChanges
    final channel = client.channel('public:work_items')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        // В supabase_flutter >=2.6.0 filter принимает PostgresChangeFilter
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'work_id',
          value: workId,
        ),
        callback: (payload) async {
          try {
            final Map<String, dynamic>? newRecord =
                payload.newRecord as Map<String, dynamic>?;
            final Map<String, dynamic>? oldRecord =
                payload.oldRecord as Map<String, dynamic>?;
            final event = payload.eventType;
            final dynamic idValue =
                newRecord != null ? newRecord['id'] : oldRecord?['id'];
            final String? id =
                idValue is String ? idValue : idValue?.toString();

            WorkItemModel? nextModel;
            if (newRecord != null) {
              nextModel = WorkItemModel.fromJson(newRecord);
            }

            switch (event) {
              case PostgresChangeEvent.insert:
                if (nextModel != null) {
                  current = [...current, nextModel];
                }
                break;
              case PostgresChangeEvent.update:
                if (nextModel != null && id != null) {
                  current = current
                      .map((item) => item.id == id ? nextModel! : item)
                      .toList();
                }
                break;
              case PostgresChangeEvent.delete:
                if (id != null) {
                  current = current.where((item) => item.id != id).toList();
                }
                break;
              default:
                await syncInitial();
            }

            if (!controller.isClosed) controller.add(current);
          } catch (_) {
            // При ошибке парсинга делаем полную синхронизацию
            await syncInitial();
          }
        },
      )
      ..subscribe();

    controller.onCancel = () async {
      try {
        await channel.unsubscribe();
      } catch (_) {
        // Намеренно игнорируем ошибки отписки
      }
      try {
        await client.removeChannel(channel);
      } catch (_) {
        // Намеренно игнорируем ошибки удаления канала
      }
      await controller.close();
    };

    yield* controller.stream;
  }
}
