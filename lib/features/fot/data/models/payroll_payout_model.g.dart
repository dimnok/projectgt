// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payroll_payout_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PayrollPayoutModel _$PayrollPayoutModelFromJson(Map<String, dynamic> json) =>
    _PayrollPayoutModel(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      amount: json['amount'] as num,
      payoutDate: DateTime.parse(json['payout_date'] as String),
      method: json['method'] as String,
      type: json['type'] as String,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      comment: json['comment'] as String?,
    );

Map<String, dynamic> _$PayrollPayoutModelToJson(_PayrollPayoutModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'employee_id': instance.employeeId,
      'amount': instance.amount,
      'payout_date': instance.payoutDate.toIso8601String(),
      'method': instance.method,
      'type': instance.type,
      'created_at': instance.createdAt?.toIso8601String(),
      'comment': instance.comment,
    };
