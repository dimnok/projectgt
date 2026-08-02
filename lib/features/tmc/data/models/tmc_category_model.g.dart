// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tmc_category_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TmcCategoryModel _$TmcCategoryModelFromJson(Map<String, dynamic> json) =>
    _TmcCategoryModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      parentId: json['parent_id'] as String?,
      name: json['name'] as String,
      code: json['code'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
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

Map<String, dynamic> _$TmcCategoryModelToJson(_TmcCategoryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'company_id': instance.companyId,
      'parent_id': instance.parentId,
      'name': instance.name,
      'code': instance.code,
      'sort_order': instance.sortOrder,
      'is_archived': instance.isArchived,
      'archived_at': instance.archivedAt?.toIso8601String(),
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'created_by': instance.createdBy,
    };
