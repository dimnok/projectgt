import 'package:projectgt/data/datasources/object_data_source.dart';
import 'package:projectgt/data/models/object_model.dart';
import 'package:projectgt/domain/entities/object.dart';
import 'package:projectgt/domain/repositories/object_repository.dart';

/// Имплементация [ObjectRepository] для работы с объектами через data source.
///
/// Инкапсулирует преобразование моделей и делегирует вызовы data-слою.
class ObjectRepositoryImpl implements ObjectRepository {
  /// Data source для работы с объектами.
  final ObjectDataSource dataSource;

  /// Создаёт [ObjectRepositoryImpl] с указанным [dataSource].
  ObjectRepositoryImpl(this.dataSource);

  @override
  Future<List<ObjectEntity>> getObjects() async {
    final models = await dataSource.getObjects();
    return models.map((m) => m.toDomain()).toList();
  }

  @override
  Future<ObjectEntity?> getObject(String id) async {
    final model = await dataSource.getObject(id);
    return model?.toDomain();
  }

  @override
  Future<ObjectEntity> createObject(ObjectEntity object) async {
    final model = await dataSource.createObject(ObjectModel.fromDomain(object));
    return model.toDomain();
  }

  @override
  Future<ObjectEntity> updateObject(ObjectEntity object) async {
    final model = await dataSource.updateObject(ObjectModel.fromDomain(object));
    return model.toDomain();
  }

  @override
  Future<void> deleteObject(String id) async {
    await dataSource.deleteObject(id);
  }
} 