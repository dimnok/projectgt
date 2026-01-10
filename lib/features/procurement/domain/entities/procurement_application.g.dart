// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'procurement_application.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProcurementApplication _$ProcurementApplicationFromJson(
  Map<String, dynamic> json,
) => _ProcurementApplication(
  id: json['id'] as String,
  readableId: json['readable_id'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  status: json['status'] as String? ?? 'pending_approval',
  object: _objectFromJson(json['object'] as Map<String, dynamic>?),
  requester: json['requester'] == null
      ? null
      : BotUserModel.fromJson(json['requester'] as Map<String, dynamic>),
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => ProcurementRequest.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  history:
      (json['history'] as List<dynamic>?)
          ?.map((e) => ProcurementHistory.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$ProcurementApplicationToJson(
  _ProcurementApplication instance,
) => <String, dynamic>{
  'id': instance.id,
  'readable_id': instance.readableId,
  'created_at': instance.createdAt.toIso8601String(),
  'status': instance.status,
  'object': _objectToJson(instance.object),
  'requester': instance.requester?.toJson(),
  'items': instance.items.map((e) => e.toJson()).toList(),
  'history': instance.history.map((e) => e.toJson()).toList(),
};

_ProcurementHistory _$ProcurementHistoryFromJson(Map<String, dynamic> json) =>
    _ProcurementHistory(
      id: json['id'] as String,
      newStatus: json['new_status'] as String,
      changedAt: DateTime.parse(json['changed_at'] as String),
      comment: json['comment'] as String?,
      actor: json['actor'] == null
          ? null
          : BotUserModel.fromJson(json['actor'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ProcurementHistoryToJson(_ProcurementHistory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'new_status': instance.newStatus,
      'changed_at': instance.changedAt.toIso8601String(),
      'comment': instance.comment,
      'actor': instance.actor?.toJson(),
    };
