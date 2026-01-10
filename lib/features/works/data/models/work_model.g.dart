// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WorkModel _$WorkModelFromJson(Map<String, dynamic> json) => _WorkModel(
  id: json['id'] as String?,
  companyId: json['company_id'] as String,
  date: DateTime.parse(json['date'] as String),
  objectId: json['object_id'] as String,
  openedBy: json['opened_by'] as String,
  status: json['status'] as String,
  photoUrl: json['photo_url'] as String?,
  eveningPhotoUrl: json['evening_photo_url'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  totalAmount: (json['total_amount'] as num?)?.toDouble(),
  itemsCount: (json['items_count'] as num?)?.toInt(),
  employeesCount: (json['employees_count'] as num?)?.toInt(),
  telegramMessageId: (json['telegram_message_id'] as num?)?.toInt(),
);

Map<String, dynamic> _$WorkModelToJson(_WorkModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'company_id': instance.companyId,
      'date': instance.date.toIso8601String(),
      'object_id': instance.objectId,
      'opened_by': instance.openedBy,
      'status': instance.status,
      'photo_url': instance.photoUrl,
      'evening_photo_url': instance.eveningPhotoUrl,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'total_amount': instance.totalAmount,
      'items_count': instance.itemsCount,
      'employees_count': instance.employeesCount,
      'telegram_message_id': instance.telegramMessageId,
    };
