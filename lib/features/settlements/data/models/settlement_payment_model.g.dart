// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settlement_payment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SettlementPaymentModel _$SettlementPaymentModelFromJson(
  Map<String, dynamic> json,
) => _SettlementPaymentModel(
  id: json['id'] as String,
  companyId: json['company_id'] as String,
  settlementOperationId: json['settlement_operation_id'] as String,
  paymentDate: DateTime.parse(json['payment_date'] as String),
  amount: (json['amount'] as num).toDouble(),
  note: json['note'] as String?,
  cashFlowTransactionId: json['cash_flow_transaction_id'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  createdBy: json['created_by'] as String?,
);

Map<String, dynamic> _$SettlementPaymentModelToJson(
  _SettlementPaymentModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'company_id': instance.companyId,
  'settlement_operation_id': instance.settlementOperationId,
  'payment_date': dateOnlyToJson(instance.paymentDate),
  'amount': instance.amount,
  'note': instance.note,
  'cash_flow_transaction_id': instance.cashFlowTransactionId,
  'created_at': instance.createdAt?.toIso8601String(),
  'created_by': instance.createdBy,
};
