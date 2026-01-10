import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projectgt/features/objects/data/models/object_model.dart';

/// Абстракция источника данных для работы с объектами [ObjectModel].
/// Определяет базовые CRUD-операции для реализации в конкретных источниках (например, Supabase).
abstract class ObjectDataSource {
  /// Получить список всех объектов.
  ///
  /// Возвращает [List<ObjectModel>].
  /// Может выбросить исключение при ошибке доступа к данным.
  Future<List<ObjectModel>> getObjects();

  /// Получить объект по идентификатору [id].
  ///
  /// [id] — уникальный идентификатор объекта.
  /// Возвращает [ObjectModel], либо `null`, если объект не найден.
  /// Может выбросить исключение при ошибке доступа к данным.
  Future<ObjectModel?> getObject(String id);

  /// Создать новый объект.
  ///
  /// [object] — данные нового объекта.
  /// Возвращает созданный [ObjectModel] с присвоенным идентификатором.
  /// Может выбросить исключение, если объект не удалось создать.
  Future<ObjectModel> createObject(ObjectModel object);

  /// Обновить существующий объект.
  ///
  /// [object] — объект с обновлёнными данными (id обязателен).
  /// Возвращает обновлённый [ObjectModel].
  /// Может выбросить исключение, если объект не найден или не удалось обновить.
  Future<ObjectModel> updateObject(ObjectModel object);

  /// Удалить объект по идентификатору [id].
  ///
  /// [id] — уникальный идентификатор объекта.
  /// Возвращает `true`, если объект успешно удалён, иначе `false`.
  /// Может выбросить исключение при ошибке доступа к данным.
  Future<bool> deleteObject(String id);
}

/// Реализация [ObjectDataSource] для Supabase.
/// Использует [SupabaseClient] для взаимодействия с таблицей объектов.
class SupabaseObjectDataSource implements ObjectDataSource {
  /// Клиент Supabase для работы с БД.
  final SupabaseClient client;

  /// ID текущей активной компании для фильтрации данных.
  final String activeCompanyId;

  /// Создаёт экземпляр с переданным [client] и [activeCompanyId].
  SupabaseObjectDataSource(this.client, this.activeCompanyId);

  @override
  Future<List<ObjectModel>> getObjects() async {
    final response = await client
        .from('objects')
        .select('*')
        .eq('company_id', activeCompanyId)
        .order('name');
    return response
        .map<ObjectModel>((json) => ObjectModel.fromJson(json))
        .toList();
  }

  @override
  Future<ObjectModel?> getObject(String id) async {
    final response = await client
        .from('objects')
        .select('*')
        .eq('id', id)
        .eq('company_id', activeCompanyId)
        .maybeSingle();
    if (response == null) return null;
    return ObjectModel.fromJson(response);
  }

  @override
  Future<ObjectModel> createObject(ObjectModel object) async {
    final response = await client
        .from('objects')
        .insert(object.toJson())
        .select()
        .maybeSingle();
    if (response == null) {
      throw Exception('Ошибка создания объекта');
    }
    return ObjectModel.fromJson(response);
  }

  @override
  Future<ObjectModel> updateObject(ObjectModel object) async {
    final response = await client
        .from('objects')
        .update(object.toJson())
        .eq('id', object.id)
        .eq('company_id', activeCompanyId)
        .select()
        .maybeSingle();
    if (response == null) {
      throw Exception('Объект не найден для обновления');
    }
    return ObjectModel.fromJson(response);
  }

  @override
  Future<bool> deleteObject(String id) async {
    await client
        .from('objects')
        .delete()
        .eq('id', id)
        .eq('company_id', activeCompanyId);
    return true;
  }
}
