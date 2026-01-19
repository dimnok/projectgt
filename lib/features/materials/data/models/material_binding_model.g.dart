// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'material_binding_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MaterialBindingModel _$MaterialBindingModelFromJson(
  Map<String, dynamic> json,
) => _MaterialBindingModel(
  name: json['name'] as String,
  unit: json['unit'] as String?,
  receiptNumber: json['receipt_number'] as String?,
  bindingStatus: $enumDecode(
    _$MaterialBindingStatusEnumMap,
    json['binding_status'],
  ),
  linkedEstimateName: json['linked_estimate_name'] as String?,
  linkedEstimateNames:
      (json['linked_estimate_names'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  linkedEstimateId: json['linked_estimate_id'] as String?,
  aliasId: json['alias_id'] as String?,
);

Map<String, dynamic> _$MaterialBindingModelToJson(
  _MaterialBindingModel instance,
) => <String, dynamic>{
  'name': instance.name,
  'unit': instance.unit,
  'receipt_number': instance.receiptNumber,
  'binding_status': _$MaterialBindingStatusEnumMap[instance.bindingStatus]!,
  'linked_estimate_name': instance.linkedEstimateName,
  'linked_estimate_names': instance.linkedEstimateNames,
  'linked_estimate_id': instance.linkedEstimateId,
  'alias_id': instance.aliasId,
};

const _$MaterialBindingStatusEnumMap = {
  MaterialBindingStatus.available: 'available',
  MaterialBindingStatus.current: 'current',
  MaterialBindingStatus.conflict: 'conflict',
  MaterialBindingStatus.shared: 'shared',
};
