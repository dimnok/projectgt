// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contractor_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ContractorModel _$ContractorModelFromJson(Map<String, dynamic> json) =>
    _ContractorModel(
      id: json['id'] as String,
      logoUrl: json['logo_url'] as String?,
      fullName: json['full_name'] as String,
      shortName: json['short_name'] as String,
      inn: json['inn'] as String,
      director: json['director'] as String,
      legalAddress: json['legal_address'] as String,
      actualAddress: json['actual_address'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
      type: $enumDecode(_$ContractorTypeEnumMap, json['type']),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$ContractorModelToJson(_ContractorModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'logo_url': instance.logoUrl,
      'full_name': instance.fullName,
      'short_name': instance.shortName,
      'inn': instance.inn,
      'director': instance.director,
      'legal_address': instance.legalAddress,
      'actual_address': instance.actualAddress,
      'phone': instance.phone,
      'email': instance.email,
      'type': _$ContractorTypeEnumMap[instance.type]!,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$ContractorTypeEnumMap = {
  ContractorType.customer: 'customer',
  ContractorType.contractor: 'contractor',
  ContractorType.supplier: 'supplier',
};
