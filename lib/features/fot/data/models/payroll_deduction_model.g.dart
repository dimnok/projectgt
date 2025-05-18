// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payroll_deduction_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PayrollDeductionModel _$PayrollDeductionModelFromJson(
        Map<String, dynamic> json) =>
    _PayrollDeductionModel(
      id: json['id'] as String,
      payrollId: json['payrollId'] as String,
      type: json['type'] as String,
      amount: json['amount'] as num,
      comment: json['comment'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$PayrollDeductionModelToJson(
        _PayrollDeductionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'payrollId': instance.payrollId,
      'type': instance.type,
      'amount': instance.amount,
      'comment': instance.comment,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
