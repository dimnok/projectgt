// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contract_file_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ContractFileModel _$ContractFileModelFromJson(Map<String, dynamic> json) =>
    _ContractFileModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      contractId: json['contract_id'] as String,
      name: json['name'] as String,
      filePath: json['file_path'] as String,
      size: (json['size'] as num).toInt(),
      type: json['type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      createdBy: json['created_by'] as String,
    );

Map<String, dynamic> _$ContractFileModelToJson(_ContractFileModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'company_id': instance.companyId,
      'contract_id': instance.contractId,
      'name': instance.name,
      'file_path': instance.filePath,
      'size': instance.size,
      'type': instance.type,
      'created_at': instance.createdAt.toIso8601String(),
      'created_by': instance.createdBy,
    };
