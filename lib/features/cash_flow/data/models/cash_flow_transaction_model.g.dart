// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cash_flow_transaction_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CashFlowTransactionModel _$CashFlowTransactionModelFromJson(
  Map<String, dynamic> json,
) => _CashFlowTransactionModel(
  id: json['id'] as String,
  companyId: json['company_id'] as String,
  date: DateTime.parse(json['date'] as String),
  type: $enumDecode(_$CashFlowTypeEnumMap, json['type']),
  amount: (json['amount'] as num).toDouble(),
  objectId: json['object_id'] as String?,
  contractId: json['contract_id'] as String?,
  contractorId: json['contractor_id'] as String?,
  contractorName: json['contractor_name'] as String?,
  contractorInn: json['contractor_inn'] as String?,
  categoryId: json['category_id'] as String?,
  comment: json['comment'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  createdBy: json['created_by'] as String?,
  operationHash: json['operation_hash'] as String?,
  objectName: json['object_name'] as String?,
  contractNumber: json['contract_number'] as String?,
  categoryName: json['category_name'] as String?,
  createdByName: json['created_by_name'] as String?,
);

Map<String, dynamic> _$CashFlowTransactionModelToJson(
  _CashFlowTransactionModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'company_id': instance.companyId,
  'date': _dateOnlyToJson(instance.date),
  'type': _$CashFlowTypeEnumMap[instance.type]!,
  'amount': instance.amount,
  'object_id': instance.objectId,
  'contract_id': instance.contractId,
  'contractor_id': instance.contractorId,
  'contractor_name': instance.contractorName,
  'contractor_inn': instance.contractorInn,
  'category_id': instance.categoryId,
  'comment': instance.comment,
  'created_at': instance.createdAt?.toIso8601String(),
  'created_by': instance.createdBy,
  'operation_hash': instance.operationHash,
};

const _$CashFlowTypeEnumMap = {
  CashFlowType.income: 'income',
  CashFlowType.expense: 'expense',
};
