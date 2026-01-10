// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_trip_rate_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BusinessTripRateModel _$BusinessTripRateModelFromJson(
  Map<String, dynamic> json,
) => _BusinessTripRateModel(
  id: json['id'] as String,
  objectId: json['object_id'] as String,
  employeeId: json['employee_id'] as String?,
  rate: (json['rate'] as num).toDouble(),
  minimumHours: (json['minimum_hours'] as num?)?.toDouble() ?? 0.0,
  validFrom: DateTime.parse(json['valid_from'] as String),
  validTo: json['valid_to'] == null
      ? null
      : DateTime.parse(json['valid_to'] as String),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  createdBy: json['created_by'] as String?,
);

Map<String, dynamic> _$BusinessTripRateModelToJson(
  _BusinessTripRateModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'object_id': instance.objectId,
  'employee_id': instance.employeeId,
  'rate': instance.rate,
  'minimum_hours': instance.minimumHours,
  'valid_from': instance.validFrom.toIso8601String(),
  'valid_to': instance.validTo?.toIso8601String(),
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'created_by': instance.createdBy,
};
