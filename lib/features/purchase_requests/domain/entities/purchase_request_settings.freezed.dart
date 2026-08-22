// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'purchase_request_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PurchaseRequestSettings {

 String get companyId; List<String> get firstApproverIds; List<String> get invoicePreparerIds; List<String> get invoiceApproverIds; List<String> get accountantIds; PurchaseRequestReceiverMode get receiverMode; List<String> get fixedReceiverIds;
/// Create a copy of PurchaseRequestSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PurchaseRequestSettingsCopyWith<PurchaseRequestSettings> get copyWith => _$PurchaseRequestSettingsCopyWithImpl<PurchaseRequestSettings>(this as PurchaseRequestSettings, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PurchaseRequestSettings&&(identical(other.companyId, companyId) || other.companyId == companyId)&&const DeepCollectionEquality().equals(other.firstApproverIds, firstApproverIds)&&const DeepCollectionEquality().equals(other.invoicePreparerIds, invoicePreparerIds)&&const DeepCollectionEquality().equals(other.invoiceApproverIds, invoiceApproverIds)&&const DeepCollectionEquality().equals(other.accountantIds, accountantIds)&&(identical(other.receiverMode, receiverMode) || other.receiverMode == receiverMode)&&const DeepCollectionEquality().equals(other.fixedReceiverIds, fixedReceiverIds));
}


@override
int get hashCode => Object.hash(runtimeType,companyId,const DeepCollectionEquality().hash(firstApproverIds),const DeepCollectionEquality().hash(invoicePreparerIds),const DeepCollectionEquality().hash(invoiceApproverIds),const DeepCollectionEquality().hash(accountantIds),receiverMode,const DeepCollectionEquality().hash(fixedReceiverIds));

@override
String toString() {
  return 'PurchaseRequestSettings(companyId: $companyId, firstApproverIds: $firstApproverIds, invoicePreparerIds: $invoicePreparerIds, invoiceApproverIds: $invoiceApproverIds, accountantIds: $accountantIds, receiverMode: $receiverMode, fixedReceiverIds: $fixedReceiverIds)';
}


}

/// @nodoc
abstract mixin class $PurchaseRequestSettingsCopyWith<$Res>  {
  factory $PurchaseRequestSettingsCopyWith(PurchaseRequestSettings value, $Res Function(PurchaseRequestSettings) _then) = _$PurchaseRequestSettingsCopyWithImpl;
@useResult
$Res call({
 String companyId, List<String> firstApproverIds, List<String> invoicePreparerIds, List<String> invoiceApproverIds, List<String> accountantIds, PurchaseRequestReceiverMode receiverMode, List<String> fixedReceiverIds
});




}
/// @nodoc
class _$PurchaseRequestSettingsCopyWithImpl<$Res>
    implements $PurchaseRequestSettingsCopyWith<$Res> {
  _$PurchaseRequestSettingsCopyWithImpl(this._self, this._then);

  final PurchaseRequestSettings _self;
  final $Res Function(PurchaseRequestSettings) _then;

/// Create a copy of PurchaseRequestSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? companyId = null,Object? firstApproverIds = null,Object? invoicePreparerIds = null,Object? invoiceApproverIds = null,Object? accountantIds = null,Object? receiverMode = null,Object? fixedReceiverIds = null,}) {
  return _then(_self.copyWith(
companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,firstApproverIds: null == firstApproverIds ? _self.firstApproverIds : firstApproverIds // ignore: cast_nullable_to_non_nullable
as List<String>,invoicePreparerIds: null == invoicePreparerIds ? _self.invoicePreparerIds : invoicePreparerIds // ignore: cast_nullable_to_non_nullable
as List<String>,invoiceApproverIds: null == invoiceApproverIds ? _self.invoiceApproverIds : invoiceApproverIds // ignore: cast_nullable_to_non_nullable
as List<String>,accountantIds: null == accountantIds ? _self.accountantIds : accountantIds // ignore: cast_nullable_to_non_nullable
as List<String>,receiverMode: null == receiverMode ? _self.receiverMode : receiverMode // ignore: cast_nullable_to_non_nullable
as PurchaseRequestReceiverMode,fixedReceiverIds: null == fixedReceiverIds ? _self.fixedReceiverIds : fixedReceiverIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// @nodoc


class _PurchaseRequestSettings implements PurchaseRequestSettings {
  const _PurchaseRequestSettings({required this.companyId, final  List<String> firstApproverIds = const <String>[], final  List<String> invoicePreparerIds = const <String>[], final  List<String> invoiceApproverIds = const <String>[], final  List<String> accountantIds = const <String>[], this.receiverMode = PurchaseRequestReceiverMode.initiator, final  List<String> fixedReceiverIds = const <String>[]}): _firstApproverIds = firstApproverIds,_invoicePreparerIds = invoicePreparerIds,_invoiceApproverIds = invoiceApproverIds,_accountantIds = accountantIds,_fixedReceiverIds = fixedReceiverIds;
  

@override final  String companyId;
 final  List<String> _firstApproverIds;
@override@JsonKey() List<String> get firstApproverIds {
  if (_firstApproverIds is EqualUnmodifiableListView) return _firstApproverIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_firstApproverIds);
}

 final  List<String> _invoicePreparerIds;
@override@JsonKey() List<String> get invoicePreparerIds {
  if (_invoicePreparerIds is EqualUnmodifiableListView) return _invoicePreparerIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_invoicePreparerIds);
}

 final  List<String> _invoiceApproverIds;
@override@JsonKey() List<String> get invoiceApproverIds {
  if (_invoiceApproverIds is EqualUnmodifiableListView) return _invoiceApproverIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_invoiceApproverIds);
}

 final  List<String> _accountantIds;
@override@JsonKey() List<String> get accountantIds {
  if (_accountantIds is EqualUnmodifiableListView) return _accountantIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_accountantIds);
}

@override@JsonKey() final  PurchaseRequestReceiverMode receiverMode;
 final  List<String> _fixedReceiverIds;
@override@JsonKey() List<String> get fixedReceiverIds {
  if (_fixedReceiverIds is EqualUnmodifiableListView) return _fixedReceiverIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_fixedReceiverIds);
}


/// Create a copy of PurchaseRequestSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PurchaseRequestSettingsCopyWith<_PurchaseRequestSettings> get copyWith => __$PurchaseRequestSettingsCopyWithImpl<_PurchaseRequestSettings>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PurchaseRequestSettings&&(identical(other.companyId, companyId) || other.companyId == companyId)&&const DeepCollectionEquality().equals(other._firstApproverIds, _firstApproverIds)&&const DeepCollectionEquality().equals(other._invoicePreparerIds, _invoicePreparerIds)&&const DeepCollectionEquality().equals(other._invoiceApproverIds, _invoiceApproverIds)&&const DeepCollectionEquality().equals(other._accountantIds, _accountantIds)&&(identical(other.receiverMode, receiverMode) || other.receiverMode == receiverMode)&&const DeepCollectionEquality().equals(other._fixedReceiverIds, _fixedReceiverIds));
}


@override
int get hashCode => Object.hash(runtimeType,companyId,const DeepCollectionEquality().hash(_firstApproverIds),const DeepCollectionEquality().hash(_invoicePreparerIds),const DeepCollectionEquality().hash(_invoiceApproverIds),const DeepCollectionEquality().hash(_accountantIds),receiverMode,const DeepCollectionEquality().hash(_fixedReceiverIds));

@override
String toString() {
  return 'PurchaseRequestSettings(companyId: $companyId, firstApproverIds: $firstApproverIds, invoicePreparerIds: $invoicePreparerIds, invoiceApproverIds: $invoiceApproverIds, accountantIds: $accountantIds, receiverMode: $receiverMode, fixedReceiverIds: $fixedReceiverIds)';
}


}

/// @nodoc
abstract mixin class _$PurchaseRequestSettingsCopyWith<$Res> implements $PurchaseRequestSettingsCopyWith<$Res> {
  factory _$PurchaseRequestSettingsCopyWith(_PurchaseRequestSettings value, $Res Function(_PurchaseRequestSettings) _then) = __$PurchaseRequestSettingsCopyWithImpl;
@override @useResult
$Res call({
 String companyId, List<String> firstApproverIds, List<String> invoicePreparerIds, List<String> invoiceApproverIds, List<String> accountantIds, PurchaseRequestReceiverMode receiverMode, List<String> fixedReceiverIds
});




}
/// @nodoc
class __$PurchaseRequestSettingsCopyWithImpl<$Res>
    implements _$PurchaseRequestSettingsCopyWith<$Res> {
  __$PurchaseRequestSettingsCopyWithImpl(this._self, this._then);

  final _PurchaseRequestSettings _self;
  final $Res Function(_PurchaseRequestSettings) _then;

/// Create a copy of PurchaseRequestSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? companyId = null,Object? firstApproverIds = null,Object? invoicePreparerIds = null,Object? invoiceApproverIds = null,Object? accountantIds = null,Object? receiverMode = null,Object? fixedReceiverIds = null,}) {
  return _then(_PurchaseRequestSettings(
companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,firstApproverIds: null == firstApproverIds ? _self._firstApproverIds : firstApproverIds // ignore: cast_nullable_to_non_nullable
as List<String>,invoicePreparerIds: null == invoicePreparerIds ? _self._invoicePreparerIds : invoicePreparerIds // ignore: cast_nullable_to_non_nullable
as List<String>,invoiceApproverIds: null == invoiceApproverIds ? _self._invoiceApproverIds : invoiceApproverIds // ignore: cast_nullable_to_non_nullable
as List<String>,accountantIds: null == accountantIds ? _self._accountantIds : accountantIds // ignore: cast_nullable_to_non_nullable
as List<String>,receiverMode: null == receiverMode ? _self.receiverMode : receiverMode // ignore: cast_nullable_to_non_nullable
as PurchaseRequestReceiverMode,fixedReceiverIds: null == fixedReceiverIds ? _self._fixedReceiverIds : fixedReceiverIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
