// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProfileModel _$ProfileModelFromJson(Map<String, dynamic> json) =>
    _ProfileModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      shortName: json['short_name'] as String?,
      photoUrl: json['photo_url'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'user',
      status: json['status'] as bool? ?? true,
      object: json['object'] as Map<String, dynamic>?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      objectIds: (json['object_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$ProfileModelToJson(_ProfileModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'full_name': instance.fullName,
      'short_name': instance.shortName,
      'photo_url': instance.photoUrl,
      'phone': instance.phone,
      'role': instance.role,
      'status': instance.status,
      'object': instance.object,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'object_ids': instance.objectIds,
    };
