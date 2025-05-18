// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_hour.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WorkHour _$WorkHourFromJson(Map<String, dynamic> json) => _WorkHour(
      id: json['id'] as String,
      workId: json['work_id'] as String,
      employeeId: json['employee_id'] as String,
      hours: json['hours'] as num,
      comment: json['comment'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$WorkHourToJson(_WorkHour instance) => <String, dynamic>{
      'id': instance.id,
      'work_id': instance.workId,
      'employee_id': instance.employeeId,
      'hours': instance.hours,
      'comment': instance.comment,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
