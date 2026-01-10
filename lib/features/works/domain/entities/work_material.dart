import 'package:freezed_annotation/freezed_annotation.dart';

part 'work_material.freezed.dart';
part 'work_material.g.dart';

/// Сущность "Материал смены".
///
/// Описывает материал, используемый в рамках конкретной смены.
@freezed
abstract class WorkMaterial with _$WorkMaterial {
  /// Создаёт сущность материала смены.
  ///
  /// [id] — идентификатор материала
  /// [workId] — идентификатор смены
  /// [name] — наименование материала
  /// [unit] — единица измерения
  /// [quantity] — количество
  /// [comment] — комментарий (опционально)
  /// [createdAt] — дата создания записи (опционально)
  /// [updatedAt] — дата последнего обновления (опционально)
  const factory WorkMaterial({
    /// Идентификатор материала.
    required String id,

    /// Идентификатор компании.
    required String companyId,

    /// Идентификатор смены.
    required String workId,

    /// Наименование материала.
    required String name,

    /// Единица измерения.
    required String unit,

    /// Количество.
    required num quantity,

    /// Комментарий к материалу.
    String? comment,

    /// Дата создания записи.
    DateTime? createdAt,

    /// Дата последнего обновления.
    DateTime? updatedAt,
  }) = _WorkMaterial;

  /// Создаёт сущность из JSON.
  factory WorkMaterial.fromJson(Map<String, dynamic> json) =>
      _$WorkMaterialFromJson(json);
}
