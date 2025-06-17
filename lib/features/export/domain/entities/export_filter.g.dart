// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_filter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ExportFilter _$ExportFilterFromJson(Map<String, dynamic> json) =>
    _ExportFilter(
      dateFrom: DateTime.parse(json['dateFrom'] as String),
      dateTo: DateTime.parse(json['dateTo'] as String),
      objectIds: (json['objectIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      contractIds: (json['contractIds'] as List<dynamic>?)
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

Map<String, dynamic> _$ExportFilterToJson(_ExportFilter instance) =>
    <String, dynamic>{
      'dateFrom': instance.dateFrom.toIso8601String(),
      'dateTo': instance.dateTo.toIso8601String(),
      'objectIds': instance.objectIds,
      'contractIds': instance.contractIds,
      'systems': instance.systems,
      'subsystems': instance.subsystems,
    };
