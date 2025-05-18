// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_material.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WorkMaterial _$WorkMaterialFromJson(Map<String, dynamic> json) =>
    _WorkMaterial(
      id: json['id'] as String,
      workId: json['workId'] as String,
      name: json['name'] as String,
      unit: json['unit'] as String,
      quantity: json['quantity'] as num,
      comment: json['comment'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$WorkMaterialToJson(_WorkMaterial instance) =>
    <String, dynamic>{
      'id': instance.id,
      'workId': instance.workId,
      'name': instance.name,
      'unit': instance.unit,
      'quantity': instance.quantity,
      'comment': instance.comment,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
