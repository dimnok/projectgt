// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'employee_attendance_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EmployeeAttendanceEntry _$EmployeeAttendanceEntryFromJson(
        Map<String, dynamic> json) =>
    _EmployeeAttendanceEntry(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      objectId: json['objectId'] as String,
      date: DateTime.parse(json['date'] as String),
      hours: json['hours'] as num,
      attendanceType: $enumDecodeNullable(
              _$AttendanceTypeEnumMap, json['attendanceType']) ??
          AttendanceType.work,
      comment: json['comment'] as String?,
      createdBy: json['createdBy'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      employeeName: json['employeeName'] as String?,
      employeePosition: json['employeePosition'] as String?,
      objectName: json['objectName'] as String?,
    );

Map<String, dynamic> _$EmployeeAttendanceEntryToJson(
        _EmployeeAttendanceEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'employeeId': instance.employeeId,
      'objectId': instance.objectId,
      'date': instance.date.toIso8601String(),
      'hours': instance.hours,
      'attendanceType': _$AttendanceTypeEnumMap[instance.attendanceType]!,
      'comment': instance.comment,
      'createdBy': instance.createdBy,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'employeeName': instance.employeeName,
      'employeePosition': instance.employeePosition,
      'objectName': instance.objectName,
    };

const _$AttendanceTypeEnumMap = {
  AttendanceType.work: 'work',
  AttendanceType.vacation: 'vacation',
  AttendanceType.sickLeave: 'sick_leave',
  AttendanceType.businessTrip: 'business_trip',
  AttendanceType.dayOff: 'day_off',
};
