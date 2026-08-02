// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tmc_unit_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TmcUnitModel _$TmcUnitModelFromJson(Map<String, dynamic> json) =>
    _TmcUnitModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      itemId: json['item_id'] as String,
      inventoryNumber: json['inventory_number'] as String,
      serialNumber: json['serial_number'] as String?,
      barcode: json['barcode'] as String?,
      purchaseDate: tmcParseDate(json['purchase_date']),
      purchasePrice: (json['purchase_price'] as num?)?.toDouble() ?? 0,
      conditionId: json['condition_id'] as String?,
      status:
          $enumDecodeNullable(_$TmcUnitStatusEnumMap, json['status']) ??
          TmcUnitStatus.inStock,
      locationType:
          $enumDecodeNullable(
            _$TmcLocationTypeEnumMap,
            json['location_type'],
          ) ??
          TmcLocationType.warehouse,
      warehouseId: json['warehouse_id'] as String?,
      objectId: json['object_id'] as String?,
      employeeId: json['employee_id'] as String?,
      locationNote: json['location_note'] as String?,
      usageObjectId: json['usage_object_id'] as String?,
      responsibleEmployeeId: json['responsible_employee_id'] as String?,
      lastIssueDate: tmcParseDate(json['last_issue_date']),
      nextInspectionDate: tmcParseDate(json['next_inspection_date']),
      warrantyUntil: tmcParseDate(json['warranty_until']),
      comment: json['comment'] as String?,
      photoUrl: json['photo_url'] as String?,
      isArchived: json['is_archived'] as bool? ?? false,
      archivedAt: json['archived_at'] == null
          ? null
          : DateTime.parse(json['archived_at'] as String),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      createdBy: json['created_by'] as String?,
      itemName: json['item_name'] as String?,
      conditionName: json['condition_name'] as String?,
      warehouseName: json['warehouse_name'] as String?,
      objectName: json['object_name'] as String?,
      employeeName: json['employee_name'] as String?,
    );

Map<String, dynamic> _$TmcUnitModelToJson(_TmcUnitModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'company_id': instance.companyId,
      'item_id': instance.itemId,
      'inventory_number': instance.inventoryNumber,
      'serial_number': instance.serialNumber,
      'barcode': instance.barcode,
      'purchase_date': tmcDateOnlyToJson(instance.purchaseDate),
      'purchase_price': instance.purchasePrice,
      'condition_id': instance.conditionId,
      'status': _$TmcUnitStatusEnumMap[instance.status]!,
      'location_type': _$TmcLocationTypeEnumMap[instance.locationType]!,
      'warehouse_id': instance.warehouseId,
      'object_id': instance.objectId,
      'employee_id': instance.employeeId,
      'location_note': instance.locationNote,
      'usage_object_id': instance.usageObjectId,
      'responsible_employee_id': instance.responsibleEmployeeId,
      'last_issue_date': tmcDateOnlyToJson(instance.lastIssueDate),
      'next_inspection_date': tmcDateOnlyToJson(instance.nextInspectionDate),
      'warranty_until': tmcDateOnlyToJson(instance.warrantyUntil),
      'comment': instance.comment,
      'photo_url': instance.photoUrl,
      'is_archived': instance.isArchived,
      'archived_at': instance.archivedAt?.toIso8601String(),
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'created_by': instance.createdBy,
    };

const _$TmcUnitStatusEnumMap = {
  TmcUnitStatus.inStock: 'in_stock',
  TmcUnitStatus.onObject: 'on_object',
  TmcUnitStatus.issued: 'issued',
  TmcUnitStatus.temporarilyTransferred: 'temporarily_transferred',
  TmcUnitStatus.inRepair: 'in_repair',
  TmcUnitStatus.inService: 'in_service',
  TmcUnitStatus.reserved: 'reserved',
  TmcUnitStatus.lost: 'lost',
  TmcUnitStatus.writtenOff: 'written_off',
};

const _$TmcLocationTypeEnumMap = {
  TmcLocationType.warehouse: 'warehouse',
  TmcLocationType.object: 'object',
  TmcLocationType.employee: 'employee',
  TmcLocationType.office: 'office',
  TmcLocationType.repairOrg: 'repair_org',
  TmcLocationType.other: 'other',
};
