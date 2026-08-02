// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tmc_inventory_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TmcInventoryItemModel _$TmcInventoryItemModelFromJson(
  Map<String, dynamic> json,
) => _TmcInventoryItemModel(
  id: json['id'] as String,
  companyId: json['company_id'] as String,
  inventoryId: json['inventory_id'] as String,
  itemId: json['item_id'] as String,
  unitId: json['unit_id'] as String?,
  systemQuantity: (json['system_quantity'] as num?)?.toDouble() ?? 0,
  actualQuantity: (json['actual_quantity'] as num?)?.toDouble(),
  surplus: (json['surplus'] as num?)?.toDouble(),
  shortage: (json['shortage'] as num?)?.toDouble(),
  conditionId: json['condition_id'] as String?,
  comment: json['comment'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  itemName: json['item_name'] as String?,
  inventoryNumber: json['inventory_number'] as String?,
);

Map<String, dynamic> _$TmcInventoryItemModelToJson(
  _TmcInventoryItemModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'company_id': instance.companyId,
  'inventory_id': instance.inventoryId,
  'item_id': instance.itemId,
  'unit_id': instance.unitId,
  'system_quantity': instance.systemQuantity,
  'actual_quantity': instance.actualQuantity,
  'surplus': instance.surplus,
  'shortage': instance.shortage,
  'condition_id': instance.conditionId,
  'comment': instance.comment,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};

_TmcInventoryModel _$TmcInventoryModelFromJson(Map<String, dynamic> json) =>
    _TmcInventoryModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      title: json['title'] as String,
      scopeType:
          $enumDecodeNullable(
            _$TmcInventoryScopeTypeEnumMap,
            json['scope_type'],
          ) ??
          TmcInventoryScopeType.company,
      warehouseId: json['warehouse_id'] as String?,
      objectId: json['object_id'] as String?,
      employeeId: json['employee_id'] as String?,
      categoryId: json['category_id'] as String?,
      status:
          $enumDecodeNullable(_$TmcInventoryStatusEnumMap, json['status']) ??
          TmcInventoryStatus.draft,
      startedAt: DateTime.parse(json['started_at'] as String),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
      comment: json['comment'] as String?,
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
                    TmcInventoryItemModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );

Map<String, dynamic> _$TmcInventoryModelToJson(_TmcInventoryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'company_id': instance.companyId,
      'title': instance.title,
      'scope_type': _$TmcInventoryScopeTypeEnumMap[instance.scopeType]!,
      'warehouse_id': instance.warehouseId,
      'object_id': instance.objectId,
      'employee_id': instance.employeeId,
      'category_id': instance.categoryId,
      'status': _$TmcInventoryStatusEnumMap[instance.status]!,
      'started_at': instance.startedAt.toIso8601String(),
      'completed_at': instance.completedAt?.toIso8601String(),
      'comment': instance.comment,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'created_by': instance.createdBy,
    };

const _$TmcInventoryScopeTypeEnumMap = {
  TmcInventoryScopeType.company: 'company',
  TmcInventoryScopeType.warehouse: 'warehouse',
  TmcInventoryScopeType.object: 'object',
  TmcInventoryScopeType.employee: 'employee',
  TmcInventoryScopeType.category: 'category',
  TmcInventoryScopeType.items: 'items',
};

const _$TmcInventoryStatusEnumMap = {
  TmcInventoryStatus.draft: 'draft',
  TmcInventoryStatus.inProgress: 'in_progress',
  TmcInventoryStatus.completed: 'completed',
  TmcInventoryStatus.cancelled: 'cancelled',
};
