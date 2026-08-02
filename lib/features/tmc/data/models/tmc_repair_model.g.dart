// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tmc_repair_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TmcRepairModel _$TmcRepairModelFromJson(Map<String, dynamic> json) =>
    _TmcRepairModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      itemId: json['item_id'] as String,
      unitId: json['unit_id'] as String?,
      sentAt: tmcParseRequiredDate(json['sent_at']),
      reason: json['reason'] as String?,
      faultDescription: json['fault_description'] as String?,
      repairOrgName: json['repair_org_name'] as String?,
      responsibleEmployeeId: json['responsible_employee_id'] as String?,
      estimatedCost: (json['estimated_cost'] as num?)?.toDouble(),
      actualCost: (json['actual_cost'] as num?)?.toDouble(),
      completedAt: tmcParseDate(json['completed_at']),
      result: json['result'] as String?,
      conditionAfterId: json['condition_after_id'] as String?,
      repairWarrantyUntil: tmcParseDate(json['repair_warranty_until']),
      status:
          $enumDecodeNullable(_$TmcRepairStatusEnumMap, json['status']) ??
          TmcRepairStatus.open,
      sendOperationId: json['send_operation_id'] as String?,
      returnOperationId: json['return_operation_id'] as String?,
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

Map<String, dynamic> _$TmcRepairModelToJson(_TmcRepairModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'company_id': instance.companyId,
      'item_id': instance.itemId,
      'unit_id': instance.unitId,
      'sent_at': tmcDateOnlyToJson(instance.sentAt),
      'reason': instance.reason,
      'fault_description': instance.faultDescription,
      'repair_org_name': instance.repairOrgName,
      'responsible_employee_id': instance.responsibleEmployeeId,
      'estimated_cost': instance.estimatedCost,
      'actual_cost': instance.actualCost,
      'completed_at': tmcDateOnlyToJson(instance.completedAt),
      'result': instance.result,
      'condition_after_id': instance.conditionAfterId,
      'repair_warranty_until': tmcDateOnlyToJson(instance.repairWarrantyUntil),
      'status': _$TmcRepairStatusEnumMap[instance.status]!,
      'send_operation_id': instance.sendOperationId,
      'return_operation_id': instance.returnOperationId,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'created_by': instance.createdBy,
    };

const _$TmcRepairStatusEnumMap = {
  TmcRepairStatus.open: 'open',
  TmcRepairStatus.completed: 'completed',
  TmcRepairStatus.cancelled: 'cancelled',
};
