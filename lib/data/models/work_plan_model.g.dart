// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_plan_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WorkPlanModel _$WorkPlanModelFromJson(Map<String, dynamic> json) =>
    _WorkPlanModel(
      id: json['id'] as String?,
      companyId: json['company_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdBy: json['created_by'] as String,
      date: DateTime.parse(json['date'] as String),
      objectId: json['object_id'] as String,
      objectName: json['object_name'] as String?,
      objectAddress: json['object_address'] as String?,
      workBlocks:
          (json['work_blocks'] as List<dynamic>?)
              ?.map((e) => WorkBlockModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$WorkPlanModelToJson(_WorkPlanModel instance) =>
    <String, dynamic>{
      if (instance.id case final value?) 'id': value,
      'company_id': instance.companyId,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'created_by': instance.createdBy,
      'date': instance.date.toIso8601String(),
      'object_id': instance.objectId,
      if (instance.objectName case final value?) 'object_name': value,
      if (instance.objectAddress case final value?) 'object_address': value,
      'work_blocks': instance.workBlocks.map((e) => e.toJson()).toList(),
    };

_WorkPlanItemModel _$WorkPlanItemModelFromJson(Map<String, dynamic> json) =>
    _WorkPlanItemModel(
      companyId: json['company_id'] as String,
      estimateId: json['estimate_id'] as String,
      name: json['name'] as String,
      unit: json['unit'] as String,
      price: (json['price'] as num).toDouble(),
      plannedQuantity: (json['planned_quantity'] as num?)?.toDouble() ?? 0,
      actualQuantity: (json['actual_quantity'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$WorkPlanItemModelToJson(_WorkPlanItemModel instance) =>
    <String, dynamic>{
      'company_id': instance.companyId,
      'estimate_id': instance.estimateId,
      'name': instance.name,
      'unit': instance.unit,
      'price': instance.price,
      'planned_quantity': instance.plannedQuantity,
      'actual_quantity': instance.actualQuantity,
    };

_WorkBlockModel _$WorkBlockModelFromJson(Map<String, dynamic> json) =>
    _WorkBlockModel(
      id: json['id'] as String?,
      companyId: json['company_id'] as String,
      responsibleId: json['responsible_id'] as String?,
      workerIds:
          (json['worker_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      section: json['section'] as String?,
      floor: json['floor'] as String?,
      system: json['system'] as String,
      selectedWorks:
          (json['work_plan_items'] as List<dynamic>?)
              ?.map(
                (e) => WorkPlanItemModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );

Map<String, dynamic> _$WorkBlockModelToJson(_WorkBlockModel instance) =>
    <String, dynamic>{
      if (instance.id case final value?) 'id': value,
      'company_id': instance.companyId,
      if (instance.responsibleId case final value?) 'responsible_id': value,
      'worker_ids': instance.workerIds,
      if (instance.section case final value?) 'section': value,
      if (instance.floor case final value?) 'floor': value,
      'system': instance.system,
      'work_plan_items': instance.selectedWorks.map((e) => e.toJson()).toList(),
    };
