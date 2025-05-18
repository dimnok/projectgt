// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_hour_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WorkHourModel _$WorkHourModelFromJson(Map<String, dynamic> json) =>
    _WorkHourModel(
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

Map<String, dynamic> _$WorkHourModelToJson(_WorkHourModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'work_id': instance.workId,
      'employee_id': instance.employeeId,
      'hours': instance.hours,
      'comment': instance.comment,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
