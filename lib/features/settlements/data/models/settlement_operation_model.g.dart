// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settlement_operation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SettlementOperationModel _$SettlementOperationModelFromJson(
  Map<String, dynamic> json,
) => _SettlementOperationModel(
  id: json['id'] as String,
  companyId: json['company_id'] as String,
  operationType: $enumDecode(
    _$SettlementOperationTypeEnumMap,
    json['operation_type'],
  ),
  objectId: json['object_id'] as String,
  contractorId: json['contractor_id'] as String,
  contractId: json['contract_id'] as String,
  periodFrom: json['period_from'] == null
      ? null
      : DateTime.parse(json['period_from'] as String),
  periodTo: json['period_to'] == null
      ? null
      : DateTime.parse(json['period_to'] as String),
  actNumber: json['act_number'] as String?,
  actDate: json['act_date'] == null
      ? null
      : DateTime.parse(json['act_date'] as String),
  invoiceNumber: json['invoice_number'] as String,
  invoiceDate: DateTime.parse(json['invoice_date'] as String),
  amount: (json['amount'] as num).toDouble(),
  isVatIncluded: json['is_vat_included'] as bool? ?? true,
  vatRate: (json['vat_rate'] as num?)?.toDouble(),
  vatAmount: (json['vat_amount'] as num?)?.toDouble() ?? 0,
  advanceRetention: (json['advance_retention'] as num?)?.toDouble() ?? 0,
  warrantyRetention: (json['warranty_retention'] as num?)?.toDouble() ?? 0,
  totalToPay: (json['total_to_pay'] as num?)?.toDouble() ?? 0,
  paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0,
  paymentStatus:
      $enumDecodeNullable(
        _$SettlementPaymentStatusEnumMap,
        json['payment_status'],
      ) ??
      SettlementPaymentStatus.unpaid,
  purpose: json['purpose'] as String?,
  note: json['note'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  createdBy: json['created_by'] as String?,
  objectName: json['object_name'] as String?,
  contractorName: json['contractor_name'] as String?,
  contractNumber: json['contract_number'] as String?,
);

Map<String, dynamic> _$SettlementOperationModelToJson(
  _SettlementOperationModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'company_id': instance.companyId,
  'operation_type': _$SettlementOperationTypeEnumMap[instance.operationType]!,
  'object_id': instance.objectId,
  'contractor_id': instance.contractorId,
  'contract_id': instance.contractId,
  'period_from': _dateOnlyToJson(instance.periodFrom),
  'period_to': _dateOnlyToJson(instance.periodTo),
  'act_number': instance.actNumber,
  'act_date': _dateOnlyToJson(instance.actDate),
  'invoice_number': instance.invoiceNumber,
  'invoice_date': _dateOnlyToJson(instance.invoiceDate),
  'amount': instance.amount,
  'is_vat_included': instance.isVatIncluded,
  'vat_rate': instance.vatRate,
  'vat_amount': instance.vatAmount,
  'advance_retention': instance.advanceRetention,
  'warranty_retention': instance.warrantyRetention,
  'total_to_pay': instance.totalToPay,
  'paid_amount': instance.paidAmount,
  'payment_status': _$SettlementPaymentStatusEnumMap[instance.paymentStatus]!,
  'purpose': instance.purpose,
  'note': instance.note,
  'created_at': instance.createdAt?.toIso8601String(),
  'created_by': instance.createdBy,
};

const _$SettlementOperationTypeEnumMap = {
  SettlementOperationType.act: 'act',
  SettlementOperationType.advance: 'advance',
  SettlementOperationType.other: 'other',
};

const _$SettlementPaymentStatusEnumMap = {
  SettlementPaymentStatus.unpaid: 'unpaid',
  SettlementPaymentStatus.partial: 'partial',
  SettlementPaymentStatus.paid: 'paid',
  SettlementPaymentStatus.overpaid: 'overpaid',
};
