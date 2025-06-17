// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payroll_bonus_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PayrollBonusModel _$PayrollBonusModelFromJson(Map<String, dynamic> json) =>
    _PayrollBonusModel(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      type: json['type'] as String,
      amount: json['amount'] as num,
      reason: json['reason'] as String?,
      date:
          json['date'] == null ? null : DateTime.parse(json['date'] as String),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      objectId: json['object_id'] as String?,
    );

Map<String, dynamic> _$PayrollBonusModelToJson(_PayrollBonusModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'employee_id': instance.employeeId,
      'type': instance.type,
      'amount': instance.amount,
      'reason': instance.reason,
      'date': instance.date?.toIso8601String(),
      'created_at': instance.createdAt?.toIso8601String(),
      'object_id': instance.objectId,
    };
