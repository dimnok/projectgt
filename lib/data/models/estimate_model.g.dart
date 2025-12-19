// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'estimate_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EstimateModel _$EstimateModelFromJson(Map<String, dynamic> json) =>
    _EstimateModel(
      id: json['id'] as String?,
      system: json['system'] as String,
      subsystem: json['subsystem'] as String,
      number: _numberFromJson(json['number']),
      name: json['name'] as String,
      article: json['article'] as String,
      manufacturer: json['manufacturer'] as String,
      unit: json['unit'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      objectId: json['object_id'] as String?,
      contractId: json['contract_id'] as String?,
      contractNumber: json['contract_number'] as String?,
      estimateTitle: json['estimate_title'] as String?,
    );

Map<String, dynamic> _$EstimateModelToJson(_EstimateModel instance) =>
    <String, dynamic>{
      if (instance.id case final value?) 'id': value,
      'system': instance.system,
      'subsystem': instance.subsystem,
      'number': instance.number,
      'name': instance.name,
      'article': instance.article,
      'manufacturer': instance.manufacturer,
      'unit': instance.unit,
      'quantity': instance.quantity,
      'price': instance.price,
      'total': instance.total,
      if (instance.objectId case final value?) 'object_id': value,
      if (instance.contractId case final value?) 'contract_id': value,
      if (instance.contractNumber case final value?) 'contract_number': value,
      if (instance.estimateTitle case final value?) 'estimate_title': value,
    };
