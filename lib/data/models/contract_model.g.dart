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
      vatRate: (json['vat_rate'] as num?)?.toDouble() ?? 0.0,
      isVatIncluded: json['is_vat_included'] as bool? ?? true,
      vatAmount: (json['vat_amount'] as num?)?.toDouble() ?? 0.0,
      advanceAmount: (json['advance_amount'] as num?)?.toDouble() ?? 0.0,
      warrantyRetentionAmount:
          (json['warranty_retention_amount'] as num?)?.toDouble() ?? 0.0,
      warrantyRetentionRate:
          (json['warranty_retention_rate'] as num?)?.toDouble() ?? 0.0,
      warrantyPeriodMonths:
          (json['warranty_period_months'] as num?)?.toInt() ?? 0,
      generalContractorFeeAmount:
          (json['general_contractor_fee_amount'] as num?)?.toDouble() ?? 0.0,
      generalContractorFeeRate:
          (json['general_contractor_fee_rate'] as num?)?.toDouble() ?? 0.0,
      objectId: json['object_id'] as String,
      objectName: json['object_name'] as String?,
      status: $enumDecodeNullable(_$ContractStatusEnumMap, json['status']) ??
          ContractStatus.active,
      contractorLegalName: json['contractor_legal_name'] as String?,
      contractorPosition: json['contractor_position'] as String?,
      contractorSigner: json['contractor_signer'] as String?,
      customerLegalName: json['customer_legal_name'] as String?,
      customerPosition: json['customer_position'] as String?,
      customerSigner: json['customer_signer'] as String?,
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
      'vat_rate': instance.vatRate,
      'is_vat_included': instance.isVatIncluded,
      'vat_amount': instance.vatAmount,
      'advance_amount': instance.advanceAmount,
      'warranty_retention_amount': instance.warrantyRetentionAmount,
      'warranty_retention_rate': instance.warrantyRetentionRate,
      'warranty_period_months': instance.warrantyPeriodMonths,
      'general_contractor_fee_amount': instance.generalContractorFeeAmount,
      'general_contractor_fee_rate': instance.generalContractorFeeRate,
      'object_id': instance.objectId,
      'object_name': instance.objectName,
      'status': _$ContractStatusEnumMap[instance.status]!,
      'contractor_legal_name': instance.contractorLegalName,
      'contractor_position': instance.contractorPosition,
      'contractor_signer': instance.contractorSigner,
      'customer_legal_name': instance.customerLegalName,
      'customer_position': instance.customerPosition,
      'customer_signer': instance.customerSigner,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$ContractStatusEnumMap = {
  ContractStatus.active: 'active',
  ContractStatus.suspended: 'suspended',
  ContractStatus.completed: 'completed',
};
