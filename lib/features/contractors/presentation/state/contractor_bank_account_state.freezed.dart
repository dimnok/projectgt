// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'contractor_bank_account_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ContractorBankAccountState {

 List<ContractorBankAccount> get accounts; BankAccountStatus get status; String? get errorMessage;
/// Create a copy of ContractorBankAccountState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContractorBankAccountStateCopyWith<ContractorBankAccountState> get copyWith => _$ContractorBankAccountStateCopyWithImpl<ContractorBankAccountState>(this as ContractorBankAccountState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContractorBankAccountState&&const DeepCollectionEquality().equals(other.accounts, accounts)&&(identical(other.status, status) || other.status == status)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(accounts),status,errorMessage);

@override
String toString() {
  return 'ContractorBankAccountState(accounts: $accounts, status: $status, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $ContractorBankAccountStateCopyWith<$Res>  {
  factory $ContractorBankAccountStateCopyWith(ContractorBankAccountState value, $Res Function(ContractorBankAccountState) _then) = _$ContractorBankAccountStateCopyWithImpl;
@useResult
$Res call({
 List<ContractorBankAccount> accounts, BankAccountStatus status, String? errorMessage
});




}
/// @nodoc
class _$ContractorBankAccountStateCopyWithImpl<$Res>
    implements $ContractorBankAccountStateCopyWith<$Res> {
  _$ContractorBankAccountStateCopyWithImpl(this._self, this._then);

  final ContractorBankAccountState _self;
  final $Res Function(ContractorBankAccountState) _then;

/// Create a copy of ContractorBankAccountState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accounts = null,Object? status = null,Object? errorMessage = freezed,}) {
  return _then(_self.copyWith(
accounts: null == accounts ? _self.accounts : accounts // ignore: cast_nullable_to_non_nullable
as List<ContractorBankAccount>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BankAccountStatus,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc


class _ContractorBankAccountState implements ContractorBankAccountState {
  const _ContractorBankAccountState({final  List<ContractorBankAccount> accounts = const [], this.status = BankAccountStatus.initial, this.errorMessage}): _accounts = accounts;
  

 final  List<ContractorBankAccount> _accounts;
@override@JsonKey() List<ContractorBankAccount> get accounts {
  if (_accounts is EqualUnmodifiableListView) return _accounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_accounts);
}

@override@JsonKey() final  BankAccountStatus status;
@override final  String? errorMessage;

/// Create a copy of ContractorBankAccountState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContractorBankAccountStateCopyWith<_ContractorBankAccountState> get copyWith => __$ContractorBankAccountStateCopyWithImpl<_ContractorBankAccountState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ContractorBankAccountState&&const DeepCollectionEquality().equals(other._accounts, _accounts)&&(identical(other.status, status) || other.status == status)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_accounts),status,errorMessage);

@override
String toString() {
  return 'ContractorBankAccountState(accounts: $accounts, status: $status, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$ContractorBankAccountStateCopyWith<$Res> implements $ContractorBankAccountStateCopyWith<$Res> {
  factory _$ContractorBankAccountStateCopyWith(_ContractorBankAccountState value, $Res Function(_ContractorBankAccountState) _then) = __$ContractorBankAccountStateCopyWithImpl;
@override @useResult
$Res call({
 List<ContractorBankAccount> accounts, BankAccountStatus status, String? errorMessage
});




}
/// @nodoc
class __$ContractorBankAccountStateCopyWithImpl<$Res>
    implements _$ContractorBankAccountStateCopyWith<$Res> {
  __$ContractorBankAccountStateCopyWithImpl(this._self, this._then);

  final _ContractorBankAccountState _self;
  final $Res Function(_ContractorBankAccountState) _then;

/// Create a copy of ContractorBankAccountState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accounts = null,Object? status = null,Object? errorMessage = freezed,}) {
  return _then(_ContractorBankAccountState(
accounts: null == accounts ? _self._accounts : accounts // ignore: cast_nullable_to_non_nullable
as List<ContractorBankAccount>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BankAccountStatus,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
