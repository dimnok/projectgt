// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tmc_write_off_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TmcWriteOffModel _$TmcWriteOffModelFromJson(Map<String, dynamic> json) =>
    _TmcWriteOffModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      itemId: json['item_id'] as String,
      unitId: json['unit_id'] as String?,
      writtenOffAt: tmcParseRequiredDate(json['written_off_at']),
      reason: $enumDecode(_$TmcWriteOffReasonEnumMap, json['reason']),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
      conditionId: json['condition_id'] as String?,
      bookValue: (json['book_value'] as num?)?.toDouble(),
      responsibleEmployeeId: json['responsible_employee_id'] as String?,
      objectId: json['object_id'] as String?,
      actNumber: json['act_number'] as String?,
      comment: json['comment'] as String?,
      operationId: json['operation_id'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      createdBy: json['created_by'] as String?,
      itemName: json['item_name'] as String?,
      inventoryNumber: json['inventory_number'] as String?,
    );

Map<String, dynamic> _$TmcWriteOffModelToJson(_TmcWriteOffModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'company_id': instance.companyId,
      'item_id': instance.itemId,
      'unit_id': instance.unitId,
      'written_off_at': tmcDateOnlyToJson(instance.writtenOffAt),
      'reason': _$TmcWriteOffReasonEnumMap[instance.reason]!,
      'quantity': instance.quantity,
      'condition_id': instance.conditionId,
      'book_value': instance.bookValue,
      'responsible_employee_id': instance.responsibleEmployeeId,
      'object_id': instance.objectId,
      'act_number': instance.actNumber,
      'comment': instance.comment,
      'operation_id': instance.operationId,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'created_by': instance.createdBy,
    };

const _$TmcWriteOffReasonEnumMap = {
  TmcWriteOffReason.wear: 'wear',
  TmcWriteOffReason.breakdown: 'breakdown',
  TmcWriteOffReason.loss: 'loss',
  TmcWriteOffReason.shortage: 'shortage',
  TmcWriteOffReason.obsolescence: 'obsolescence',
  TmcWriteOffReason.endOfLife: 'end_of_life',
  TmcWriteOffReason.other: 'other',
};
