import 'package:freezed_annotation/freezed_annotation.dart';

part 'work_item_model.freezed.dart';
part 'work_item_model.g.dart';

/// Data-модель работы в смене для хранения и передачи данных между слоями data и источником данных.
@freezed
abstract class WorkItemModel with _$WorkItemModel {
  /// Создаёт data-модель работы в смене.
  ///
  /// [id] — идентификатор работы
  /// [workId] — идентификатор смены
  /// [section] — секция
  /// [floor] — этаж
  /// [estimateId] — идентификатор сметы
  /// [name] — наименование работы
  /// [system] — система
  /// [subsystem] — подсистема
  /// [unit] — единица измерения
  /// [quantity] — объём/количество
  /// [price] — цена за единицу (опционально)
  /// [total] — итоговая сумма (опционально)
  /// [createdAt] — дата создания записи (опционально)
  /// [updatedAt] — дата последнего обновления (опционально)
  const factory WorkItemModel({
    /// Идентификатор работы.
    required String id,
    /// Идентификатор смены.
    @JsonKey(name: 'work_id') required String workId,
    /// Секция.
    required String section,
    /// Этаж.
    required String floor,
    /// Идентификатор сметы.
    @JsonKey(name: 'estimate_id') required String estimateId,
    /// Наименование работы.
    required String name,
    /// Система.
    required String system,
    /// Подсистема.
    required String subsystem,
    /// Единица измерения.
    required String unit,
    /// Объём/количество.
    required num quantity,
    /// Цена за единицу.
    double? price,
    /// Итоговая сумма.
    double? total,
    /// Дата создания записи.
    @JsonKey(name: 'created_at') DateTime? createdAt,
    /// Дата последнего обновления.
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _WorkItemModel;

  /// Создаёт data-модель работы в смене из JSON.
  factory WorkItemModel.fromJson(Map<String, dynamic> json) => _$WorkItemModelFromJson(json);
} 