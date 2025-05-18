import '../entities/work_material.dart';

/// Абстрактный репозиторий для работы с материалами смены.
/// 
/// Определяет методы для получения, добавления, обновления и удаления материалов для конкретной смены.
abstract class WorkMaterialRepository {
  /// Возвращает список материалов для смены по идентификатору [workId].
  Future<List<WorkMaterial>> fetchWorkMaterials(String workId);

  /// Добавляет новый материал [material] в смену.
  Future<void> addWorkMaterial(WorkMaterial material);

  /// Обновляет материал [material] в смене.
  Future<void> updateWorkMaterial(WorkMaterial material);

  /// Удаляет материал по идентификатору [id].
  Future<void> deleteWorkMaterial(String id);
} 