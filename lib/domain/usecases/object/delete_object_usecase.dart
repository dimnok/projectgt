import 'package:projectgt/domain/repositories/object_repository.dart';

/// UseCase для удаления объекта по идентификатору.
///
/// Используется для удаления объекта по id через [ObjectRepository].
///
/// Пример использования:
/// ```dart
/// final useCase = DeleteObjectUseCase(objectRepository);
/// await useCase.execute('objectId');
/// ```
///
/// [id] — идентификатор объекта.
/// Возвращает void.
/// Бросает [Exception] при ошибке.
class DeleteObjectUseCase {
  /// Репозиторий объектов для удаления данных.
  final ObjectRepository repository;

  /// Создаёт use case с указанным репозиторием.
  DeleteObjectUseCase(this.repository);

  /// Удаление объекта по id.
  ///
  /// [id] — идентификатор объекта.
  /// Возвращает void.
  /// Бросает [Exception] при ошибке.
  Future<void> execute(String id) async {
    return repository.deleteObject(id);
  }
} 