// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_version_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppVersionModel _$AppVersionModelFromJson(Map<String, dynamic> json) =>
    _AppVersionModel(
      id: json['id'] as String,
      currentVersion: json['current_version'] as String,
      minimumVersion: json['minimum_version'] as String,
      forceUpdate: json['force_update'] as bool,
      updateMessage: json['update_message'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$AppVersionModelToJson(_AppVersionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'current_version': instance.currentVersion,
      'minimum_version': instance.minimumVersion,
      'force_update': instance.forceUpdate,
      'update_message': instance.updateMessage,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
