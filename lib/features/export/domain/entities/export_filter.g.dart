// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_filter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ExportFilter _$ExportFilterFromJson(Map<String, dynamic> json) =>
    _ExportFilter(
      dateFrom: DateTime.parse(json['dateFrom'] as String),
      dateTo: DateTime.parse(json['dateTo'] as String),
      objectId: json['objectId'] as String?,
      contractId: json['contractId'] as String?,
      system: json['system'] as String?,
      subsystem: json['subsystem'] as String?,
    );

Map<String, dynamic> _$ExportFilterToJson(_ExportFilter instance) =>
    <String, dynamic>{
      'dateFrom': instance.dateFrom.toIso8601String(),
      'dateTo': instance.dateTo.toIso8601String(),
      'objectId': instance.objectId,
      'contractId': instance.contractId,
      'system': instance.system,
      'subsystem': instance.subsystem,
    };
