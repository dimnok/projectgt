import 'package:projectgt/domain/entities/object.dart';
import 'package:projectgt/domain/repositories/object_repository.dart';

/// UseCase для создания нового объекта.
///
/// Используется для добавления объекта через [ObjectRepository].
///
/// Пример использования:
/// ```dart
/// final useCase = CreateObjectUseCase(objectRepository);
/// final object = await useCase.execute(object);
/// ```
///
/// [object] — данные объекта.
/// Возвращает созданный [ObjectEntity].
/// Бросает [Exception] при ошибке.
class CreateObjectUseCase {
  /// Репозиторий объектов для создания данных.
  final ObjectRepository repository;

  /// Создаёт use case с указанным репозиторием.
  CreateObjectUseCase(this.repository);

  /// Создание нового объекта.
  ///
  /// [object] — данные объекта.
  /// Возвращает созданный [ObjectEntity].
  /// Бросает [Exception] при ошибке.
  Future<ObjectEntity> execute(ObjectEntity object) async {
    return repository.createObject(object);
  }
}
