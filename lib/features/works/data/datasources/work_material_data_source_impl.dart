import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../models/work_material_model.dart';
import 'work_material_data_source.dart';

/// Реализация источника данных для работы с материалами смены через Supabase.
class WorkMaterialDataSourceImpl implements WorkMaterialDataSource {
  /// Клиент Supabase для доступа к базе данных.
  final SupabaseClient client;

  /// ID текущей активной компании для фильтрации данных (Multi-tenancy).
  final String activeCompanyId;

  /// Название таблицы материалов.
  static const String table = 'work_materials';

  /// Логгер для вывода ошибок.
  final Logger _logger = Logger();

  /// Создаёт источник данных для работы с материалами смены.
  WorkMaterialDataSourceImpl(this.client, this.activeCompanyId);

  /// Возвращает список материалов для смены по идентификатору [workId].
  @override
  Future<List<WorkMaterialModel>> fetchWorkMaterials(String workId) async {
    try {
      final response = await client
          .from(table)
          .select()
          .eq('work_id', workId)
          .eq('company_id', activeCompanyId)
          .order('created_at');

      return response
          .map<WorkMaterialModel>((json) => WorkMaterialModel.fromJson(json))
          .toList();
    } catch (e) {
      _logger.e('Ошибка получения списка материалов: $e');
      rethrow;
    }
  }

  /// Добавляет новый материал [material] в смену.
  @override
  Future<void> addWorkMaterial(WorkMaterialModel material) async {
    try {
      final now = DateTime.now().toIso8601String();
      final materialJson = material.toJson();
      materialJson['created_at'] = now;
      materialJson['updated_at'] = now;
      materialJson['company_id'] = activeCompanyId;

      await client.from(table).insert(materialJson);
    } catch (e) {
      _logger.e('Ошибка добавления материала: $e');
      rethrow;
    }
  }

  /// Обновляет материал [material] в смене.
  @override
  Future<void> updateWorkMaterial(WorkMaterialModel material) async {
    try {
      final now = DateTime.now().toIso8601String();
      final materialJson = material.toJson();
      materialJson['updated_at'] = now;
      materialJson['company_id'] = activeCompanyId;

      await client
          .from(table)
          .update(materialJson)
          .eq('id', material.id)
          .eq('company_id', activeCompanyId);
    } catch (e) {
      _logger.e('Ошибка обновления материала: $e');
      rethrow;
    }
  }

  /// Удаляет материал по идентификатору [id].
  @override
  Future<void> deleteWorkMaterial(String id) async {
    try {
      await client
          .from(table)
          .delete()
          .eq('id', id)
          .eq('company_id', activeCompanyId);
    } catch (e) {
      _logger.e('Ошибка удаления материала: $e');
      rethrow;
    }
  }
}
