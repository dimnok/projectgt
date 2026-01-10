// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_material_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WorkMaterialModel _$WorkMaterialModelFromJson(Map<String, dynamic> json) =>
    _WorkMaterialModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      workId: json['work_id'] as String,
      name: json['name'] as String,
      unit: json['unit'] as String,
      quantity: json['quantity'] as num,
      comment: json['comment'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$WorkMaterialModelToJson(_WorkMaterialModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'company_id': instance.companyId,
      'work_id': instance.workId,
      'name': instance.name,
      'unit': instance.unit,
      'quantity': instance.quantity,
      'comment': instance.comment,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
