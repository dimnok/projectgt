// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contract_file.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ContractFile _$ContractFileFromJson(Map<String, dynamic> json) =>
    _ContractFile(
      id: json['id'] as String,
      companyId: json['companyId'] as String,
      contractId: json['contractId'] as String,
      name: json['name'] as String,
      filePath: json['filePath'] as String,
      size: (json['size'] as num).toInt(),
      type: json['type'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      createdBy: json['createdBy'] as String,
    );

Map<String, dynamic> _$ContractFileToJson(_ContractFile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'companyId': instance.companyId,
      'contractId': instance.contractId,
      'name': instance.name,
      'filePath': instance.filePath,
      'size': instance.size,
      'type': instance.type,
      'createdAt': instance.createdAt.toIso8601String(),
      'createdBy': instance.createdBy,
    };
