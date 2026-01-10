// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'contractor.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Contractor {

/// Уникальный идентификатор подрядчика.
 String get id;/// ID компании, к которой относится контрагент.
@JsonKey(name: 'company_id') String get companyId;/// URL логотипа подрядчика.
 String? get logoUrl;/// Полное наименование.
 String get fullName;/// Краткое наименование.
 String get shortName;/// ИНН организации.
 String get inn;/// ФИО генерального директора.
 String get director;/// Юридический адрес.
 String get legalAddress;/// Фактический адрес.
 String get actualAddress;/// Телефон.
 String get phone;/// Email.
 String get email;/// Тип подрядчика ([ContractorType]).
 ContractorType get type;/// Веб-сайт.
 String? get website;/// Описание деятельности.
 String? get activityDescription;/// КПП.
 String? get kpp;/// ОГРН.
 String? get ogrn;/// ОКПО.
 String? get okpo;/// На основании чего действует директор.
 String? get directorBasis;/// Телефон директора.
 String? get directorPhone;/// ФИО главного бухгалтера.
 String? get chiefAccountantName;/// Телефон главного бухгалтера.
 String? get chiefAccountantPhone;/// Контактное лицо.
 String? get contactPerson;/// Система налогообложения.
 String? get taxationSystem;/// Является ли плательщиком НДС.
 bool get isVatPayer;/// Ставка НДС.
 double get vatRate;/// Дата создания записи.
 DateTime? get createdAt;/// Дата последнего обновления записи.
 DateTime? get updatedAt;
/// Create a copy of Contractor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContractorCopyWith<Contractor> get copyWith => _$ContractorCopyWithImpl<Contractor>(this as Contractor, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Contractor&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.shortName, shortName) || other.shortName == shortName)&&(identical(other.inn, inn) || other.inn == inn)&&(identical(other.director, director) || other.director == director)&&(identical(other.legalAddress, legalAddress) || other.legalAddress == legalAddress)&&(identical(other.actualAddress, actualAddress) || other.actualAddress == actualAddress)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.type, type) || other.type == type)&&(identical(other.website, website) || other.website == website)&&(identical(other.activityDescription, activityDescription) || other.activityDescription == activityDescription)&&(identical(other.kpp, kpp) || other.kpp == kpp)&&(identical(other.ogrn, ogrn) || other.ogrn == ogrn)&&(identical(other.okpo, okpo) || other.okpo == okpo)&&(identical(other.directorBasis, directorBasis) || other.directorBasis == directorBasis)&&(identical(other.directorPhone, directorPhone) || other.directorPhone == directorPhone)&&(identical(other.chiefAccountantName, chiefAccountantName) || other.chiefAccountantName == chiefAccountantName)&&(identical(other.chiefAccountantPhone, chiefAccountantPhone) || other.chiefAccountantPhone == chiefAccountantPhone)&&(identical(other.contactPerson, contactPerson) || other.contactPerson == contactPerson)&&(identical(other.taxationSystem, taxationSystem) || other.taxationSystem == taxationSystem)&&(identical(other.isVatPayer, isVatPayer) || other.isVatPayer == isVatPayer)&&(identical(other.vatRate, vatRate) || other.vatRate == vatRate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,logoUrl,fullName,shortName,inn,director,legalAddress,actualAddress,phone,email,type,website,activityDescription,kpp,ogrn,okpo,directorBasis,directorPhone,chiefAccountantName,chiefAccountantPhone,contactPerson,taxationSystem,isVatPayer,vatRate,createdAt,updatedAt]);

@override
String toString() {
  return 'Contractor(id: $id, companyId: $companyId, logoUrl: $logoUrl, fullName: $fullName, shortName: $shortName, inn: $inn, director: $director, legalAddress: $legalAddress, actualAddress: $actualAddress, phone: $phone, email: $email, type: $type, website: $website, activityDescription: $activityDescription, kpp: $kpp, ogrn: $ogrn, okpo: $okpo, directorBasis: $directorBasis, directorPhone: $directorPhone, chiefAccountantName: $chiefAccountantName, chiefAccountantPhone: $chiefAccountantPhone, contactPerson: $contactPerson, taxationSystem: $taxationSystem, isVatPayer: $isVatPayer, vatRate: $vatRate, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ContractorCopyWith<$Res>  {
  factory $ContractorCopyWith(Contractor value, $Res Function(Contractor) _then) = _$ContractorCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'company_id') String companyId, String? logoUrl, String fullName, String shortName, String inn, String director, String legalAddress, String actualAddress, String phone, String email, ContractorType type, String? website, String? activityDescription, String? kpp, String? ogrn, String? okpo, String? directorBasis, String? directorPhone, String? chiefAccountantName, String? chiefAccountantPhone, String? contactPerson, String? taxationSystem, bool isVatPayer, double vatRate, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$ContractorCopyWithImpl<$Res>
    implements $ContractorCopyWith<$Res> {
  _$ContractorCopyWithImpl(this._self, this._then);

  final Contractor _self;
  final $Res Function(Contractor) _then;

/// Create a copy of Contractor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? logoUrl = freezed,Object? fullName = null,Object? shortName = null,Object? inn = null,Object? director = null,Object? legalAddress = null,Object? actualAddress = null,Object? phone = null,Object? email = null,Object? type = null,Object? website = freezed,Object? activityDescription = freezed,Object? kpp = freezed,Object? ogrn = freezed,Object? okpo = freezed,Object? directorBasis = freezed,Object? directorPhone = freezed,Object? chiefAccountantName = freezed,Object? chiefAccountantPhone = freezed,Object? contactPerson = freezed,Object? taxationSystem = freezed,Object? isVatPayer = null,Object? vatRate = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,shortName: null == shortName ? _self.shortName : shortName // ignore: cast_nullable_to_non_nullable
as String,inn: null == inn ? _self.inn : inn // ignore: cast_nullable_to_non_nullable
as String,director: null == director ? _self.director : director // ignore: cast_nullable_to_non_nullable
as String,legalAddress: null == legalAddress ? _self.legalAddress : legalAddress // ignore: cast_nullable_to_non_nullable
as String,actualAddress: null == actualAddress ? _self.actualAddress : actualAddress // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ContractorType,website: freezed == website ? _self.website : website // ignore: cast_nullable_to_non_nullable
as String?,activityDescription: freezed == activityDescription ? _self.activityDescription : activityDescription // ignore: cast_nullable_to_non_nullable
as String?,kpp: freezed == kpp ? _self.kpp : kpp // ignore: cast_nullable_to_non_nullable
as String?,ogrn: freezed == ogrn ? _self.ogrn : ogrn // ignore: cast_nullable_to_non_nullable
as String?,okpo: freezed == okpo ? _self.okpo : okpo // ignore: cast_nullable_to_non_nullable
as String?,directorBasis: freezed == directorBasis ? _self.directorBasis : directorBasis // ignore: cast_nullable_to_non_nullable
as String?,directorPhone: freezed == directorPhone ? _self.directorPhone : directorPhone // ignore: cast_nullable_to_non_nullable
as String?,chiefAccountantName: freezed == chiefAccountantName ? _self.chiefAccountantName : chiefAccountantName // ignore: cast_nullable_to_non_nullable
as String?,chiefAccountantPhone: freezed == chiefAccountantPhone ? _self.chiefAccountantPhone : chiefAccountantPhone // ignore: cast_nullable_to_non_nullable
as String?,contactPerson: freezed == contactPerson ? _self.contactPerson : contactPerson // ignore: cast_nullable_to_non_nullable
as String?,taxationSystem: freezed == taxationSystem ? _self.taxationSystem : taxationSystem // ignore: cast_nullable_to_non_nullable
as String?,isVatPayer: null == isVatPayer ? _self.isVatPayer : isVatPayer // ignore: cast_nullable_to_non_nullable
as bool,vatRate: null == vatRate ? _self.vatRate : vatRate // ignore: cast_nullable_to_non_nullable
as double,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc


class _Contractor extends Contractor {
  const _Contractor({required this.id, @JsonKey(name: 'company_id') required this.companyId, this.logoUrl, required this.fullName, required this.shortName, required this.inn, required this.director, required this.legalAddress, required this.actualAddress, required this.phone, required this.email, required this.type, this.website, this.activityDescription, this.kpp, this.ogrn, this.okpo, this.directorBasis, this.directorPhone, this.chiefAccountantName, this.chiefAccountantPhone, this.contactPerson, this.taxationSystem, this.isVatPayer = false, this.vatRate = 0, this.createdAt, this.updatedAt}): super._();
  

/// Уникальный идентификатор подрядчика.
@override final  String id;
/// ID компании, к которой относится контрагент.
@override@JsonKey(name: 'company_id') final  String companyId;
/// URL логотипа подрядчика.
@override final  String? logoUrl;
/// Полное наименование.
@override final  String fullName;
/// Краткое наименование.
@override final  String shortName;
/// ИНН организации.
@override final  String inn;
/// ФИО генерального директора.
@override final  String director;
/// Юридический адрес.
@override final  String legalAddress;
/// Фактический адрес.
@override final  String actualAddress;
/// Телефон.
@override final  String phone;
/// Email.
@override final  String email;
/// Тип подрядчика ([ContractorType]).
@override final  ContractorType type;
/// Веб-сайт.
@override final  String? website;
/// Описание деятельности.
@override final  String? activityDescription;
/// КПП.
@override final  String? kpp;
/// ОГРН.
@override final  String? ogrn;
/// ОКПО.
@override final  String? okpo;
/// На основании чего действует директор.
@override final  String? directorBasis;
/// Телефон директора.
@override final  String? directorPhone;
/// ФИО главного бухгалтера.
@override final  String? chiefAccountantName;
/// Телефон главного бухгалтера.
@override final  String? chiefAccountantPhone;
/// Контактное лицо.
@override final  String? contactPerson;
/// Система налогообложения.
@override final  String? taxationSystem;
/// Является ли плательщиком НДС.
@override@JsonKey() final  bool isVatPayer;
/// Ставка НДС.
@override@JsonKey() final  double vatRate;
/// Дата создания записи.
@override final  DateTime? createdAt;
/// Дата последнего обновления записи.
@override final  DateTime? updatedAt;

/// Create a copy of Contractor
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContractorCopyWith<_Contractor> get copyWith => __$ContractorCopyWithImpl<_Contractor>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Contractor&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.shortName, shortName) || other.shortName == shortName)&&(identical(other.inn, inn) || other.inn == inn)&&(identical(other.director, director) || other.director == director)&&(identical(other.legalAddress, legalAddress) || other.legalAddress == legalAddress)&&(identical(other.actualAddress, actualAddress) || other.actualAddress == actualAddress)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.type, type) || other.type == type)&&(identical(other.website, website) || other.website == website)&&(identical(other.activityDescription, activityDescription) || other.activityDescription == activityDescription)&&(identical(other.kpp, kpp) || other.kpp == kpp)&&(identical(other.ogrn, ogrn) || other.ogrn == ogrn)&&(identical(other.okpo, okpo) || other.okpo == okpo)&&(identical(other.directorBasis, directorBasis) || other.directorBasis == directorBasis)&&(identical(other.directorPhone, directorPhone) || other.directorPhone == directorPhone)&&(identical(other.chiefAccountantName, chiefAccountantName) || other.chiefAccountantName == chiefAccountantName)&&(identical(other.chiefAccountantPhone, chiefAccountantPhone) || other.chiefAccountantPhone == chiefAccountantPhone)&&(identical(other.contactPerson, contactPerson) || other.contactPerson == contactPerson)&&(identical(other.taxationSystem, taxationSystem) || other.taxationSystem == taxationSystem)&&(identical(other.isVatPayer, isVatPayer) || other.isVatPayer == isVatPayer)&&(identical(other.vatRate, vatRate) || other.vatRate == vatRate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,logoUrl,fullName,shortName,inn,director,legalAddress,actualAddress,phone,email,type,website,activityDescription,kpp,ogrn,okpo,directorBasis,directorPhone,chiefAccountantName,chiefAccountantPhone,contactPerson,taxationSystem,isVatPayer,vatRate,createdAt,updatedAt]);

@override
String toString() {
  return 'Contractor(id: $id, companyId: $companyId, logoUrl: $logoUrl, fullName: $fullName, shortName: $shortName, inn: $inn, director: $director, legalAddress: $legalAddress, actualAddress: $actualAddress, phone: $phone, email: $email, type: $type, website: $website, activityDescription: $activityDescription, kpp: $kpp, ogrn: $ogrn, okpo: $okpo, directorBasis: $directorBasis, directorPhone: $directorPhone, chiefAccountantName: $chiefAccountantName, chiefAccountantPhone: $chiefAccountantPhone, contactPerson: $contactPerson, taxationSystem: $taxationSystem, isVatPayer: $isVatPayer, vatRate: $vatRate, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ContractorCopyWith<$Res> implements $ContractorCopyWith<$Res> {
  factory _$ContractorCopyWith(_Contractor value, $Res Function(_Contractor) _then) = __$ContractorCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'company_id') String companyId, String? logoUrl, String fullName, String shortName, String inn, String director, String legalAddress, String actualAddress, String phone, String email, ContractorType type, String? website, String? activityDescription, String? kpp, String? ogrn, String? okpo, String? directorBasis, String? directorPhone, String? chiefAccountantName, String? chiefAccountantPhone, String? contactPerson, String? taxationSystem, bool isVatPayer, double vatRate, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$ContractorCopyWithImpl<$Res>
    implements _$ContractorCopyWith<$Res> {
  __$ContractorCopyWithImpl(this._self, this._then);

  final _Contractor _self;
  final $Res Function(_Contractor) _then;

/// Create a copy of Contractor
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? logoUrl = freezed,Object? fullName = null,Object? shortName = null,Object? inn = null,Object? director = null,Object? legalAddress = null,Object? actualAddress = null,Object? phone = null,Object? email = null,Object? type = null,Object? website = freezed,Object? activityDescription = freezed,Object? kpp = freezed,Object? ogrn = freezed,Object? okpo = freezed,Object? directorBasis = freezed,Object? directorPhone = freezed,Object? chiefAccountantName = freezed,Object? chiefAccountantPhone = freezed,Object? contactPerson = freezed,Object? taxationSystem = freezed,Object? isVatPayer = null,Object? vatRate = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Contractor(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,shortName: null == shortName ? _self.shortName : shortName // ignore: cast_nullable_to_non_nullable
as String,inn: null == inn ? _self.inn : inn // ignore: cast_nullable_to_non_nullable
as String,director: null == director ? _self.director : director // ignore: cast_nullable_to_non_nullable
as String,legalAddress: null == legalAddress ? _self.legalAddress : legalAddress // ignore: cast_nullable_to_non_nullable
as String,actualAddress: null == actualAddress ? _self.actualAddress : actualAddress // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ContractorType,website: freezed == website ? _self.website : website // ignore: cast_nullable_to_non_nullable
as String?,activityDescription: freezed == activityDescription ? _self.activityDescription : activityDescription // ignore: cast_nullable_to_non_nullable
as String?,kpp: freezed == kpp ? _self.kpp : kpp // ignore: cast_nullable_to_non_nullable
as String?,ogrn: freezed == ogrn ? _self.ogrn : ogrn // ignore: cast_nullable_to_non_nullable
as String?,okpo: freezed == okpo ? _self.okpo : okpo // ignore: cast_nullable_to_non_nullable
as String?,directorBasis: freezed == directorBasis ? _self.directorBasis : directorBasis // ignore: cast_nullable_to_non_nullable
as String?,directorPhone: freezed == directorPhone ? _self.directorPhone : directorPhone // ignore: cast_nullable_to_non_nullable
as String?,chiefAccountantName: freezed == chiefAccountantName ? _self.chiefAccountantName : chiefAccountantName // ignore: cast_nullable_to_non_nullable
as String?,chiefAccountantPhone: freezed == chiefAccountantPhone ? _self.chiefAccountantPhone : chiefAccountantPhone // ignore: cast_nullable_to_non_nullable
as String?,contactPerson: freezed == contactPerson ? _self.contactPerson : contactPerson // ignore: cast_nullable_to_non_nullable
as String?,taxationSystem: freezed == taxationSystem ? _self.taxationSystem : taxationSystem // ignore: cast_nullable_to_non_nullable
as String?,isVatPayer: null == isVatPayer ? _self.isVatPayer : isVatPayer // ignore: cast_nullable_to_non_nullable
as bool,vatRate: null == vatRate ? _self.vatRate : vatRate // ignore: cast_nullable_to_non_nullable
as double,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
