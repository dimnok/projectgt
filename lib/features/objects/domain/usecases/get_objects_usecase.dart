import 'package:projectgt/features/objects/domain/entities/object.dart';
import 'package:projectgt/features/objects/domain/repositories/object_repository.dart';

/// UseCase для получения списка всех объектов.
///
/// Используется для загрузки списка объектов через [ObjectRepository].
///
/// Пример использования:
/// ```dart
/// final useCase = GetObjectsUseCase(objectRepository);
/// final objects = await useCase.execute();
/// print(objects.length);
/// ```
///
/// Возвращает список [ObjectEntity].
/// Бросает [Exception] при ошибке.
class GetObjectsUseCase {
  /// Репозиторий объектов для получения данных.
  final ObjectRepository repository;

  /// Создаёт use case с указанным репозиторием.
  GetObjectsUseCase(this.repository);

  /// Получение списка всех объектов.
  ///
  /// Возвращает список [ObjectEntity].
  /// Бросает [Exception] при ошибке.
  Future<List<ObjectEntity>> execute() async {
    return repository.getObjects();
  }
}
