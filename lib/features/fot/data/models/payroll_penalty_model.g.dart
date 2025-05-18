// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payroll_penalty_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PayrollPenaltyModel _$PayrollPenaltyModelFromJson(Map<String, dynamic> json) =>
    _PayrollPenaltyModel(
      id: json['id'] as String,
      payrollId: json['payrollId'] as String,
      type: json['type'] as String,
      amount: json['amount'] as num,
      reason: json['reason'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$PayrollPenaltyModelToJson(
        _PayrollPenaltyModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'payrollId': instance.payrollId,
      'type': instance.type,
      'amount': instance.amount,
      'reason': instance.reason,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
