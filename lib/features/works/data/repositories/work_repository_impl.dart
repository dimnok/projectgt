import '../../domain/entities/work.dart';
import '../../domain/repositories/work_repository.dart';
import '../datasources/work_data_source.dart';
import '../models/work_model.dart';

/// Реализация репозитория для работы со сменами через источник данных [WorkDataSource].
class WorkRepositoryImpl implements WorkRepository {
  /// Источник данных для смен.
  final WorkDataSource dataSource;

  /// Создаёт репозиторий для работы со сменами.
  WorkRepositoryImpl(this.dataSource);

  /// Возвращает список всех смен.
  @override
  Future<List<Work>> getWorks() async {
    final models = await dataSource.getWorks();
    return models.map(_mapToEntity).toList();
  }

  /// Возвращает смену по идентификатору [id].
  @override
  Future<Work?> getWork(String id) async {
    final model = await dataSource.getWork(id);
    return model != null ? _mapToEntity(model) : null;
  }

  /// Добавляет новую смену [work] и возвращает созданную сущность.
  @override
  Future<Work> addWork(Work work) async {
    final model = WorkModel(
      id: null,
      date: work.date,
      objectId: work.objectId,
      openedBy: work.openedBy,
      status: work.status,
      photoUrl: work.photoUrl,
      eveningPhotoUrl: work.eveningPhotoUrl,
      createdAt: work.createdAt,
      updatedAt: work.updatedAt,
    );
    final result = await dataSource.addWork(model);
    return _mapToEntity(result);
  }

  /// Обновляет данные смены [work] и возвращает обновлённую сущность.
  @override
  Future<Work> updateWork(Work work) async {
    final model = WorkModel(
      id: work.id,
      date: work.date,
      objectId: work.objectId,
      openedBy: work.openedBy,
      status: work.status,
      photoUrl: work.photoUrl,
      eveningPhotoUrl: work.eveningPhotoUrl,
      createdAt: work.createdAt,
      updatedAt: work.updatedAt,
    );
    final result = await dataSource.updateWork(model);
    return _mapToEntity(result);
  }

  /// Удаляет смену по идентификатору [id].
  @override
  Future<void> deleteWork(String id) async {
    await dataSource.deleteWork(id);
  }

  /// Преобразует модель смены [WorkModel] в доменную сущность [Work].
  Work _mapToEntity(WorkModel model) {
    return Work(
      id: model.id,
      date: model.date,
      objectId: model.objectId,
      openedBy: model.openedBy,
      status: model.status,
      photoUrl: model.photoUrl,
      eveningPhotoUrl: model.eveningPhotoUrl,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }
} 