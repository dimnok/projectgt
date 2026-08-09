// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settlement_file_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SettlementFileModel _$SettlementFileModelFromJson(Map<String, dynamic> json) =>
    _SettlementFileModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      settlementOperationId: json['settlement_operation_id'] as String,
      name: json['name'] as String,
      filePath: json['file_path'] as String,
      size: (json['size'] as num).toInt(),
      type: json['type'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      createdBy: json['created_by'] as String?,
    );

Map<String, dynamic> _$SettlementFileModelToJson(
  _SettlementFileModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'company_id': instance.companyId,
  'settlement_operation_id': instance.settlementOperationId,
  'name': instance.name,
  'file_path': instance.filePath,
  'size': instance.size,
  'type': instance.type,
  'description': instance.description,
  'created_at': instance.createdAt.toIso8601String(),
  'created_by': instance.createdBy,
};
