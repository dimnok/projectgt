// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timesheet_entry_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TimesheetEntryModel _$TimesheetEntryModelFromJson(Map<String, dynamic> json) =>
    _TimesheetEntryModel(
      id: json['id'] as String,
      workId: json['work_id'] as String,
      employeeId: json['employee_id'] as String,
      hours: json['hours'] as num,
      comment: json['comment'] as String?,
      date: DateTime.parse(json['date'] as String),
      objectId: json['object_id'] as String,
      employeeName: json['employee_name'] as String?,
      objectName: json['object_name'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$TimesheetEntryModelToJson(
  _TimesheetEntryModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'work_id': instance.workId,
  'employee_id': instance.employeeId,
  'hours': instance.hours,
  'comment': instance.comment,
  'date': instance.date.toIso8601String(),
  'object_id': instance.objectId,
  'employee_name': instance.employeeName,
  'object_name': instance.objectName,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};
