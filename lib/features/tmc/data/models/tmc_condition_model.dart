import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/features/tmc/domain/entities/tmc_condition.dart';

part 'tmc_condition_model.freezed.dart';
part 'tmc_condition_model.g.dart';

/// Модель состояния ТМЦ для Supabase.
@freezed
abstract class TmcConditionModel with _$TmcConditionModel {
  /// Создаёт модель.
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory TmcConditionModel({
    required String id,
    required String companyId,
    required String code,
    required String name,
    @Default(0) int sortOrder,
    @Default(false) bool isSystem,
    @Default(false) bool isArchived,
    DateTime? archivedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) = _TmcConditionModel;

  const TmcConditionModel._();

  /// JSON для записи в БД.
  @override
  Map<String, dynamic> toJson() =>
      _$TmcConditionModelToJson(this as _TmcConditionModel);

  /// Из JSON.
  factory TmcConditionModel.fromJson(Map<String, dynamic> json) =>
      _$TmcConditionModelFromJson(json);

  /// Из доменной сущности.
  factory TmcConditionModel.fromDomain(TmcCondition condition) =>
      TmcConditionModel(
        id: condition.id,
        companyId: condition.companyId,
        code: condition.code,
        name: condition.name,
        sortOrder: condition.sortOrder,
        isSystem: condition.isSystem,
        isArchived: condition.isArchived,
        archivedAt: condition.archivedAt,
        createdAt: condition.createdAt,
        updatedAt: condition.updatedAt,
        createdBy: condition.createdBy,
      );

  /// В доменную сущность.
  TmcCondition toDomain() => TmcCondition(
        id: id,
        companyId: companyId,
        code: code,
        name: name,
        sortOrder: sortOrder,
        isSystem: isSystem,
        isArchived: isArchived,
        archivedAt: archivedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
        createdBy: createdBy,
      );
}
