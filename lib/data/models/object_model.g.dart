// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'object_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ObjectModel _$ObjectModelFromJson(Map<String, dynamic> json) => _ObjectModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      description: json['description'] as String?,
      businessTripAmount: json['business_trip_amount'] as num? ?? 0,
    );

Map<String, dynamic> _$ObjectModelToJson(_ObjectModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'address': instance.address,
      'description': instance.description,
      'business_trip_amount': instance.businessTripAmount,
    };
