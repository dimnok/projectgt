// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'contractor_bank_account_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ContractorBankAccountModel {

 String get id;@JsonKey(name: 'company_id') String get companyId;@JsonKey(name: 'contractor_id') String get contractorId;@JsonKey(name: 'bank_name') String get bankName;@JsonKey(name: 'bank_city') String? get bankCity; String? get bik;@JsonKey(name: 'corr_account') String? get corrAccount;@JsonKey(name: 'account_number') String get accountNumber; bool get isPrimary;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;
/// Create a copy of ContractorBankAccountModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContractorBankAccountModelCopyWith<ContractorBankAccountModel> get copyWith => _$ContractorBankAccountModelCopyWithImpl<ContractorBankAccountModel>(this as ContractorBankAccountModel, _$identity);

  /// Serializes this ContractorBankAccountModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContractorBankAccountModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.contractorId, contractorId) || other.contractorId == contractorId)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.bankCity, bankCity) || other.bankCity == bankCity)&&(identical(other.bik, bik) || other.bik == bik)&&(identical(other.corrAccount, corrAccount) || other.corrAccount == corrAccount)&&(identical(other.accountNumber, accountNumber) || other.accountNumber == accountNumber)&&(identical(other.isPrimary, isPrimary) || other.isPrimary == isPrimary)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,contractorId,bankName,bankCity,bik,corrAccount,accountNumber,isPrimary,createdAt,updatedAt);

@override
String toString() {
  return 'ContractorBankAccountModel(id: $id, companyId: $companyId, contractorId: $contractorId, bankName: $bankName, bankCity: $bankCity, bik: $bik, corrAccount: $corrAccount, accountNumber: $accountNumber, isPrimary: $isPrimary, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ContractorBankAccountModelCopyWith<$Res>  {
  factory $ContractorBankAccountModelCopyWith(ContractorBankAccountModel value, $Res Function(ContractorBankAccountModel) _then) = _$ContractorBankAccountModelCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'company_id') String companyId,@JsonKey(name: 'contractor_id') String contractorId,@JsonKey(name: 'bank_name') String bankName,@JsonKey(name: 'bank_city') String? bankCity, String? bik,@JsonKey(name: 'corr_account') String? corrAccount,@JsonKey(name: 'account_number') String accountNumber, bool isPrimary,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class _$ContractorBankAccountModelCopyWithImpl<$Res>
    implements $ContractorBankAccountModelCopyWith<$Res> {
  _$ContractorBankAccountModelCopyWithImpl(this._self, this._then);

  final ContractorBankAccountModel _self;
  final $Res Function(ContractorBankAccountModel) _then;

/// Create a copy of ContractorBankAccountModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? contractorId = null,Object? bankName = null,Object? bankCity = freezed,Object? bik = freezed,Object? corrAccount = freezed,Object? accountNumber = null,Object? isPrimary = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,contractorId: null == contractorId ? _self.contractorId : contractorId // ignore: cast_nullable_to_non_nullable
as String,bankName: null == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String,bankCity: freezed == bankCity ? _self.bankCity : bankCity // ignore: cast_nullable_to_non_nullable
as String?,bik: freezed == bik ? _self.bik : bik // ignore: cast_nullable_to_non_nullable
as String?,corrAccount: freezed == corrAccount ? _self.corrAccount : corrAccount // ignore: cast_nullable_to_non_nullable
as String?,accountNumber: null == accountNumber ? _self.accountNumber : accountNumber // ignore: cast_nullable_to_non_nullable
as String,isPrimary: null == isPrimary ? _self.isPrimary : isPrimary // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class _ContractorBankAccountModel extends ContractorBankAccountModel {
  const _ContractorBankAccountModel({required this.id, @JsonKey(name: 'company_id') required this.companyId, @JsonKey(name: 'contractor_id') required this.contractorId, @JsonKey(name: 'bank_name') required this.bankName, @JsonKey(name: 'bank_city') this.bankCity, this.bik, @JsonKey(name: 'corr_account') this.corrAccount, @JsonKey(name: 'account_number') required this.accountNumber, this.isPrimary = false, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt}): super._();
  factory _ContractorBankAccountModel.fromJson(Map<String, dynamic> json) => _$ContractorBankAccountModelFromJson(json);

@override final  String id;
@override@JsonKey(name: 'company_id') final  String companyId;
@override@JsonKey(name: 'contractor_id') final  String contractorId;
@override@JsonKey(name: 'bank_name') final  String bankName;
@override@JsonKey(name: 'bank_city') final  String? bankCity;
@override final  String? bik;
@override@JsonKey(name: 'corr_account') final  String? corrAccount;
@override@JsonKey(name: 'account_number') final  String accountNumber;
@override@JsonKey() final  bool isPrimary;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;

/// Create a copy of ContractorBankAccountModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContractorBankAccountModelCopyWith<_ContractorBankAccountModel> get copyWith => __$ContractorBankAccountModelCopyWithImpl<_ContractorBankAccountModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ContractorBankAccountModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ContractorBankAccountModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.contractorId, contractorId) || other.contractorId == contractorId)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.bankCity, bankCity) || other.bankCity == bankCity)&&(identical(other.bik, bik) || other.bik == bik)&&(identical(other.corrAccount, corrAccount) || other.corrAccount == corrAccount)&&(identical(other.accountNumber, accountNumber) || other.accountNumber == accountNumber)&&(identical(other.isPrimary, isPrimary) || other.isPrimary == isPrimary)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,contractorId,bankName,bankCity,bik,corrAccount,accountNumber,isPrimary,createdAt,updatedAt);

@override
String toString() {
  return 'ContractorBankAccountModel(id: $id, companyId: $companyId, contractorId: $contractorId, bankName: $bankName, bankCity: $bankCity, bik: $bik, corrAccount: $corrAccount, accountNumber: $accountNumber, isPrimary: $isPrimary, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ContractorBankAccountModelCopyWith<$Res> implements $ContractorBankAccountModelCopyWith<$Res> {
  factory _$ContractorBankAccountModelCopyWith(_ContractorBankAccountModel value, $Res Function(_ContractorBankAccountModel) _then) = __$ContractorBankAccountModelCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'company_id') String companyId,@JsonKey(name: 'contractor_id') String contractorId,@JsonKey(name: 'bank_name') String bankName,@JsonKey(name: 'bank_city') String? bankCity, String? bik,@JsonKey(name: 'corr_account') String? corrAccount,@JsonKey(name: 'account_number') String accountNumber, bool isPrimary,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class __$ContractorBankAccountModelCopyWithImpl<$Res>
    implements _$ContractorBankAccountModelCopyWith<$Res> {
  __$ContractorBankAccountModelCopyWithImpl(this._self, this._then);

  final _ContractorBankAccountModel _self;
  final $Res Function(_ContractorBankAccountModel) _then;

/// Create a copy of ContractorBankAccountModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? contractorId = null,Object? bankName = null,Object? bankCity = freezed,Object? bik = freezed,Object? corrAccount = freezed,Object? accountNumber = null,Object? isPrimary = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_ContractorBankAccountModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,contractorId: null == contractorId ? _self.contractorId : contractorId // ignore: cast_nullable_to_non_nullable
as String,bankName: null == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String,bankCity: freezed == bankCity ? _self.bankCity : bankCity // ignore: cast_nullable_to_non_nullable
as String?,bik: freezed == bik ? _self.bik : bik // ignore: cast_nullable_to_non_nullable
as String?,corrAccount: freezed == corrAccount ? _self.corrAccount : corrAccount // ignore: cast_nullable_to_non_nullable
as String?,accountNumber: null == accountNumber ? _self.accountNumber : accountNumber // ignore: cast_nullable_to_non_nullable
as String,isPrimary: null == isPrimary ? _self.isPrimary : isPrimary // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
