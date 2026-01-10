// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'contractor_bank_account.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ContractorBankAccount {

 String get id;@JsonKey(name: 'company_id') String get companyId;@JsonKey(name: 'contractor_id') String get contractorId;@JsonKey(name: 'bank_name') String get bankName;@JsonKey(name: 'bank_city') String? get bankCity; String? get bik;@JsonKey(name: 'corr_account') String? get corrAccount;@JsonKey(name: 'account_number') String get accountNumber;@JsonKey(name: 'is_primary') bool get isPrimary;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;
/// Create a copy of ContractorBankAccount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContractorBankAccountCopyWith<ContractorBankAccount> get copyWith => _$ContractorBankAccountCopyWithImpl<ContractorBankAccount>(this as ContractorBankAccount, _$identity);

  /// Serializes this ContractorBankAccount to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContractorBankAccount&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.contractorId, contractorId) || other.contractorId == contractorId)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.bankCity, bankCity) || other.bankCity == bankCity)&&(identical(other.bik, bik) || other.bik == bik)&&(identical(other.corrAccount, corrAccount) || other.corrAccount == corrAccount)&&(identical(other.accountNumber, accountNumber) || other.accountNumber == accountNumber)&&(identical(other.isPrimary, isPrimary) || other.isPrimary == isPrimary)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,contractorId,bankName,bankCity,bik,corrAccount,accountNumber,isPrimary,createdAt,updatedAt);

@override
String toString() {
  return 'ContractorBankAccount(id: $id, companyId: $companyId, contractorId: $contractorId, bankName: $bankName, bankCity: $bankCity, bik: $bik, corrAccount: $corrAccount, accountNumber: $accountNumber, isPrimary: $isPrimary, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ContractorBankAccountCopyWith<$Res>  {
  factory $ContractorBankAccountCopyWith(ContractorBankAccount value, $Res Function(ContractorBankAccount) _then) = _$ContractorBankAccountCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'company_id') String companyId,@JsonKey(name: 'contractor_id') String contractorId,@JsonKey(name: 'bank_name') String bankName,@JsonKey(name: 'bank_city') String? bankCity, String? bik,@JsonKey(name: 'corr_account') String? corrAccount,@JsonKey(name: 'account_number') String accountNumber,@JsonKey(name: 'is_primary') bool isPrimary,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class _$ContractorBankAccountCopyWithImpl<$Res>
    implements $ContractorBankAccountCopyWith<$Res> {
  _$ContractorBankAccountCopyWithImpl(this._self, this._then);

  final ContractorBankAccount _self;
  final $Res Function(ContractorBankAccount) _then;

/// Create a copy of ContractorBankAccount
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
@JsonSerializable()

class _ContractorBankAccount implements ContractorBankAccount {
  const _ContractorBankAccount({required this.id, @JsonKey(name: 'company_id') required this.companyId, @JsonKey(name: 'contractor_id') required this.contractorId, @JsonKey(name: 'bank_name') required this.bankName, @JsonKey(name: 'bank_city') this.bankCity, this.bik, @JsonKey(name: 'corr_account') this.corrAccount, @JsonKey(name: 'account_number') required this.accountNumber, @JsonKey(name: 'is_primary') this.isPrimary = false, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt});
  factory _ContractorBankAccount.fromJson(Map<String, dynamic> json) => _$ContractorBankAccountFromJson(json);

@override final  String id;
@override@JsonKey(name: 'company_id') final  String companyId;
@override@JsonKey(name: 'contractor_id') final  String contractorId;
@override@JsonKey(name: 'bank_name') final  String bankName;
@override@JsonKey(name: 'bank_city') final  String? bankCity;
@override final  String? bik;
@override@JsonKey(name: 'corr_account') final  String? corrAccount;
@override@JsonKey(name: 'account_number') final  String accountNumber;
@override@JsonKey(name: 'is_primary') final  bool isPrimary;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;

/// Create a copy of ContractorBankAccount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContractorBankAccountCopyWith<_ContractorBankAccount> get copyWith => __$ContractorBankAccountCopyWithImpl<_ContractorBankAccount>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ContractorBankAccountToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ContractorBankAccount&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.contractorId, contractorId) || other.contractorId == contractorId)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.bankCity, bankCity) || other.bankCity == bankCity)&&(identical(other.bik, bik) || other.bik == bik)&&(identical(other.corrAccount, corrAccount) || other.corrAccount == corrAccount)&&(identical(other.accountNumber, accountNumber) || other.accountNumber == accountNumber)&&(identical(other.isPrimary, isPrimary) || other.isPrimary == isPrimary)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,contractorId,bankName,bankCity,bik,corrAccount,accountNumber,isPrimary,createdAt,updatedAt);

@override
String toString() {
  return 'ContractorBankAccount(id: $id, companyId: $companyId, contractorId: $contractorId, bankName: $bankName, bankCity: $bankCity, bik: $bik, corrAccount: $corrAccount, accountNumber: $accountNumber, isPrimary: $isPrimary, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ContractorBankAccountCopyWith<$Res> implements $ContractorBankAccountCopyWith<$Res> {
  factory _$ContractorBankAccountCopyWith(_ContractorBankAccount value, $Res Function(_ContractorBankAccount) _then) = __$ContractorBankAccountCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'company_id') String companyId,@JsonKey(name: 'contractor_id') String contractorId,@JsonKey(name: 'bank_name') String bankName,@JsonKey(name: 'bank_city') String? bankCity, String? bik,@JsonKey(name: 'corr_account') String? corrAccount,@JsonKey(name: 'account_number') String accountNumber,@JsonKey(name: 'is_primary') bool isPrimary,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class __$ContractorBankAccountCopyWithImpl<$Res>
    implements _$ContractorBankAccountCopyWith<$Res> {
  __$ContractorBankAccountCopyWithImpl(this._self, this._then);

  final _ContractorBankAccount _self;
  final $Res Function(_ContractorBankAccount) _then;

/// Create a copy of ContractorBankAccount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? contractorId = null,Object? bankName = null,Object? bankCity = freezed,Object? bik = freezed,Object? corrAccount = freezed,Object? accountNumber = null,Object? isPrimary = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_ContractorBankAccount(
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
