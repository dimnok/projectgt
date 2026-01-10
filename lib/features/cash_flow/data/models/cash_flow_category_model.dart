import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/features/cash_flow/domain/entities/cash_flow_category.dart';

part 'cash_flow_category_model.freezed.dart';
part 'cash_flow_category_model.g.dart';

/// Модель данных статьи ДДС для Supabase.
@freezed
abstract class CashFlowCategoryModel with _$CashFlowCategoryModel {
  /// Конструктор для создания модели статьи ДДС.
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory CashFlowCategoryModel({
    required String id,
    required String companyId,
    required String name,
    required CashFlowOperationType type,
    DateTime? createdAt,
  }) = _CashFlowCategoryModel;

  const CashFlowCategoryModel._();

  /// Преобразует модель в JSON для сохранения в БД.
  @override
  Map<String, dynamic> toJson() =>
      _$CashFlowCategoryModelToJson(this as _CashFlowCategoryModel);

  /// Создаёт модель из JSON.
  factory CashFlowCategoryModel.fromJson(Map<String, dynamic> json) =>
      _$CashFlowCategoryModelFromJson(json);

  /// Создаёт модель на основе доменной сущности [CashFlowCategory].
  factory CashFlowCategoryModel.fromDomain(CashFlowCategory category) =>
      CashFlowCategoryModel(
        id: category.id,
        companyId: category.companyId,
        name: category.name,
        type: category.type,
        createdAt: category.createdAt,
      );

  /// Преобразует модель в доменную сущность [CashFlowCategory].
  CashFlowCategory toDomain() => CashFlowCategory(
        id: id,
        companyId: companyId,
        name: name,
        type: type,
        createdAt: createdAt,
      );
}
