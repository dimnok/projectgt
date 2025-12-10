// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'procurement_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProcurementRequest _$ProcurementRequestFromJson(Map<String, dynamic> json) =>
    _ProcurementRequest(
      id: json['id'] as String,
      itemName: json['item_name'] as String,
      quantity: json['quantity'] as String,
      status: json['status'] as String? ?? 'pending_approval',
      createdAt: DateTime.parse(json['created_at'] as String),
      description: json['description'] as String?,
      requesterTelegramId: (json['requester_telegram_id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ProcurementRequestToJson(_ProcurementRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'item_name': instance.itemName,
      'quantity': instance.quantity,
      'status': instance.status,
      'created_at': instance.createdAt.toIso8601String(),
      'description': instance.description,
      'requester_telegram_id': instance.requesterTelegramId,
    };
