import 'package:freezed_annotation/freezed_annotation.dart';

part 'work_material_model.freezed.dart';
part 'work_material_model.g.dart';

/// Data-модель материала смены для хранения и передачи данных между слоями data и источником данных.
@freezed
abstract class WorkMaterialModel with _$WorkMaterialModel {
  /// Создаёт data-модель материала смены.
  ///
  /// [id] — идентификатор материала
  /// [workId] — идентификатор смены
  /// [name] — наименование материала
  /// [unit] — единица измерения
  /// [quantity] — количество
  /// [comment] — комментарий (опционально)
  /// [createdAt] — дата создания записи (опционально)
  /// [updatedAt] — дата последнего обновления (опционально)
  const factory WorkMaterialModel({
    /// Идентификатор материала.
    required String id,

    /// Идентификатор смены.
    @JsonKey(name: 'work_id') required String workId,

    /// Наименование материала.
    required String name,

    /// Единица измерения.
    required String unit,

    /// Количество.
    required num quantity,

    /// Комментарий к материалу.
    String? comment,

    /// Дата создания записи.
    @JsonKey(name: 'created_at') DateTime? createdAt,

    /// Дата последнего обновления.
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _WorkMaterialModel;

  /// Создаёт data-модель материала смены из JSON.
  factory WorkMaterialModel.fromJson(Map<String, dynamic> json) =>
      _$WorkMaterialModelFromJson(json);
}
