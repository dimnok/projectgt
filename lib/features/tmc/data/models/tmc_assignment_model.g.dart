// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tmc_assignment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TmcAssignmentModel _$TmcAssignmentModelFromJson(Map<String, dynamic> json) =>
    _TmcAssignmentModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      itemId: json['item_id'] as String,
      unitId: json['unit_id'] as String?,
      employeeId: json['employee_id'] as String,
      objectId: json['object_id'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
      issuedAt: DateTime.parse(json['issued_at'] as String),
      plannedReturnDate: tmcParseDate(json['planned_return_date']),
      conditionId: json['condition_id'] as String?,
      issueOperationId: json['issue_operation_id'] as String?,
      clothingSize: json['clothing_size'] as String?,
      heightCm: (json['height_cm'] as num?)?.toDouble(),
      season: json['season'] as String?,
      serviceLifeDays: (json['service_life_days'] as num?)?.toInt(),
      nextReplacementDate: tmcParseDate(json['next_replacement_date']),
      comment: json['comment'] as String?,
      returnedAt: json['returned_at'] == null
          ? null
          : DateTime.parse(json['returned_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      createdBy: json['created_by'] as String?,
      itemName: json['item_name'] as String?,
      inventoryNumber: json['inventory_number'] as String?,
      employeeName: json['employee_name'] as String?,
      objectName: json['object_name'] as String?,
    );

Map<String, dynamic> _$TmcAssignmentModelToJson(_TmcAssignmentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'company_id': instance.companyId,
      'item_id': instance.itemId,
      'unit_id': instance.unitId,
      'employee_id': instance.employeeId,
      'object_id': instance.objectId,
      'quantity': instance.quantity,
      'issued_at': instance.issuedAt.toIso8601String(),
      'planned_return_date': tmcDateOnlyToJson(instance.plannedReturnDate),
      'condition_id': instance.conditionId,
      'issue_operation_id': instance.issueOperationId,
      'clothing_size': instance.clothingSize,
      'height_cm': instance.heightCm,
      'season': instance.season,
      'service_life_days': instance.serviceLifeDays,
      'next_replacement_date': tmcDateOnlyToJson(instance.nextReplacementDate),
      'comment': instance.comment,
      'returned_at': instance.returnedAt?.toIso8601String(),
      'is_active': instance.isActive,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'created_by': instance.createdBy,
    };
