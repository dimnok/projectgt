import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/features/cash_flow/domain/entities/cash_flow_category.dart';
import 'package:projectgt/features/cash_flow/domain/entities/cash_flow_category_rule.dart';

part 'cash_flow_category_rule_model.freezed.dart';
part 'cash_flow_category_rule_model.g.dart';

/// Модель правила автосопоставления категории ДДС для Supabase.
@freezed
abstract class CashFlowCategoryRuleModel with _$CashFlowCategoryRuleModel {
  /// Создаёт [CashFlowCategoryRuleModel].
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory CashFlowCategoryRuleModel({
    required String id,
    required String companyId,
    required String categoryId,
    required String keyword,
    required CashFlowOperationType operationType,
    @Default(0) int priority,
    @Default(true) bool requiresContractBinding,
    DateTime? createdAt,
    @JsonKey(includeToJson: false) String? categoryName,
  }) = _CashFlowCategoryRuleModel;

  const CashFlowCategoryRuleModel._();

  /// Преобразует модель в JSON для сохранения в БД.
  Map<String, dynamic> toJson() =>
      _$CashFlowCategoryRuleModelToJson(this as _CashFlowCategoryRuleModel);

  /// Создаёт модель из JSON.
  factory CashFlowCategoryRuleModel.fromJson(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    map['category_name'] = json['cash_flow_categories']?['name'];
    return _$CashFlowCategoryRuleModelFromJson(map);
  }

  /// Создаёт модель из доменной сущности.
  factory CashFlowCategoryRuleModel.fromDomain(CashFlowCategoryRule rule) =>
      CashFlowCategoryRuleModel(
        id: rule.id,
        companyId: rule.companyId,
        categoryId: rule.categoryId,
        keyword: rule.keyword,
        operationType: rule.operationType,
        priority: rule.priority,
        requiresContractBinding: rule.requiresContractBinding,
        createdAt: rule.createdAt,
        categoryName: rule.categoryName,
      );

  /// Преобразует в доменную сущность.
  CashFlowCategoryRule toDomain() => CashFlowCategoryRule(
        id: id,
        companyId: companyId,
        categoryId: categoryId,
        keyword: keyword,
        operationType: operationType,
        priority: priority,
        requiresContractBinding: requiresContractBinding,
        createdAt: createdAt,
        categoryName: categoryName,
      );
}
