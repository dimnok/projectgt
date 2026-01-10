// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'employee_rate_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EmployeeRateModel _$EmployeeRateModelFromJson(Map<String, dynamic> json) =>
    _EmployeeRateModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      employeeId: json['employee_id'] as String,
      hourlyRate: (json['hourly_rate'] as num).toDouble(),
      validFrom: DateTime.parse(json['valid_from'] as String),
      validTo: json['valid_to'] == null
          ? null
          : DateTime.parse(json['valid_to'] as String),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      createdBy: json['created_by'] as String?,
    );

Map<String, dynamic> _$EmployeeRateModelToJson(_EmployeeRateModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'company_id': instance.companyId,
      'employee_id': instance.employeeId,
      'hourly_rate': instance.hourlyRate,
      'valid_from': instance.validFrom.toIso8601String(),
      'valid_to': instance.validTo?.toIso8601String(),
      'created_at': instance.createdAt?.toIso8601String(),
      'created_by': instance.createdBy,
    };
