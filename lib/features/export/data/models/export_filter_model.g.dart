// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_filter_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ExportFilterModel _$ExportFilterModelFromJson(Map<String, dynamic> json) =>
    _ExportFilterModel(
      dateFrom: DateTime.parse(json['date_from'] as String),
      dateTo: DateTime.parse(json['date_to'] as String),
      objectId: json['object_id'] as String?,
      contractId: json['contract_id'] as String?,
      system: json['system'] as String?,
      subsystem: json['subsystem'] as String?,
    );

Map<String, dynamic> _$ExportFilterModelToJson(_ExportFilterModel instance) =>
    <String, dynamic>{
      'date_from': instance.dateFrom.toIso8601String(),
      'date_to': instance.dateTo.toIso8601String(),
      'object_id': instance.objectId,
      'contract_id': instance.contractId,
      'system': instance.system,
      'subsystem': instance.subsystem,
    };
