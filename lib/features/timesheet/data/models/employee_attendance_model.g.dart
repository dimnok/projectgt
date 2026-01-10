// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'employee_attendance_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EmployeeAttendanceModel _$EmployeeAttendanceModelFromJson(
  Map<String, dynamic> json,
) => _EmployeeAttendanceModel(
  id: json['id'] as String,
  companyId: json['company_id'] as String,
  employeeId: json['employee_id'] as String,
  objectId: json['object_id'] as String,
  date: json['date'] as String,
  hours: json['hours'] as num,
  attendanceType:
      $enumDecodeNullable(_$AttendanceTypeEnumMap, json['attendance_type']) ??
      AttendanceType.work,
  comment: json['comment'] as String?,
  createdBy: json['created_by'] as String?,
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
);

Map<String, dynamic> _$EmployeeAttendanceModelToJson(
  _EmployeeAttendanceModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'company_id': instance.companyId,
  'employee_id': instance.employeeId,
  'object_id': instance.objectId,
  'date': instance.date,
  'hours': instance.hours,
  'attendance_type': _$AttendanceTypeEnumMap[instance.attendanceType]!,
  'comment': instance.comment,
  'created_by': instance.createdBy,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
};

const _$AttendanceTypeEnumMap = {
  AttendanceType.work: 'work',
  AttendanceType.vacation: 'vacation',
  AttendanceType.sickLeave: 'sick_leave',
  AttendanceType.businessTrip: 'business_trip',
  AttendanceType.dayOff: 'day_off',
};
