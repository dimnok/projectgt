// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tmc_condition_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TmcConditionModel _$TmcConditionModelFromJson(Map<String, dynamic> json) =>
    _TmcConditionModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      isSystem: json['is_system'] as bool? ?? false,
      isArchived: json['is_archived'] as bool? ?? false,
      archivedAt: json['archived_at'] == null
          ? null
          : DateTime.parse(json['archived_at'] as String),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      createdBy: json['created_by'] as String?,
    );

Map<String, dynamic> _$TmcConditionModelToJson(_TmcConditionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'company_id': instance.companyId,
      'code': instance.code,
      'name': instance.name,
      'sort_order': instance.sortOrder,
      'is_system': instance.isSystem,
      'is_archived': instance.isArchived,
      'archived_at': instance.archivedAt?.toIso8601String(),
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'created_by': instance.createdBy,
    };
