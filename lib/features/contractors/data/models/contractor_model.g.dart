// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contractor_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ContractorModel _$ContractorModelFromJson(Map<String, dynamic> json) =>
    _ContractorModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
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
      website: json['website'] as String?,
      activityDescription: json['activity_description'] as String?,
      kpp: json['kpp'] as String?,
      ogrn: json['ogrn'] as String?,
      okpo: json['okpo'] as String?,
      directorBasis: json['director_basis'] as String?,
      directorPhone: json['director_phone'] as String?,
      chiefAccountantName: json['chief_accountant_name'] as String?,
      chiefAccountantPhone: json['chief_accountant_phone'] as String?,
      contactPerson: json['contact_person'] as String?,
      taxationSystem: json['taxation_system'] as String?,
      isVatPayer: json['is_vat_payer'] as bool? ?? false,
      vatRate: (json['vat_rate'] as num?)?.toDouble() ?? 0,
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
      'company_id': instance.companyId,
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
      'website': instance.website,
      'activity_description': instance.activityDescription,
      'kpp': instance.kpp,
      'ogrn': instance.ogrn,
      'okpo': instance.okpo,
      'director_basis': instance.directorBasis,
      'director_phone': instance.directorPhone,
      'chief_accountant_name': instance.chiefAccountantName,
      'chief_accountant_phone': instance.chiefAccountantPhone,
      'contact_person': instance.contactPerson,
      'taxation_system': instance.taxationSystem,
      'is_vat_payer': instance.isVatPayer,
      'vat_rate': instance.vatRate,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$ContractorTypeEnumMap = {
  ContractorType.customer: 'customer',
  ContractorType.contractor: 'contractor',
  ContractorType.supplier: 'supplier',
};
