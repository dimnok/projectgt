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
      createdAt: DateTime.parse(json['created_at'] as String),
      createdBy: json['created_by'] as String,
    );

Map<String, dynamic> _$ContractFileModelToJson(
  _ContractFileModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'company_id': instance.companyId,
  'contract_id': instance.contractId,
  'name': instance.name,
  'file_path': instance.filePath,
  'size': instance.size,
  'type': instance.type,
  'description': instance.description,
  'display_order': instance.displayOrder,
  'document_status': _$ContractDocumentStatusEnumMap[instance.documentStatus]!,
  'document_version': instance.documentVersion,
  'is_amendment': instance.isAmendment,
  'created_at': instance.createdAt.toIso8601String(),
  'created_by': instance.createdBy,
};

const _$ContractDocumentStatusEnumMap = {
  ContractDocumentStatus.draft: 'draft',
  ContractDocumentStatus.pendingApproval: 'pending_approval',
  ContractDocumentStatus.approved: 'approved',
  ContractDocumentStatus.signed: 'signed',
  ContractDocumentStatus.rejected: 'rejected',
  ContractDocumentStatus.obsolete: 'obsolete',
};
