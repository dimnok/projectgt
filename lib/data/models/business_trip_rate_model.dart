import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/domain/entities/business_trip_rate.dart';

part 'business_trip_rate_model.freezed.dart';
part 'business_trip_rate_model.g.dart';

/// Модель ставки командировочных выплат для слоя data.
///
/// Используется для сериализации/десериализации данных из/в Supabase
/// и преобразования в доменную сущность [BusinessTripRate].
///
/// Пример использования:
/// ```dart
/// final rate = BusinessTripRateModel(
///   id: '1',
///   objectId: 'object-1',
///   rate: 1500.0,
///   validFrom: DateTime(2025, 1, 1),
///   validTo: DateTime(2025, 12, 31),
/// );
/// ```
@freezed
abstract class BusinessTripRateModel with _$BusinessTripRateModel {
  /// Конструктор для создания [BusinessTripRateModel].
  ///
  /// - [id] — уникальный идентификатор ставки.
  /// - [objectId] — идентификатор объекта.
  /// - [employeeId] — идентификатор сотрудника (опционально).
  /// - [rate] — размер ставки командировочных за смену.
  /// - [minimumHours] — минимальное количество часов для начисления.
  /// - [validFrom] — дата начала действия ставки.
  /// - [validTo] — дата окончания действия ставки (опционально).
  /// - [createdAt] — дата создания записи (опционально).
  /// - [updatedAt] — дата обновления записи (опционально).
  /// - [createdBy] — создатель записи (опционально).
  @JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
  const factory BusinessTripRateModel({
    required String id,
    required String objectId,
    String? employeeId,
    required double rate,
    @Default(0.0) double minimumHours,
    required DateTime validFrom,
    DateTime? validTo,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) = _BusinessTripRateModel;

  /// Приватный конструктор для поддержки расширения через [freezed].
  const BusinessTripRateModel._();

  /// Создаёт [BusinessTripRateModel] из JSON.
  ///
  /// [json] — карта с данными ставки командировочных.
  /// Возвращает экземпляр [BusinessTripRateModel].
  ///
  /// Пример:
  /// ```dart
  /// final model = BusinessTripRateModel.fromJson(jsonMap);
  /// ```
  factory BusinessTripRateModel.fromJson(Map<String, dynamic> json) =>
      _$BusinessTripRateModelFromJson(json);

  /// Создаёт [BusinessTripRateModel] из доменной сущности [BusinessTripRate].
  ///
  /// [rate] — доменная сущность ставки командировочных.
  /// Возвращает экземпляр [BusinessTripRateModel].
  factory BusinessTripRateModel.fromDomain(BusinessTripRate rate) =>
      BusinessTripRateModel(
        id: rate.id,
        objectId: rate.objectId,
        employeeId: rate.employeeId,
        rate: rate.rate,
        minimumHours: rate.minimumHours,
        validFrom: rate.validFrom,
        validTo: rate.validTo,
        createdAt: rate.createdAt,
        updatedAt: rate.updatedAt,
        createdBy: rate.createdBy,
      );

  /// Преобразует [BusinessTripRateModel] в доменную сущность [BusinessTripRate].
  ///
  /// Возвращает [BusinessTripRate] с соответствующими полями.
  BusinessTripRate toDomain() => BusinessTripRate(
        id: id,
        objectId: objectId,
        employeeId: employeeId,
        rate: rate,
        minimumHours: minimumHours,
        validFrom: validFrom,
        validTo: validTo,
        createdAt: createdAt,
        updatedAt: updatedAt,
        createdBy: createdBy,
      );
}
