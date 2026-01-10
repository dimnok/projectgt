// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'company_bank_account.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CompanyBankAccount {

 String get id;@JsonKey(name: 'company_id') String get companyId;@JsonKey(name: 'bank_name') String get bankName;@JsonKey(name: 'bank_city') String? get bankCity;@JsonKey(name: 'account_number') String get accountNumber;@JsonKey(name: 'corr_account') String? get corrAccount; String? get bik;@JsonKey(name: 'is_primary') bool get isPrimary;@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of CompanyBankAccount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompanyBankAccountCopyWith<CompanyBankAccount> get copyWith => _$CompanyBankAccountCopyWithImpl<CompanyBankAccount>(this as CompanyBankAccount, _$identity);

  /// Serializes this CompanyBankAccount to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompanyBankAccount&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.bankCity, bankCity) || other.bankCity == bankCity)&&(identical(other.accountNumber, accountNumber) || other.accountNumber == accountNumber)&&(identical(other.corrAccount, corrAccount) || other.corrAccount == corrAccount)&&(identical(other.bik, bik) || other.bik == bik)&&(identical(other.isPrimary, isPrimary) || other.isPrimary == isPrimary)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,bankName,bankCity,accountNumber,corrAccount,bik,isPrimary,createdAt);

@override
String toString() {
  return 'CompanyBankAccount(id: $id, companyId: $companyId, bankName: $bankName, bankCity: $bankCity, accountNumber: $accountNumber, corrAccount: $corrAccount, bik: $bik, isPrimary: $isPrimary, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $CompanyBankAccountCopyWith<$Res>  {
  factory $CompanyBankAccountCopyWith(CompanyBankAccount value, $Res Function(CompanyBankAccount) _then) = _$CompanyBankAccountCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'company_id') String companyId,@JsonKey(name: 'bank_name') String bankName,@JsonKey(name: 'bank_city') String? bankCity,@JsonKey(name: 'account_number') String accountNumber,@JsonKey(name: 'corr_account') String? corrAccount, String? bik,@JsonKey(name: 'is_primary') bool isPrimary,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class _$CompanyBankAccountCopyWithImpl<$Res>
    implements $CompanyBankAccountCopyWith<$Res> {
  _$CompanyBankAccountCopyWithImpl(this._self, this._then);

  final CompanyBankAccount _self;
  final $Res Function(CompanyBankAccount) _then;

/// Create a copy of CompanyBankAccount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? bankName = null,Object? bankCity = freezed,Object? accountNumber = null,Object? corrAccount = freezed,Object? bik = freezed,Object? isPrimary = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,bankName: null == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String,bankCity: freezed == bankCity ? _self.bankCity : bankCity // ignore: cast_nullable_to_non_nullable
as String?,accountNumber: null == accountNumber ? _self.accountNumber : accountNumber // ignore: cast_nullable_to_non_nullable
as String,corrAccount: freezed == corrAccount ? _self.corrAccount : corrAccount // ignore: cast_nullable_to_non_nullable
as String?,bik: freezed == bik ? _self.bik : bik // ignore: cast_nullable_to_non_nullable
as String?,isPrimary: null == isPrimary ? _self.isPrimary : isPrimary // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _CompanyBankAccount implements CompanyBankAccount {
  const _CompanyBankAccount({required this.id, @JsonKey(name: 'company_id') required this.companyId, @JsonKey(name: 'bank_name') required this.bankName, @JsonKey(name: 'bank_city') this.bankCity, @JsonKey(name: 'account_number') required this.accountNumber, @JsonKey(name: 'corr_account') this.corrAccount, this.bik, @JsonKey(name: 'is_primary') this.isPrimary = false, @JsonKey(name: 'created_at') this.createdAt});
  factory _CompanyBankAccount.fromJson(Map<String, dynamic> json) => _$CompanyBankAccountFromJson(json);

@override final  String id;
@override@JsonKey(name: 'company_id') final  String companyId;
@override@JsonKey(name: 'bank_name') final  String bankName;
@override@JsonKey(name: 'bank_city') final  String? bankCity;
@override@JsonKey(name: 'account_number') final  String accountNumber;
@override@JsonKey(name: 'corr_account') final  String? corrAccount;
@override final  String? bik;
@override@JsonKey(name: 'is_primary') final  bool isPrimary;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of CompanyBankAccount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompanyBankAccountCopyWith<_CompanyBankAccount> get copyWith => __$CompanyBankAccountCopyWithImpl<_CompanyBankAccount>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CompanyBankAccountToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CompanyBankAccount&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.bankCity, bankCity) || other.bankCity == bankCity)&&(identical(other.accountNumber, accountNumber) || other.accountNumber == accountNumber)&&(identical(other.corrAccount, corrAccount) || other.corrAccount == corrAccount)&&(identical(other.bik, bik) || other.bik == bik)&&(identical(other.isPrimary, isPrimary) || other.isPrimary == isPrimary)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,bankName,bankCity,accountNumber,corrAccount,bik,isPrimary,createdAt);

@override
String toString() {
  return 'CompanyBankAccount(id: $id, companyId: $companyId, bankName: $bankName, bankCity: $bankCity, accountNumber: $accountNumber, corrAccount: $corrAccount, bik: $bik, isPrimary: $isPrimary, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$CompanyBankAccountCopyWith<$Res> implements $CompanyBankAccountCopyWith<$Res> {
  factory _$CompanyBankAccountCopyWith(_CompanyBankAccount value, $Res Function(_CompanyBankAccount) _then) = __$CompanyBankAccountCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'company_id') String companyId,@JsonKey(name: 'bank_name') String bankName,@JsonKey(name: 'bank_city') String? bankCity,@JsonKey(name: 'account_number') String accountNumber,@JsonKey(name: 'corr_account') String? corrAccount, String? bik,@JsonKey(name: 'is_primary') bool isPrimary,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class __$CompanyBankAccountCopyWithImpl<$Res>
    implements _$CompanyBankAccountCopyWith<$Res> {
  __$CompanyBankAccountCopyWithImpl(this._self, this._then);

  final _CompanyBankAccount _self;
  final $Res Function(_CompanyBankAccount) _then;

/// Create a copy of CompanyBankAccount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? bankName = null,Object? bankCity = freezed,Object? accountNumber = null,Object? corrAccount = freezed,Object? bik = freezed,Object? isPrimary = null,Object? createdAt = freezed,}) {
  return _then(_CompanyBankAccount(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,bankName: null == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String,bankCity: freezed == bankCity ? _self.bankCity : bankCity // ignore: cast_nullable_to_non_nullable
as String?,accountNumber: null == accountNumber ? _self.accountNumber : accountNumber // ignore: cast_nullable_to_non_nullable
as String,corrAccount: freezed == corrAccount ? _self.corrAccount : corrAccount // ignore: cast_nullable_to_non_nullable
as String?,bik: freezed == bik ? _self.bik : bik // ignore: cast_nullable_to_non_nullable
as String?,isPrimary: null == isPrimary ? _self.isPrimary : isPrimary // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
