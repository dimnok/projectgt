// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contract_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ContractModel _$ContractModelFromJson(Map<String, dynamic> json) =>
    _ContractModel(
      id: json['id'] as String,
      number: json['number'] as String,
      date: DateTime.parse(json['date'] as String),
      endDate: json['end_date'] == null
          ? null
          : DateTime.parse(json['end_date'] as String),
      contractorId: json['contractor_id'] as String,
      contractorName: json['contractor_name'] as String?,
      amount: (json['amount'] as num).toDouble(),
      objectId: json['object_id'] as String,
      objectName: json['object_name'] as String?,
      status: $enumDecodeNullable(_$ContractStatusEnumMap, json['status']) ??
          ContractStatus.active,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$ContractModelToJson(_ContractModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'number': instance.number,
      'date': _dateOnlyToJson(instance.date),
      'end_date': _dateOnlyToJson(instance.endDate),
      'contractor_id': instance.contractorId,
      'contractor_name': instance.contractorName,
      'amount': instance.amount,
      'object_id': instance.objectId,
      'object_name': instance.objectName,
      'status': _$ContractStatusEnumMap[instance.status]!,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$ContractStatusEnumMap = {
  ContractStatus.active: 'active',
  ContractStatus.suspended: 'suspended',
  ContractStatus.completed: 'completed',
};
