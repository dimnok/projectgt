import 'package:freezed_annotation/freezed_annotation.dart';

part 'grouped_material_item.freezed.dart';
part 'grouped_material_item.g.dart';

/// Модель сгруппированного материала по смете.
@freezed
abstract class GroupedMaterialItem with _$GroupedMaterialItem {
  /// Основной конструктор [GroupedMaterialItem].
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory GroupedMaterialItem({
    /// ID сметной позиции
    required String estimateId,

    /// Каноническое наименование из сметы
    required String estimateName,

    /// Единица измерения из сметы
    required String estimateUnit,

    /// Система (ЭО1, СС и т.д.)
    required String system,

    /// Номер договора
    required String contractNumber,

    /// ID компании
    required String companyId,

    /// Общий приход (в единицах сметы)
    required double totalIncoming,

    /// Общий расход (в единицах сметы)
    required double totalUsed,

    /// Общий остаток (в единицах сметы)
    required double totalRemaining,

    /// Количество партий (накладных)
    required int batchCount,
  }) = _GroupedMaterialItem;

  /// Создаёт [GroupedMaterialItem] из JSON.
  factory GroupedMaterialItem.fromJson(Map<String, dynamic> json) =>
      _$GroupedMaterialItemFromJson(json);
}
