// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'role_permission_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RolePermissionModel _$RolePermissionModelFromJson(Map<String, dynamic> json) =>
    _RolePermissionModel(
      id: json['id'] as String,
      roleId: json['role_id'] as String,
      moduleCode: json['module_code'] as String,
      permissionCode: json['permission_code'] as String,
      isEnabled: json['is_enabled'] as bool? ?? true,
    );

Map<String, dynamic> _$RolePermissionModelToJson(
        _RolePermissionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'role_id': instance.roleId,
      'module_code': instance.moduleCode,
      'permission_code': instance.permissionCode,
      'is_enabled': instance.isEnabled,
    };
