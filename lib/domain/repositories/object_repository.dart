import 'package:projectgt/domain/entities/object.dart';

/// Абстракция репозитория для работы с объектами.
abstract class ObjectRepository {
  /// Получи список всех объектов.
  ///
  /// Возвращает список [ObjectEntity]. Бросает [Exception] при ошибке.
  Future<List<ObjectEntity>> getObjects();

  /// Получи объект по [id].
  ///
  /// Возвращает [ObjectEntity] или null, если не найден. Бросает [Exception] при ошибке.
  Future<ObjectEntity?> getObject(String id);

  /// Создай новый объект [object] в источнике данных.
  ///
  /// Возвращает созданный [ObjectEntity]. Бросает [Exception] при ошибке.
  Future<ObjectEntity> createObject(ObjectEntity object);

  /// Обнови объект [object] в источнике данных.
  ///
  /// Возвращает обновлённый [ObjectEntity]. Бросает [Exception] при ошибке.
  Future<ObjectEntity> updateObject(ObjectEntity object);

  /// Удали объект по [id].
  ///
  /// Возвращает void. Бросает [Exception] при ошибке.
  Future<void> deleteObject(String id);
} 