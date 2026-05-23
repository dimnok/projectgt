// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contract_act_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ContractActModel _$ContractActModelFromJson(Map<String, dynamic> json) =>
    _ContractActModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      contractId: json['contract_id'] as String,
      actKind: json['act_kind'] as String? ?? 'manual',
      title: json['title'] as String,
      number: json['number'] as String,
      actDate: DateTime.parse(json['act_date'] as String),
      periodFrom: DateTime.parse(json['period_from'] as String),
      periodTo: DateTime.parse(json['period_to'] as String),
      amount: (json['amount'] as num).toDouble(),
      vatAmount: (json['vat_amount'] as num).toDouble(),
      advanceRetention: (json['advance_retention'] as num).toDouble(),
      warrantyRetention: (json['warranty_retention'] as num).toDouble(),
      otherRetentions: (json['other_retentions'] as num).toDouble(),
      totalToPay: (json['total_to_pay'] as num).toDouble(),
      amountSource: json['amount_source'] as String? ?? 'manual',
      note: json['note'] as String?,
      workflowStatus: json['workflow_status'] as String,
      paymentStatus: json['payment_status'] as String,
      vorId: json['vor_id'] as String?,
      excelPath: json['excel_path'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      createdBy: json['created_by'] as String?,
    );

Map<String, dynamic> _$ContractActModelToJson(_ContractActModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'company_id': instance.companyId,
      'contract_id': instance.contractId,
      'act_kind': instance.actKind,
      'title': instance.title,
      'number': instance.number,
      'act_date': instance.actDate.toIso8601String(),
      'period_from': instance.periodFrom.toIso8601String(),
      'period_to': instance.periodTo.toIso8601String(),
      'amount': instance.amount,
      'vat_amount': instance.vatAmount,
      'advance_retention': instance.advanceRetention,
      'warranty_retention': instance.warrantyRetention,
      'other_retentions': instance.otherRetentions,
      'total_to_pay': instance.totalToPay,
      'amount_source': instance.amountSource,
      'note': instance.note,
      'workflow_status': instance.workflowStatus,
      'payment_status': instance.paymentStatus,
      'vor_id': instance.vorId,
      'excel_path': instance.excelPath,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'created_by': instance.createdBy,
    };
