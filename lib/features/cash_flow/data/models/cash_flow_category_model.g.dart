// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cash_flow_category_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CashFlowCategoryModel _$CashFlowCategoryModelFromJson(
  Map<String, dynamic> json,
) => _CashFlowCategoryModel(
  id: json['id'] as String,
  companyId: json['company_id'] as String,
  name: json['name'] as String,
  type: $enumDecode(_$CashFlowOperationTypeEnumMap, json['type']),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$CashFlowCategoryModelToJson(
  _CashFlowCategoryModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'company_id': instance.companyId,
  'name': instance.name,
  'type': _$CashFlowOperationTypeEnumMap[instance.type]!,
  'created_at': instance.createdAt?.toIso8601String(),
};

const _$CashFlowOperationTypeEnumMap = {
  CashFlowOperationType.income: 'income',
  CashFlowOperationType.expense: 'expense',
};
