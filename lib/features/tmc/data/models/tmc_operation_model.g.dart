// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tmc_operation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TmcOperationItemModel _$TmcOperationItemModelFromJson(
  Map<String, dynamic> json,
) => _TmcOperationItemModel(
  id: json['id'] as String,
  companyId: json['company_id'] as String,
  operationId: json['operation_id'] as String,
  itemId: json['item_id'] as String,
  unitId: json['unit_id'] as String?,
  quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
  unitPrice: (json['unit_price'] as num?)?.toDouble(),
  conditionId: json['condition_id'] as String?,
  completenessNote: json['completeness_note'] as String?,
  comment: json['comment'] as String?,
  clothingSize: json['clothing_size'] as String?,
  heightCm: (json['height_cm'] as num?)?.toDouble(),
  season: json['season'] as String?,
  serviceLifeDays: (json['service_life_days'] as num?)?.toInt(),
  nextReplacementDate: tmcParseDate(json['next_replacement_date']),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  itemName: json['item_name'] as String?,
  inventoryNumber: json['inventory_number'] as String?,
);

Map<String, dynamic> _$TmcOperationItemModelToJson(
  _TmcOperationItemModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'company_id': instance.companyId,
  'operation_id': instance.operationId,
  'item_id': instance.itemId,
  'unit_id': instance.unitId,
  'quantity': instance.quantity,
  'unit_price': instance.unitPrice,
  'condition_id': instance.conditionId,
  'completeness_note': instance.completenessNote,
  'comment': instance.comment,
  'clothing_size': instance.clothingSize,
  'height_cm': instance.heightCm,
  'season': instance.season,
  'service_life_days': instance.serviceLifeDays,
  'next_replacement_date': tmcDateOnlyToJson(instance.nextReplacementDate),
  'created_at': instance.createdAt?.toIso8601String(),
};

_TmcOperationModel _$TmcOperationModelFromJson(Map<String, dynamic> json) =>
    _TmcOperationModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      operationType: $enumDecode(
        _$TmcOperationTypeEnumMap,
        json['operation_type'],
      ),
      operatedAt: DateTime.parse(json['operated_at'] as String),
      documentNumber: json['document_number'] as String?,
      basis: json['basis'] as String?,
      comment: json['comment'] as String?,
      fromLocationType: $enumDecodeNullable(
        _$TmcLocationTypeEnumMap,
        json['from_location_type'],
      ),
      fromWarehouseId: json['from_warehouse_id'] as String?,
      fromObjectId: json['from_object_id'] as String?,
      fromEmployeeId: json['from_employee_id'] as String?,
      fromLocationNote: json['from_location_note'] as String?,
      toLocationType: $enumDecodeNullable(
        _$TmcLocationTypeEnumMap,
        json['to_location_type'],
      ),
      toWarehouseId: json['to_warehouse_id'] as String?,
      toObjectId: json['to_object_id'] as String?,
      toEmployeeId: json['to_employee_id'] as String?,
      toLocationNote: json['to_location_note'] as String?,
      responsibleEmployeeId: json['responsible_employee_id'] as String?,
      objectId: json['object_id'] as String?,
      reversesOperationId: json['reverses_operation_id'] as String?,
      plannedReturnDate: tmcParseDate(json['planned_return_date']),
      conditionId: json['condition_id'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      createdBy: json['created_by'] as String?,
      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (e) =>
                    TmcOperationItemModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );

Map<String, dynamic> _$TmcOperationModelToJson(_TmcOperationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'company_id': instance.companyId,
      'operation_type': _$TmcOperationTypeEnumMap[instance.operationType]!,
      'operated_at': instance.operatedAt.toIso8601String(),
      'document_number': instance.documentNumber,
      'basis': instance.basis,
      'comment': instance.comment,
      'from_location_type': _$TmcLocationTypeEnumMap[instance.fromLocationType],
      'from_warehouse_id': instance.fromWarehouseId,
      'from_object_id': instance.fromObjectId,
      'from_employee_id': instance.fromEmployeeId,
      'from_location_note': instance.fromLocationNote,
      'to_location_type': _$TmcLocationTypeEnumMap[instance.toLocationType],
      'to_warehouse_id': instance.toWarehouseId,
      'to_object_id': instance.toObjectId,
      'to_employee_id': instance.toEmployeeId,
      'to_location_note': instance.toLocationNote,
      'responsible_employee_id': instance.responsibleEmployeeId,
      'object_id': instance.objectId,
      'reverses_operation_id': instance.reversesOperationId,
      'planned_return_date': tmcDateOnlyToJson(instance.plannedReturnDate),
      'condition_id': instance.conditionId,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'created_by': instance.createdBy,
    };

const _$TmcOperationTypeEnumMap = {
  TmcOperationType.receipt: 'receipt',
  TmcOperationType.issue: 'issue',
  TmcOperationType.returnFromEmployee: 'return_from_employee',
  TmcOperationType.transferToObject: 'transfer_to_object',
  TmcOperationType.returnFromObject: 'return_from_object',
  TmcOperationType.moveBetweenObjects: 'move_between_objects',
  TmcOperationType.moveBetweenWarehouses: 'move_between_warehouses',
  TmcOperationType.transferBetweenEmployees: 'transfer_between_employees',
  TmcOperationType.reserve: 'reserve',
  TmcOperationType.unreserve: 'unreserve',
  TmcOperationType.sendToRepair: 'send_to_repair',
  TmcOperationType.returnFromRepair: 'return_from_repair',
  TmcOperationType.changeCondition: 'change_condition',
  TmcOperationType.inventoryAdjust: 'inventory_adjust',
  TmcOperationType.writeOff: 'write_off',
  TmcOperationType.shortage: 'shortage',
  TmcOperationType.correction: 'correction',
};

const _$TmcLocationTypeEnumMap = {
  TmcLocationType.warehouse: 'warehouse',
  TmcLocationType.object: 'object',
  TmcLocationType.employee: 'employee',
  TmcLocationType.office: 'office',
  TmcLocationType.repairOrg: 'repair_org',
  TmcLocationType.other: 'other',
};
