// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payroll_payout_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PayrollPayoutModel _$PayrollPayoutModelFromJson(Map<String, dynamic> json) =>
    _PayrollPayoutModel(
      id: json['id'] as String,
      payrollId: json['payrollId'] as String,
      amount: json['amount'] as num,
      payoutDate: DateTime.parse(json['payoutDate'] as String),
      method: json['method'] as String,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$PayrollPayoutModelToJson(_PayrollPayoutModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'payrollId': instance.payrollId,
      'amount': instance.amount,
      'payoutDate': instance.payoutDate.toIso8601String(),
      'method': instance.method,
      'status': instance.status,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
