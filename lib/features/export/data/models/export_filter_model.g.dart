// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_filter_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ExportFilterModel _$ExportFilterModelFromJson(Map<String, dynamic> json) =>
    _ExportFilterModel(
      dateFrom: DateTime.parse(json['date_from'] as String),
      dateTo: DateTime.parse(json['date_to'] as String),
      objectIds: (json['object_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      contractIds: (json['contract_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      systems: (json['systems'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      subsystems: (json['subsystems'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$ExportFilterModelToJson(_ExportFilterModel instance) =>
    <String, dynamic>{
      'date_from': instance.dateFrom.toIso8601String(),
      'date_to': instance.dateTo.toIso8601String(),
      'object_ids': instance.objectIds,
      'contract_ids': instance.contractIds,
      'systems': instance.systems,
      'subsystems': instance.subsystems,
    };
