// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tmc_notification_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TmcNotificationModel _$TmcNotificationModelFromJson(
  Map<String, dynamic> json,
) => _TmcNotificationModel(
  id: json['id'] as String,
  companyId: json['company_id'] as String,
  userId: json['user_id'] as String?,
  notificationType: $enumDecode(
    _$TmcNotificationTypeEnumMap,
    json['notification_type'],
  ),
  title: json['title'] as String,
  body: json['body'] as String?,
  itemId: json['item_id'] as String?,
  unitId: json['unit_id'] as String?,
  payload: json['payload'] as Map<String, dynamic>? ?? const {},
  isRead: json['is_read'] as bool? ?? false,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$TmcNotificationModelToJson(
  _TmcNotificationModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'company_id': instance.companyId,
  'user_id': instance.userId,
  'notification_type': _$TmcNotificationTypeEnumMap[instance.notificationType]!,
  'title': instance.title,
  'body': instance.body,
  'item_id': instance.itemId,
  'unit_id': instance.unitId,
  'payload': instance.payload,
  'is_read': instance.isRead,
  'created_at': instance.createdAt?.toIso8601String(),
};

const _$TmcNotificationTypeEnumMap = {
  TmcNotificationType.warrantyExpiring: 'warranty_expiring',
  TmcNotificationType.serviceDue: 'service_due',
  TmcNotificationType.returnDue: 'return_due',
  TmcNotificationType.notReturned: 'not_returned',
  TmcNotificationType.needsRepair: 'needs_repair',
  TmcNotificationType.ppeReplacement: 'ppe_replacement',
  TmcNotificationType.shortage: 'shortage',
  TmcNotificationType.noMovement: 'no_movement',
  TmcNotificationType.other: 'other',
};
