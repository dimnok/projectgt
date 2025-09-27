import 'package:projectgt/domain/entities/object.dart';
import 'package:projectgt/domain/repositories/object_repository.dart';

/// UseCase для обновления данных объекта.
///
/// Используется для обновления информации об объекте через [ObjectRepository].
///
/// Пример использования:
/// ```dart
/// final useCase = UpdateObjectUseCase(objectRepository);
/// final updated = await useCase.execute(object.copyWith(name: 'Новое имя'));
/// ```
///
/// [object] — обновлённые данные объекта.
/// Возвращает обновлённый [ObjectEntity].
/// Бросает [Exception] при ошибке.
class UpdateObjectUseCase {
  /// Репозиторий объектов для обновления данных.
  final ObjectRepository repository;

  /// Создаёт use case с указанным репозиторием.
  UpdateObjectUseCase(this.repository);

  /// Обновление объекта.
  ///
  /// [object] — обновлённые данные объекта.
  /// Возвращает обновлённый [ObjectEntity].
  /// Бросает [Exception] при ошибке.
  Future<ObjectEntity> execute(ObjectEntity object) async {
    return repository.updateObject(object);
  }
}
