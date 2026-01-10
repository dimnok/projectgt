// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payroll_penalty_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PayrollPenaltyModel _$PayrollPenaltyModelFromJson(Map<String, dynamic> json) =>
    _PayrollPenaltyModel(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      companyId: json['company_id'] as String,
      type: json['type'] as String,
      amount: json['amount'] as num,
      reason: json['reason'] as String?,
      date: json['date'] == null
          ? null
          : DateTime.parse(json['date'] as String),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      objectId: json['object_id'] as String?,
    );

Map<String, dynamic> _$PayrollPenaltyModelToJson(
  _PayrollPenaltyModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'employee_id': instance.employeeId,
  'company_id': instance.companyId,
  'type': instance.type,
  'amount': instance.amount,
  'reason': instance.reason,
  'date': instance.date?.toIso8601String(),
  'created_at': instance.createdAt?.toIso8601String(),
  'object_id': instance.objectId,
};
