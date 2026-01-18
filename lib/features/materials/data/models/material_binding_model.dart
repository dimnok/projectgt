import 'package:freezed_annotation/freezed_annotation.dart';

part 'material_binding_model.freezed.dart';
part 'material_binding_model.g.dart';

/// Перечисление возможных статусов привязки материала.
enum MaterialBindingStatus {
  /// Материал свободен для привязки.
  @JsonValue('available')
  available,

  /// Материал уже привязан к текущей сметной позиции.
  @JsonValue('current')
  current,

  /// Материал занят другой сметной позицией в рамках договора.
  @JsonValue('conflict')
  conflict,
}

/// Модель материала с информацией о его статусе привязки к смете.
/// Используется в окне выбора материала из накладных.
@freezed
abstract class MaterialBindingModel with _$MaterialBindingModel {
  /// Основной конструктор [MaterialBindingModel].
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory MaterialBindingModel({
    /// Наименование материала из накладной
    required String name,

    /// Единица измерения из накладной
    String? unit,

    /// Номер накладной
    String? receiptNumber,

    /// Текущий статус привязки в рамках договора
    required MaterialBindingStatus bindingStatus,

    /// Название сметной позиции, к которой уже привязан материал (при конфликте)
    String? linkedEstimateName,

    /// ID сметной позиции, к которой уже привязан материал
    String? linkedEstimateId,

    /// ID записи в material_aliases (если привязан)
    String? aliasId,
  }) = _MaterialBindingModel;

  /// Создаёт [MaterialBindingModel] из JSON.
  factory MaterialBindingModel.fromJson(Map<String, dynamic> json) =>
      _$MaterialBindingModelFromJson(json);
}
