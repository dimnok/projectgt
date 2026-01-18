// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grouped_material_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GroupedMaterialItem _$GroupedMaterialItemFromJson(Map<String, dynamic> json) =>
    _GroupedMaterialItem(
      estimateId: json['estimate_id'] as String,
      estimateName: json['estimate_name'] as String,
      estimateUnit: json['estimate_unit'] as String,
      system: json['system'] as String,
      contractNumber: json['contract_number'] as String,
      companyId: json['company_id'] as String,
      totalIncoming: (json['total_incoming'] as num).toDouble(),
      totalUsed: (json['total_used'] as num).toDouble(),
      totalRemaining: (json['total_remaining'] as num).toDouble(),
      batchCount: (json['batch_count'] as num).toInt(),
    );

Map<String, dynamic> _$GroupedMaterialItemToJson(
  _GroupedMaterialItem instance,
) => <String, dynamic>{
  'estimate_id': instance.estimateId,
  'estimate_name': instance.estimateName,
  'estimate_unit': instance.estimateUnit,
  'system': instance.system,
  'contract_number': instance.contractNumber,
  'company_id': instance.companyId,
  'total_incoming': instance.totalIncoming,
  'total_used': instance.totalUsed,
  'total_remaining': instance.totalRemaining,
  'batch_count': instance.batchCount,
};
