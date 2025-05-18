import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/domain/entities/object.dart';

part 'object_model.freezed.dart';
part 'object_model.g.dart';

/// Модель объекта недвижимости для слоя data.
/// 
/// Используется для сериализации/десериализации данных из/в Supabase и преобразования в доменную сущность [ObjectEntity].
/// 
/// Пример использования:
/// ```dart
/// final object = ObjectModel(
///   id: '1',
///   name: 'Офис',
///   address: 'ул. Ленина, 1',
///   description: 'Главный офис компании',
/// );
/// ```
@freezed
abstract class ObjectModel with _$ObjectModel {
  /// Конструктор для создания [ObjectModel].
  ///
  /// - [id] — уникальный идентификатор объекта.
  /// - [name] — название объекта.
  /// - [address] — адрес объекта.
  /// - [description] — дополнительное описание (опционально).
  ///
  /// Все поля, кроме [description], обязательны.
  @JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
  const factory ObjectModel({
    required String id,
    required String name,
    required String address,
    String? description,
    /// Сумма командировочных выплат для объекта
    @Default(0) num businessTripAmount,
  }) = _ObjectModel;

  /// Приватный конструктор для поддержки расширения через [freezed].
  const ObjectModel._();

  /// Создаёт [ObjectModel] из JSON.
  ///
  /// [json] — карта с данными объекта.
  /// Возвращает экземпляр [ObjectModel].
  ///
  /// Пример:
  /// ```dart
  /// final model = ObjectModel.fromJson(jsonMap);
  /// ```
  factory ObjectModel.fromJson(Map<String, dynamic> json) => _$ObjectModelFromJson(json);

  /// Создаёт [ObjectModel] из доменной сущности [ObjectEntity].
  ///
  /// [object] — доменная сущность объекта.
  /// Возвращает экземпляр [ObjectModel].
  factory ObjectModel.fromDomain(ObjectEntity object) => ObjectModel(
        id: object.id,
        name: object.name,
        address: object.address,
        description: object.description,
        businessTripAmount: object.businessTripAmount,
      );
  
  /// Преобразует [ObjectModel] в доменную сущность [ObjectEntity].
  ///
  /// Возвращает [ObjectEntity] с соответствующими полями.
  ObjectEntity toDomain() => ObjectEntity(
        id: id,
        name: name,
        address: address,
        description: description,
        businessTripAmount: businessTripAmount,
      );
} 