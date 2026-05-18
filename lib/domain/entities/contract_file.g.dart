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
      description: json['description'] as String?,
      displayOrder: (json['display_order'] as num).toInt(),
      documentStatus:
          $enumDecodeNullable(
            _$ContractDocumentStatusEnumMap,
            json['document_status'],
          ) ??
          ContractDocumentStatus.draft,
      documentVersion: (json['document_version'] as num?)?.toInt() ?? 1,
      isAmendment: json['is_amendment'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      createdBy: json['createdBy'] as String,
    );

Map<String, dynamic> _$ContractFileToJson(
  _ContractFile instance,
) => <String, dynamic>{
  'id': instance.id,
  'companyId': instance.companyId,
  'contractId': instance.contractId,
  'name': instance.name,
  'filePath': instance.filePath,
  'size': instance.size,
  'type': instance.type,
  'description': instance.description,
  'display_order': instance.displayOrder,
  'document_status': _$ContractDocumentStatusEnumMap[instance.documentStatus]!,
  'document_version': instance.documentVersion,
  'is_amendment': instance.isAmendment,
  'createdAt': instance.createdAt.toIso8601String(),
  'createdBy': instance.createdBy,
};

const _$ContractDocumentStatusEnumMap = {
  ContractDocumentStatus.draft: 'draft',
  ContractDocumentStatus.pendingApproval: 'pending_approval',
  ContractDocumentStatus.approved: 'approved',
  ContractDocumentStatus.signed: 'signed',
  ContractDocumentStatus.rejected: 'rejected',
  ContractDocumentStatus.obsolete: 'obsolete',
};
