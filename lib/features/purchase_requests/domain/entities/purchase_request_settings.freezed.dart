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

 String get companyId; String? get firstApproverId; String? get invoicePreparerId; String? get invoiceApproverId; String? get accountantId; PurchaseRequestReceiverMode get receiverMode; String? get fixedReceiverId;
/// Create a copy of PurchaseRequestSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PurchaseRequestSettingsCopyWith<PurchaseRequestSettings> get copyWith => _$PurchaseRequestSettingsCopyWithImpl<PurchaseRequestSettings>(this as PurchaseRequestSettings, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PurchaseRequestSettings&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.firstApproverId, firstApproverId) || other.firstApproverId == firstApproverId)&&(identical(other.invoicePreparerId, invoicePreparerId) || other.invoicePreparerId == invoicePreparerId)&&(identical(other.invoiceApproverId, invoiceApproverId) || other.invoiceApproverId == invoiceApproverId)&&(identical(other.accountantId, accountantId) || other.accountantId == accountantId)&&(identical(other.receiverMode, receiverMode) || other.receiverMode == receiverMode)&&(identical(other.fixedReceiverId, fixedReceiverId) || other.fixedReceiverId == fixedReceiverId));
}


@override
int get hashCode => Object.hash(runtimeType,companyId,firstApproverId,invoicePreparerId,invoiceApproverId,accountantId,receiverMode,fixedReceiverId);

@override
String toString() {
  return 'PurchaseRequestSettings(companyId: $companyId, firstApproverId: $firstApproverId, invoicePreparerId: $invoicePreparerId, invoiceApproverId: $invoiceApproverId, accountantId: $accountantId, receiverMode: $receiverMode, fixedReceiverId: $fixedReceiverId)';
}


}

/// @nodoc
abstract mixin class $PurchaseRequestSettingsCopyWith<$Res>  {
  factory $PurchaseRequestSettingsCopyWith(PurchaseRequestSettings value, $Res Function(PurchaseRequestSettings) _then) = _$PurchaseRequestSettingsCopyWithImpl;
@useResult
$Res call({
 String companyId, String? firstApproverId, String? invoicePreparerId, String? invoiceApproverId, String? accountantId, PurchaseRequestReceiverMode receiverMode, String? fixedReceiverId
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
@pragma('vm:prefer-inline') @override $Res call({Object? companyId = null,Object? firstApproverId = freezed,Object? invoicePreparerId = freezed,Object? invoiceApproverId = freezed,Object? accountantId = freezed,Object? receiverMode = null,Object? fixedReceiverId = freezed,}) {
  return _then(_self.copyWith(
companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,firstApproverId: freezed == firstApproverId ? _self.firstApproverId : firstApproverId // ignore: cast_nullable_to_non_nullable
as String?,invoicePreparerId: freezed == invoicePreparerId ? _self.invoicePreparerId : invoicePreparerId // ignore: cast_nullable_to_non_nullable
as String?,invoiceApproverId: freezed == invoiceApproverId ? _self.invoiceApproverId : invoiceApproverId // ignore: cast_nullable_to_non_nullable
as String?,accountantId: freezed == accountantId ? _self.accountantId : accountantId // ignore: cast_nullable_to_non_nullable
as String?,receiverMode: null == receiverMode ? _self.receiverMode : receiverMode // ignore: cast_nullable_to_non_nullable
as PurchaseRequestReceiverMode,fixedReceiverId: freezed == fixedReceiverId ? _self.fixedReceiverId : fixedReceiverId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc


class _PurchaseRequestSettings implements PurchaseRequestSettings {
  const _PurchaseRequestSettings({required this.companyId, this.firstApproverId, this.invoicePreparerId, this.invoiceApproverId, this.accountantId, this.receiverMode = PurchaseRequestReceiverMode.initiator, this.fixedReceiverId});
  

@override final  String companyId;
@override final  String? firstApproverId;
@override final  String? invoicePreparerId;
@override final  String? invoiceApproverId;
@override final  String? accountantId;
@override@JsonKey() final  PurchaseRequestReceiverMode receiverMode;
@override final  String? fixedReceiverId;

/// Create a copy of PurchaseRequestSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PurchaseRequestSettingsCopyWith<_PurchaseRequestSettings> get copyWith => __$PurchaseRequestSettingsCopyWithImpl<_PurchaseRequestSettings>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PurchaseRequestSettings&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.firstApproverId, firstApproverId) || other.firstApproverId == firstApproverId)&&(identical(other.invoicePreparerId, invoicePreparerId) || other.invoicePreparerId == invoicePreparerId)&&(identical(other.invoiceApproverId, invoiceApproverId) || other.invoiceApproverId == invoiceApproverId)&&(identical(other.accountantId, accountantId) || other.accountantId == accountantId)&&(identical(other.receiverMode, receiverMode) || other.receiverMode == receiverMode)&&(identical(other.fixedReceiverId, fixedReceiverId) || other.fixedReceiverId == fixedReceiverId));
}


@override
int get hashCode => Object.hash(runtimeType,companyId,firstApproverId,invoicePreparerId,invoiceApproverId,accountantId,receiverMode,fixedReceiverId);

@override
String toString() {
  return 'PurchaseRequestSettings(companyId: $companyId, firstApproverId: $firstApproverId, invoicePreparerId: $invoicePreparerId, invoiceApproverId: $invoiceApproverId, accountantId: $accountantId, receiverMode: $receiverMode, fixedReceiverId: $fixedReceiverId)';
}


}

/// @nodoc
abstract mixin class _$PurchaseRequestSettingsCopyWith<$Res> implements $PurchaseRequestSettingsCopyWith<$Res> {
  factory _$PurchaseRequestSettingsCopyWith(_PurchaseRequestSettings value, $Res Function(_PurchaseRequestSettings) _then) = __$PurchaseRequestSettingsCopyWithImpl;
@override @useResult
$Res call({
 String companyId, String? firstApproverId, String? invoicePreparerId, String? invoiceApproverId, String? accountantId, PurchaseRequestReceiverMode receiverMode, String? fixedReceiverId
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
@override @pragma('vm:prefer-inline') $Res call({Object? companyId = null,Object? firstApproverId = freezed,Object? invoicePreparerId = freezed,Object? invoiceApproverId = freezed,Object? accountantId = freezed,Object? receiverMode = null,Object? fixedReceiverId = freezed,}) {
  return _then(_PurchaseRequestSettings(
companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,firstApproverId: freezed == firstApproverId ? _self.firstApproverId : firstApproverId // ignore: cast_nullable_to_non_nullable
as String?,invoicePreparerId: freezed == invoicePreparerId ? _self.invoicePreparerId : invoicePreparerId // ignore: cast_nullable_to_non_nullable
as String?,invoiceApproverId: freezed == invoiceApproverId ? _self.invoiceApproverId : invoiceApproverId // ignore: cast_nullable_to_non_nullable
as String?,accountantId: freezed == accountantId ? _self.accountantId : accountantId // ignore: cast_nullable_to_non_nullable
as String?,receiverMode: null == receiverMode ? _self.receiverMode : receiverMode // ignore: cast_nullable_to_non_nullable
as PurchaseRequestReceiverMode,fixedReceiverId: freezed == fixedReceiverId ? _self.fixedReceiverId : fixedReceiverId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
