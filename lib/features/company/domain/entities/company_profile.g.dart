// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'company_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CompanyProfile _$CompanyProfileFromJson(Map<String, dynamic> json) =>
    _CompanyProfile(
      id: json['id'] as String,
      nameFull: json['name_full'] as String,
      nameShort: json['name_short'] as String,
      logoUrl: json['logo_url'] as String?,
      website: json['website'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      activityDescription: json['activity_description'] as String?,
      inn: json['inn'] as String?,
      kpp: json['kpp'] as String?,
      ogrn: json['ogrn'] as String?,
      okpo: json['okpo'] as String?,
      legalAddress: json['legal_address'] as String?,
      actualAddress: json['actual_address'] as String?,
      directorName: json['director_name'] as String?,
      directorPosition: json['director_position'] as String?,
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

Map<String, dynamic> _$CompanyProfileToJson(_CompanyProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name_full': instance.nameFull,
      'name_short': instance.nameShort,
      'logo_url': instance.logoUrl,
      'website': instance.website,
      'email': instance.email,
      'phone': instance.phone,
      'activity_description': instance.activityDescription,
      'inn': instance.inn,
      'kpp': instance.kpp,
      'ogrn': instance.ogrn,
      'okpo': instance.okpo,
      'legal_address': instance.legalAddress,
      'actual_address': instance.actualAddress,
      'director_name': instance.directorName,
      'director_position': instance.directorPosition,
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
