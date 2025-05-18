import '../models/work_material_model.dart';

/// Абстрактный источник данных для работы с материалами смены.
///
/// Определяет методы для получения, добавления, обновления и удаления материалов для конкретной смены.
abstract class WorkMaterialDataSource {
  /// Возвращает список материалов для смены по идентификатору [workId].
  Future<List<WorkMaterialModel>> fetchWorkMaterials(String workId);

  /// Добавляет новый материал [material] в смену.
  Future<void> addWorkMaterial(WorkMaterialModel material);

  /// Обновляет материал [material] в смене.
  Future<void> updateWorkMaterial(WorkMaterialModel material);

  /// Удаляет материал по идентификатору [id].
  Future<void> deleteWorkMaterial(String id);
} 