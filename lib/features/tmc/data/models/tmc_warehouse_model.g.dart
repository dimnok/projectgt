// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tmc_warehouse_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TmcWarehouseModel _$TmcWarehouseModelFromJson(Map<String, dynamic> json) =>
    _TmcWarehouseModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      description: json['description'] as String?,
      isArchived: json['is_archived'] as bool? ?? false,
      archivedAt: json['archived_at'] == null
          ? null
          : DateTime.parse(json['archived_at'] as String),
      isMain: json['is_main'] as bool? ?? false,
      isSystem: json['is_system'] as bool? ?? false,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      createdBy: json['created_by'] as String?,
    );

Map<String, dynamic> _$TmcWarehouseModelToJson(_TmcWarehouseModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'company_id': instance.companyId,
      'name': instance.name,
      'address': instance.address,
      'description': instance.description,
      'is_archived': instance.isArchived,
      'archived_at': instance.archivedAt?.toIso8601String(),
      'is_main': instance.isMain,
      'is_system': instance.isSystem,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'created_by': instance.createdBy,
    };
