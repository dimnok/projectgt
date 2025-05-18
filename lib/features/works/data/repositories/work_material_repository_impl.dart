import '../../domain/entities/work_material.dart';
import '../../domain/repositories/work_material_repository.dart';
import '../datasources/work_material_data_source.dart';
import '../models/work_material_model.dart';

/// Реализация репозитория для работы с материалами смены через источник данных [WorkMaterialDataSource].
class WorkMaterialRepositoryImpl implements WorkMaterialRepository {
  /// Источник данных для материалов смены.
  final WorkMaterialDataSource dataSource;

  /// Создаёт репозиторий для работы с материалами смены.
  WorkMaterialRepositoryImpl(this.dataSource);

  /// Возвращает список материалов для смены по идентификатору [workId].
  @override
  Future<List<WorkMaterial>> fetchWorkMaterials(String workId) async {
    final models = await dataSource.fetchWorkMaterials(workId);
    return models.map((e) => WorkMaterial.fromJson(e.toJson())).toList();
  }

  /// Добавляет новый материал [material] в смену.
  @override
  Future<void> addWorkMaterial(WorkMaterial material) async {
    await dataSource.addWorkMaterial(WorkMaterialModel.fromJson(material.toJson()));
  }

  /// Обновляет материал [material] в смене.
  @override
  Future<void> updateWorkMaterial(WorkMaterial material) async {
    await dataSource.updateWorkMaterial(WorkMaterialModel.fromJson(material.toJson()));
  }

  /// Удаляет материал по идентификатору [id].
  @override
  Future<void> deleteWorkMaterial(String id) async {
    await dataSource.deleteWorkMaterial(id);
  }
} 