// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ks2_act_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Ks2ActModel _$Ks2ActModelFromJson(Map<String, dynamic> json) => _Ks2ActModel(
      id: json['id'] as String,
      contractId: json['contract_id'] as String,
      number: json['number'] as String,
      date: DateTime.parse(json['date'] as String),
      periodFrom: DateTime.parse(json['period_from'] as String),
      periodTo: DateTime.parse(json['period_to'] as String),
      status: $enumDecodeNullable(_$Ks2StatusEnumMap, json['status']) ??
          Ks2Status.draft,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      createdBy: json['created_by'] as String?,
    );

Map<String, dynamic> _$Ks2ActModelToJson(_Ks2ActModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'contract_id': instance.contractId,
      'number': instance.number,
      'date': instance.date.toIso8601String(),
      'period_from': instance.periodFrom.toIso8601String(),
      'period_to': instance.periodTo.toIso8601String(),
      'status': _$Ks2StatusEnumMap[instance.status]!,
      'total_amount': instance.totalAmount,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'created_by': instance.createdBy,
    };

const _$Ks2StatusEnumMap = {
  Ks2Status.draft: 'draft',
  Ks2Status.signed: 'signed',
  Ks2Status.paid: 'paid',
};
