// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cash_flow_category_rule_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CashFlowCategoryRuleModel _$CashFlowCategoryRuleModelFromJson(
  Map<String, dynamic> json,
) => _CashFlowCategoryRuleModel(
  id: json['id'] as String,
  companyId: json['company_id'] as String,
  categoryId: json['category_id'] as String,
  keyword: json['keyword'] as String,
  operationType: $enumDecode(
    _$CashFlowOperationTypeEnumMap,
    json['operation_type'],
  ),
  priority: (json['priority'] as num?)?.toInt() ?? 0,
  requiresContractBinding: json['requires_contract_binding'] as bool? ?? true,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  categoryName: json['category_name'] as String?,
);

Map<String, dynamic> _$CashFlowCategoryRuleModelToJson(
  _CashFlowCategoryRuleModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'company_id': instance.companyId,
  'category_id': instance.categoryId,
  'keyword': instance.keyword,
  'operation_type': _$CashFlowOperationTypeEnumMap[instance.operationType]!,
  'priority': instance.priority,
  'requires_contract_binding': instance.requiresContractBinding,
  'created_at': instance.createdAt?.toIso8601String(),
};

const _$CashFlowOperationTypeEnumMap = {
  CashFlowOperationType.income: 'income',
  CashFlowOperationType.expense: 'expense',
};
