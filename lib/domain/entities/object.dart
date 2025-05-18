import 'package:freezed_annotation/freezed_annotation.dart';

part 'object.freezed.dart';

/// Сущность "Объект" (доменная модель).
///
/// Описывает строительный или иной объект, используемый в системе.
@freezed
abstract class ObjectEntity with _$ObjectEntity {
  /// Основной конструктор [ObjectEntity].
  ///
  /// Все параметры соответствуют полям объекта в базе данных.
  const factory ObjectEntity({
    /// Уникальный идентификатор объекта.
    required String id,
    /// Название объекта.
    required String name,
    /// Адрес объекта.
    required String address,
    /// Описание объекта.
    String? description,
    /// Сумма командировочных выплат для объекта
    @Default(0) num businessTripAmount,
  }) = _ObjectEntity;

  /// Приватный конструктор для расширения функциональности через методы.
  const ObjectEntity._();
} 