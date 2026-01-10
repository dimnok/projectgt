// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'company_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CompanyProfile {

 String get id;@JsonKey(name: 'name_full') String get nameFull;@JsonKey(name: 'name_short') String get nameShort;@JsonKey(name: 'logo_url') String? get logoUrl; String? get website; String? get email; String? get phone;@JsonKey(name: 'activity_description') String? get activityDescription; String? get inn; String? get kpp; String? get ogrn; String? get okpo;@JsonKey(name: 'legal_address') String? get legalAddress;@JsonKey(name: 'actual_address') String? get actualAddress;@JsonKey(name: 'director_name') String? get directorName;@JsonKey(name: 'director_position') String? get directorPosition;@JsonKey(name: 'director_basis') String? get directorBasis;@JsonKey(name: 'director_phone') String? get directorPhone;@JsonKey(name: 'chief_accountant_name') String? get chiefAccountantName;@JsonKey(name: 'chief_accountant_phone') String? get chiefAccountantPhone;@JsonKey(name: 'contact_person') String? get contactPerson;@JsonKey(name: 'taxation_system') String? get taxationSystem;@JsonKey(name: 'is_vat_payer') bool get isVatPayer;@JsonKey(name: 'vat_rate') double get vatRate;// Системные поля Multi-tenancy
@JsonKey(name: 'owner_id') String? get ownerId;@JsonKey(name: 'invitation_code') String? get invitationCode;@JsonKey(name: 'is_active') bool get isActive;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;
/// Create a copy of CompanyProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompanyProfileCopyWith<CompanyProfile> get copyWith => _$CompanyProfileCopyWithImpl<CompanyProfile>(this as CompanyProfile, _$identity);

  /// Serializes this CompanyProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompanyProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.nameFull, nameFull) || other.nameFull == nameFull)&&(identical(other.nameShort, nameShort) || other.nameShort == nameShort)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&(identical(other.website, website) || other.website == website)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.activityDescription, activityDescription) || other.activityDescription == activityDescription)&&(identical(other.inn, inn) || other.inn == inn)&&(identical(other.kpp, kpp) || other.kpp == kpp)&&(identical(other.ogrn, ogrn) || other.ogrn == ogrn)&&(identical(other.okpo, okpo) || other.okpo == okpo)&&(identical(other.legalAddress, legalAddress) || other.legalAddress == legalAddress)&&(identical(other.actualAddress, actualAddress) || other.actualAddress == actualAddress)&&(identical(other.directorName, directorName) || other.directorName == directorName)&&(identical(other.directorPosition, directorPosition) || other.directorPosition == directorPosition)&&(identical(other.directorBasis, directorBasis) || other.directorBasis == directorBasis)&&(identical(other.directorPhone, directorPhone) || other.directorPhone == directorPhone)&&(identical(other.chiefAccountantName, chiefAccountantName) || other.chiefAccountantName == chiefAccountantName)&&(identical(other.chiefAccountantPhone, chiefAccountantPhone) || other.chiefAccountantPhone == chiefAccountantPhone)&&(identical(other.contactPerson, contactPerson) || other.contactPerson == contactPerson)&&(identical(other.taxationSystem, taxationSystem) || other.taxationSystem == taxationSystem)&&(identical(other.isVatPayer, isVatPayer) || other.isVatPayer == isVatPayer)&&(identical(other.vatRate, vatRate) || other.vatRate == vatRate)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.invitationCode, invitationCode) || other.invitationCode == invitationCode)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,nameFull,nameShort,logoUrl,website,email,phone,activityDescription,inn,kpp,ogrn,okpo,legalAddress,actualAddress,directorName,directorPosition,directorBasis,directorPhone,chiefAccountantName,chiefAccountantPhone,contactPerson,taxationSystem,isVatPayer,vatRate,ownerId,invitationCode,isActive,createdAt,updatedAt]);

@override
String toString() {
  return 'CompanyProfile(id: $id, nameFull: $nameFull, nameShort: $nameShort, logoUrl: $logoUrl, website: $website, email: $email, phone: $phone, activityDescription: $activityDescription, inn: $inn, kpp: $kpp, ogrn: $ogrn, okpo: $okpo, legalAddress: $legalAddress, actualAddress: $actualAddress, directorName: $directorName, directorPosition: $directorPosition, directorBasis: $directorBasis, directorPhone: $directorPhone, chiefAccountantName: $chiefAccountantName, chiefAccountantPhone: $chiefAccountantPhone, contactPerson: $contactPerson, taxationSystem: $taxationSystem, isVatPayer: $isVatPayer, vatRate: $vatRate, ownerId: $ownerId, invitationCode: $invitationCode, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $CompanyProfileCopyWith<$Res>  {
  factory $CompanyProfileCopyWith(CompanyProfile value, $Res Function(CompanyProfile) _then) = _$CompanyProfileCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'name_full') String nameFull,@JsonKey(name: 'name_short') String nameShort,@JsonKey(name: 'logo_url') String? logoUrl, String? website, String? email, String? phone,@JsonKey(name: 'activity_description') String? activityDescription, String? inn, String? kpp, String? ogrn, String? okpo,@JsonKey(name: 'legal_address') String? legalAddress,@JsonKey(name: 'actual_address') String? actualAddress,@JsonKey(name: 'director_name') String? directorName,@JsonKey(name: 'director_position') String? directorPosition,@JsonKey(name: 'director_basis') String? directorBasis,@JsonKey(name: 'director_phone') String? directorPhone,@JsonKey(name: 'chief_accountant_name') String? chiefAccountantName,@JsonKey(name: 'chief_accountant_phone') String? chiefAccountantPhone,@JsonKey(name: 'contact_person') String? contactPerson,@JsonKey(name: 'taxation_system') String? taxationSystem,@JsonKey(name: 'is_vat_payer') bool isVatPayer,@JsonKey(name: 'vat_rate') double vatRate,@JsonKey(name: 'owner_id') String? ownerId,@JsonKey(name: 'invitation_code') String? invitationCode,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class _$CompanyProfileCopyWithImpl<$Res>
    implements $CompanyProfileCopyWith<$Res> {
  _$CompanyProfileCopyWithImpl(this._self, this._then);

  final CompanyProfile _self;
  final $Res Function(CompanyProfile) _then;

/// Create a copy of CompanyProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nameFull = null,Object? nameShort = null,Object? logoUrl = freezed,Object? website = freezed,Object? email = freezed,Object? phone = freezed,Object? activityDescription = freezed,Object? inn = freezed,Object? kpp = freezed,Object? ogrn = freezed,Object? okpo = freezed,Object? legalAddress = freezed,Object? actualAddress = freezed,Object? directorName = freezed,Object? directorPosition = freezed,Object? directorBasis = freezed,Object? directorPhone = freezed,Object? chiefAccountantName = freezed,Object? chiefAccountantPhone = freezed,Object? contactPerson = freezed,Object? taxationSystem = freezed,Object? isVatPayer = null,Object? vatRate = null,Object? ownerId = freezed,Object? invitationCode = freezed,Object? isActive = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nameFull: null == nameFull ? _self.nameFull : nameFull // ignore: cast_nullable_to_non_nullable
as String,nameShort: null == nameShort ? _self.nameShort : nameShort // ignore: cast_nullable_to_non_nullable
as String,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,website: freezed == website ? _self.website : website // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,activityDescription: freezed == activityDescription ? _self.activityDescription : activityDescription // ignore: cast_nullable_to_non_nullable
as String?,inn: freezed == inn ? _self.inn : inn // ignore: cast_nullable_to_non_nullable
as String?,kpp: freezed == kpp ? _self.kpp : kpp // ignore: cast_nullable_to_non_nullable
as String?,ogrn: freezed == ogrn ? _self.ogrn : ogrn // ignore: cast_nullable_to_non_nullable
as String?,okpo: freezed == okpo ? _self.okpo : okpo // ignore: cast_nullable_to_non_nullable
as String?,legalAddress: freezed == legalAddress ? _self.legalAddress : legalAddress // ignore: cast_nullable_to_non_nullable
as String?,actualAddress: freezed == actualAddress ? _self.actualAddress : actualAddress // ignore: cast_nullable_to_non_nullable
as String?,directorName: freezed == directorName ? _self.directorName : directorName // ignore: cast_nullable_to_non_nullable
as String?,directorPosition: freezed == directorPosition ? _self.directorPosition : directorPosition // ignore: cast_nullable_to_non_nullable
as String?,directorBasis: freezed == directorBasis ? _self.directorBasis : directorBasis // ignore: cast_nullable_to_non_nullable
as String?,directorPhone: freezed == directorPhone ? _self.directorPhone : directorPhone // ignore: cast_nullable_to_non_nullable
as String?,chiefAccountantName: freezed == chiefAccountantName ? _self.chiefAccountantName : chiefAccountantName // ignore: cast_nullable_to_non_nullable
as String?,chiefAccountantPhone: freezed == chiefAccountantPhone ? _self.chiefAccountantPhone : chiefAccountantPhone // ignore: cast_nullable_to_non_nullable
as String?,contactPerson: freezed == contactPerson ? _self.contactPerson : contactPerson // ignore: cast_nullable_to_non_nullable
as String?,taxationSystem: freezed == taxationSystem ? _self.taxationSystem : taxationSystem // ignore: cast_nullable_to_non_nullable
as String?,isVatPayer: null == isVatPayer ? _self.isVatPayer : isVatPayer // ignore: cast_nullable_to_non_nullable
as bool,vatRate: null == vatRate ? _self.vatRate : vatRate // ignore: cast_nullable_to_non_nullable
as double,ownerId: freezed == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String?,invitationCode: freezed == invitationCode ? _self.invitationCode : invitationCode // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _CompanyProfile implements CompanyProfile {
  const _CompanyProfile({required this.id, @JsonKey(name: 'name_full') required this.nameFull, @JsonKey(name: 'name_short') required this.nameShort, @JsonKey(name: 'logo_url') this.logoUrl, this.website, this.email, this.phone, @JsonKey(name: 'activity_description') this.activityDescription, this.inn, this.kpp, this.ogrn, this.okpo, @JsonKey(name: 'legal_address') this.legalAddress, @JsonKey(name: 'actual_address') this.actualAddress, @JsonKey(name: 'director_name') this.directorName, @JsonKey(name: 'director_position') this.directorPosition, @JsonKey(name: 'director_basis') this.directorBasis, @JsonKey(name: 'director_phone') this.directorPhone, @JsonKey(name: 'chief_accountant_name') this.chiefAccountantName, @JsonKey(name: 'chief_accountant_phone') this.chiefAccountantPhone, @JsonKey(name: 'contact_person') this.contactPerson, @JsonKey(name: 'taxation_system') this.taxationSystem, @JsonKey(name: 'is_vat_payer') this.isVatPayer = false, @JsonKey(name: 'vat_rate') this.vatRate = 0, @JsonKey(name: 'owner_id') this.ownerId, @JsonKey(name: 'invitation_code') this.invitationCode, @JsonKey(name: 'is_active') this.isActive = true, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt});
  factory _CompanyProfile.fromJson(Map<String, dynamic> json) => _$CompanyProfileFromJson(json);

@override final  String id;
@override@JsonKey(name: 'name_full') final  String nameFull;
@override@JsonKey(name: 'name_short') final  String nameShort;
@override@JsonKey(name: 'logo_url') final  String? logoUrl;
@override final  String? website;
@override final  String? email;
@override final  String? phone;
@override@JsonKey(name: 'activity_description') final  String? activityDescription;
@override final  String? inn;
@override final  String? kpp;
@override final  String? ogrn;
@override final  String? okpo;
@override@JsonKey(name: 'legal_address') final  String? legalAddress;
@override@JsonKey(name: 'actual_address') final  String? actualAddress;
@override@JsonKey(name: 'director_name') final  String? directorName;
@override@JsonKey(name: 'director_position') final  String? directorPosition;
@override@JsonKey(name: 'director_basis') final  String? directorBasis;
@override@JsonKey(name: 'director_phone') final  String? directorPhone;
@override@JsonKey(name: 'chief_accountant_name') final  String? chiefAccountantName;
@override@JsonKey(name: 'chief_accountant_phone') final  String? chiefAccountantPhone;
@override@JsonKey(name: 'contact_person') final  String? contactPerson;
@override@JsonKey(name: 'taxation_system') final  String? taxationSystem;
@override@JsonKey(name: 'is_vat_payer') final  bool isVatPayer;
@override@JsonKey(name: 'vat_rate') final  double vatRate;
// Системные поля Multi-tenancy
@override@JsonKey(name: 'owner_id') final  String? ownerId;
@override@JsonKey(name: 'invitation_code') final  String? invitationCode;
@override@JsonKey(name: 'is_active') final  bool isActive;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;

/// Create a copy of CompanyProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompanyProfileCopyWith<_CompanyProfile> get copyWith => __$CompanyProfileCopyWithImpl<_CompanyProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CompanyProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CompanyProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.nameFull, nameFull) || other.nameFull == nameFull)&&(identical(other.nameShort, nameShort) || other.nameShort == nameShort)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&(identical(other.website, website) || other.website == website)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.activityDescription, activityDescription) || other.activityDescription == activityDescription)&&(identical(other.inn, inn) || other.inn == inn)&&(identical(other.kpp, kpp) || other.kpp == kpp)&&(identical(other.ogrn, ogrn) || other.ogrn == ogrn)&&(identical(other.okpo, okpo) || other.okpo == okpo)&&(identical(other.legalAddress, legalAddress) || other.legalAddress == legalAddress)&&(identical(other.actualAddress, actualAddress) || other.actualAddress == actualAddress)&&(identical(other.directorName, directorName) || other.directorName == directorName)&&(identical(other.directorPosition, directorPosition) || other.directorPosition == directorPosition)&&(identical(other.directorBasis, directorBasis) || other.directorBasis == directorBasis)&&(identical(other.directorPhone, directorPhone) || other.directorPhone == directorPhone)&&(identical(other.chiefAccountantName, chiefAccountantName) || other.chiefAccountantName == chiefAccountantName)&&(identical(other.chiefAccountantPhone, chiefAccountantPhone) || other.chiefAccountantPhone == chiefAccountantPhone)&&(identical(other.contactPerson, contactPerson) || other.contactPerson == contactPerson)&&(identical(other.taxationSystem, taxationSystem) || other.taxationSystem == taxationSystem)&&(identical(other.isVatPayer, isVatPayer) || other.isVatPayer == isVatPayer)&&(identical(other.vatRate, vatRate) || other.vatRate == vatRate)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.invitationCode, invitationCode) || other.invitationCode == invitationCode)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,nameFull,nameShort,logoUrl,website,email,phone,activityDescription,inn,kpp,ogrn,okpo,legalAddress,actualAddress,directorName,directorPosition,directorBasis,directorPhone,chiefAccountantName,chiefAccountantPhone,contactPerson,taxationSystem,isVatPayer,vatRate,ownerId,invitationCode,isActive,createdAt,updatedAt]);

@override
String toString() {
  return 'CompanyProfile(id: $id, nameFull: $nameFull, nameShort: $nameShort, logoUrl: $logoUrl, website: $website, email: $email, phone: $phone, activityDescription: $activityDescription, inn: $inn, kpp: $kpp, ogrn: $ogrn, okpo: $okpo, legalAddress: $legalAddress, actualAddress: $actualAddress, directorName: $directorName, directorPosition: $directorPosition, directorBasis: $directorBasis, directorPhone: $directorPhone, chiefAccountantName: $chiefAccountantName, chiefAccountantPhone: $chiefAccountantPhone, contactPerson: $contactPerson, taxationSystem: $taxationSystem, isVatPayer: $isVatPayer, vatRate: $vatRate, ownerId: $ownerId, invitationCode: $invitationCode, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$CompanyProfileCopyWith<$Res> implements $CompanyProfileCopyWith<$Res> {
  factory _$CompanyProfileCopyWith(_CompanyProfile value, $Res Function(_CompanyProfile) _then) = __$CompanyProfileCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'name_full') String nameFull,@JsonKey(name: 'name_short') String nameShort,@JsonKey(name: 'logo_url') String? logoUrl, String? website, String? email, String? phone,@JsonKey(name: 'activity_description') String? activityDescription, String? inn, String? kpp, String? ogrn, String? okpo,@JsonKey(name: 'legal_address') String? legalAddress,@JsonKey(name: 'actual_address') String? actualAddress,@JsonKey(name: 'director_name') String? directorName,@JsonKey(name: 'director_position') String? directorPosition,@JsonKey(name: 'director_basis') String? directorBasis,@JsonKey(name: 'director_phone') String? directorPhone,@JsonKey(name: 'chief_accountant_name') String? chiefAccountantName,@JsonKey(name: 'chief_accountant_phone') String? chiefAccountantPhone,@JsonKey(name: 'contact_person') String? contactPerson,@JsonKey(name: 'taxation_system') String? taxationSystem,@JsonKey(name: 'is_vat_payer') bool isVatPayer,@JsonKey(name: 'vat_rate') double vatRate,@JsonKey(name: 'owner_id') String? ownerId,@JsonKey(name: 'invitation_code') String? invitationCode,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class __$CompanyProfileCopyWithImpl<$Res>
    implements _$CompanyProfileCopyWith<$Res> {
  __$CompanyProfileCopyWithImpl(this._self, this._then);

  final _CompanyProfile _self;
  final $Res Function(_CompanyProfile) _then;

/// Create a copy of CompanyProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nameFull = null,Object? nameShort = null,Object? logoUrl = freezed,Object? website = freezed,Object? email = freezed,Object? phone = freezed,Object? activityDescription = freezed,Object? inn = freezed,Object? kpp = freezed,Object? ogrn = freezed,Object? okpo = freezed,Object? legalAddress = freezed,Object? actualAddress = freezed,Object? directorName = freezed,Object? directorPosition = freezed,Object? directorBasis = freezed,Object? directorPhone = freezed,Object? chiefAccountantName = freezed,Object? chiefAccountantPhone = freezed,Object? contactPerson = freezed,Object? taxationSystem = freezed,Object? isVatPayer = null,Object? vatRate = null,Object? ownerId = freezed,Object? invitationCode = freezed,Object? isActive = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_CompanyProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nameFull: null == nameFull ? _self.nameFull : nameFull // ignore: cast_nullable_to_non_nullable
as String,nameShort: null == nameShort ? _self.nameShort : nameShort // ignore: cast_nullable_to_non_nullable
as String,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,website: freezed == website ? _self.website : website // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,activityDescription: freezed == activityDescription ? _self.activityDescription : activityDescription // ignore: cast_nullable_to_non_nullable
as String?,inn: freezed == inn ? _self.inn : inn // ignore: cast_nullable_to_non_nullable
as String?,kpp: freezed == kpp ? _self.kpp : kpp // ignore: cast_nullable_to_non_nullable
as String?,ogrn: freezed == ogrn ? _self.ogrn : ogrn // ignore: cast_nullable_to_non_nullable
as String?,okpo: freezed == okpo ? _self.okpo : okpo // ignore: cast_nullable_to_non_nullable
as String?,legalAddress: freezed == legalAddress ? _self.legalAddress : legalAddress // ignore: cast_nullable_to_non_nullable
as String?,actualAddress: freezed == actualAddress ? _self.actualAddress : actualAddress // ignore: cast_nullable_to_non_nullable
as String?,directorName: freezed == directorName ? _self.directorName : directorName // ignore: cast_nullable_to_non_nullable
as String?,directorPosition: freezed == directorPosition ? _self.directorPosition : directorPosition // ignore: cast_nullable_to_non_nullable
as String?,directorBasis: freezed == directorBasis ? _self.directorBasis : directorBasis // ignore: cast_nullable_to_non_nullable
as String?,directorPhone: freezed == directorPhone ? _self.directorPhone : directorPhone // ignore: cast_nullable_to_non_nullable
as String?,chiefAccountantName: freezed == chiefAccountantName ? _self.chiefAccountantName : chiefAccountantName // ignore: cast_nullable_to_non_nullable
as String?,chiefAccountantPhone: freezed == chiefAccountantPhone ? _self.chiefAccountantPhone : chiefAccountantPhone // ignore: cast_nullable_to_non_nullable
as String?,contactPerson: freezed == contactPerson ? _self.contactPerson : contactPerson // ignore: cast_nullable_to_non_nullable
as String?,taxationSystem: freezed == taxationSystem ? _self.taxationSystem : taxationSystem // ignore: cast_nullable_to_non_nullable
as String?,isVatPayer: null == isVatPayer ? _self.isVatPayer : isVatPayer // ignore: cast_nullable_to_non_nullable
as bool,vatRate: null == vatRate ? _self.vatRate : vatRate // ignore: cast_nullable_to_non_nullable
as double,ownerId: freezed == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String?,invitationCode: freezed == invitationCode ? _self.invitationCode : invitationCode // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
