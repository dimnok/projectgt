// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WorkItem _$WorkItemFromJson(Map<String, dynamic> json) => _WorkItem(
  id: json['id'] as String,
  companyId: json['companyId'] as String,
  workId: json['workId'] as String,
  section: json['section'] as String,
  floor: json['floor'] as String,
  estimateId: json['estimateId'] as String,
  name: json['name'] as String,
  system: json['system'] as String,
  subsystem: json['subsystem'] as String,
  unit: json['unit'] as String,
  quantity: json['quantity'] as num,
  price: (json['price'] as num?)?.toDouble(),
  total: (json['total'] as num?)?.toDouble(),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  ks2Id: json['ks2Id'] as String?,
);

Map<String, dynamic> _$WorkItemToJson(_WorkItem instance) => <String, dynamic>{
  'id': instance.id,
  'companyId': instance.companyId,
  'workId': instance.workId,
  'section': instance.section,
  'floor': instance.floor,
  'estimateId': instance.estimateId,
  'name': instance.name,
  'system': instance.system,
  'subsystem': instance.subsystem,
  'unit': instance.unit,
  'quantity': instance.quantity,
  'price': instance.price,
  'total': instance.total,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
  'ks2Id': instance.ks2Id,
};
