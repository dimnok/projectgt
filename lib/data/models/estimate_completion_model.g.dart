// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'estimate_completion_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EstimateCompletionModel _$EstimateCompletionModelFromJson(
  Map<String, dynamic> json,
) => _EstimateCompletionModel(
  estimateId: json['estimate_id'] == null
      ? ''
      : _parseString(json['estimate_id']),
  objectId: json['object_id'] == null ? '' : _parseString(json['object_id']),
  contractId: json['contract_id'] == null
      ? ''
      : _parseString(json['contract_id']),
  system: json['system'] as String? ?? '',
  subsystem: json['subsystem'] as String? ?? '',
  number: json['number'] as String? ?? '',
  name: json['name'] as String? ?? '',
  unit: json['unit'] as String? ?? '',
  quantity: json['quantity'] == null ? 0.0 : _parseDouble(json['quantity']),
  total: json['total'] == null ? 0.0 : _parseDouble(json['total']),
  completedQuantity: json['completed_quantity'] == null
      ? 0.0
      : _parseDouble(json['completed_quantity']),
  completedTotal: json['completed_total'] == null
      ? 0.0
      : _parseDouble(json['completed_total']),
  percentage: json['percentage'] == null
      ? 0.0
      : _parseDouble(json['percentage']),
  remainingQuantity: json['remaining_quantity'] == null
      ? 0.0
      : _parseDouble(json['remaining_quantity']),
);

Map<String, dynamic> _$EstimateCompletionModelToJson(
  _EstimateCompletionModel instance,
) => <String, dynamic>{
  'estimate_id': instance.estimateId,
  'object_id': instance.objectId,
  'contract_id': instance.contractId,
  'system': instance.system,
  'subsystem': instance.subsystem,
  'number': instance.number,
  'name': instance.name,
  'unit': instance.unit,
  'quantity': instance.quantity,
  'total': instance.total,
  'completed_quantity': instance.completedQuantity,
  'completed_total': instance.completedTotal,
  'percentage': instance.percentage,
  'remaining_quantity': instance.remainingQuantity,
};
