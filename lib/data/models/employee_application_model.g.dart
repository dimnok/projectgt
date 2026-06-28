// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'employee_application_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EmployeeApplicationModel _$EmployeeApplicationModelFromJson(
  Map<String, dynamic> json,
) => _EmployeeApplicationModel(
  id: json['id'] as String,
  companyId: json['company_id'] as String,
  employeeId: json['employee_id'] as String,
  applicationType: json['application_type'] as String,
  startDate: DateTime.parse(json['start_date'] as String),
  endDate: json['end_date'] == null
      ? null
      : DateTime.parse(json['end_date'] as String),
  durationDays: (json['duration_days'] as num).toInt(),
  scanName: json['scan_name'] as String,
  scanPath: json['scan_path'] as String,
  scanSize: (json['scan_size'] as num).toInt(),
  scanType: json['scan_type'] as String,
  createdBy: json['created_by'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  creator: json['creator'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$EmployeeApplicationModelToJson(
  _EmployeeApplicationModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'company_id': instance.companyId,
  'employee_id': instance.employeeId,
  'application_type': instance.applicationType,
  'start_date': instance.startDate.toIso8601String(),
  'end_date': instance.endDate?.toIso8601String(),
  'duration_days': instance.durationDays,
  'scan_name': instance.scanName,
  'scan_path': instance.scanPath,
  'scan_size': instance.scanSize,
  'scan_type': instance.scanType,
  'created_by': instance.createdBy,
  'created_at': instance.createdAt.toIso8601String(),
  'creator': instance.creator,
};
