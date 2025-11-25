// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'light_work_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LightWorkModel _$LightWorkModelFromJson(Map<String, dynamic> json) =>
    _LightWorkModel(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      totalAmount: (json['total_amount'] as num).toDouble(),
      employeesCount: (json['employees_count'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$LightWorkModelToJson(_LightWorkModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date.toIso8601String(),
      'total_amount': instance.totalAmount,
      'employees_count': instance.employeesCount,
    };
