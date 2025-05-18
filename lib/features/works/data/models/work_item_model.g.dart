// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WorkItemModel _$WorkItemModelFromJson(Map<String, dynamic> json) =>
    _WorkItemModel(
      id: json['id'] as String,
      workId: json['work_id'] as String,
      section: json['section'] as String,
      floor: json['floor'] as String,
      estimateId: json['estimate_id'] as String,
      name: json['name'] as String,
      system: json['system'] as String,
      subsystem: json['subsystem'] as String,
      unit: json['unit'] as String,
      quantity: json['quantity'] as num,
      price: (json['price'] as num?)?.toDouble(),
      total: (json['total'] as num?)?.toDouble(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$WorkItemModelToJson(_WorkItemModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'work_id': instance.workId,
      'section': instance.section,
      'floor': instance.floor,
      'estimate_id': instance.estimateId,
      'name': instance.name,
      'system': instance.system,
      'subsystem': instance.subsystem,
      'unit': instance.unit,
      'quantity': instance.quantity,
      'price': instance.price,
      'total': instance.total,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
