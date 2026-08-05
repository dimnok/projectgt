// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settlement_payment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SettlementPayment {

/// Идентификатор записи.
 String get id;/// Компания-владелец.
 String get companyId;/// Счёт, к которому относится оплата.
 String get settlementOperationId;/// Дата оплаты.
 DateTime get paymentDate;/// Сумма оплаты.
 double get amount;/// Примечание.
 String? get note;/// Дата создания.
 DateTime? get createdAt;/// Автор записи.
 String? get createdBy;
/// Create a copy of SettlementPayment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettlementPaymentCopyWith<SettlementPayment> get copyWith => _$SettlementPaymentCopyWithImpl<SettlementPayment>(this as SettlementPayment, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettlementPayment&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.settlementOperationId, settlementOperationId) || other.settlementOperationId == settlementOperationId)&&(identical(other.paymentDate, paymentDate) || other.paymentDate == paymentDate)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.note, note) || other.note == note)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,settlementOperationId,paymentDate,amount,note,createdAt,createdBy);

@override
String toString() {
  return 'SettlementPayment(id: $id, companyId: $companyId, settlementOperationId: $settlementOperationId, paymentDate: $paymentDate, amount: $amount, note: $note, createdAt: $createdAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class $SettlementPaymentCopyWith<$Res>  {
  factory $SettlementPaymentCopyWith(SettlementPayment value, $Res Function(SettlementPayment) _then) = _$SettlementPaymentCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String settlementOperationId, DateTime paymentDate, double amount, String? note, DateTime? createdAt, String? createdBy
});




}
/// @nodoc
class _$SettlementPaymentCopyWithImpl<$Res>
    implements $SettlementPaymentCopyWith<$Res> {
  _$SettlementPaymentCopyWithImpl(this._self, this._then);

  final SettlementPayment _self;
  final $Res Function(SettlementPayment) _then;

/// Create a copy of SettlementPayment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? settlementOperationId = null,Object? paymentDate = null,Object? amount = null,Object? note = freezed,Object? createdAt = freezed,Object? createdBy = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,settlementOperationId: null == settlementOperationId ? _self.settlementOperationId : settlementOperationId // ignore: cast_nullable_to_non_nullable
as String,paymentDate: null == paymentDate ? _self.paymentDate : paymentDate // ignore: cast_nullable_to_non_nullable
as DateTime,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc


class _SettlementPayment implements SettlementPayment {
  const _SettlementPayment({required this.id, required this.companyId, required this.settlementOperationId, required this.paymentDate, required this.amount, this.note, this.createdAt, this.createdBy});
  

/// Идентификатор записи.
@override final  String id;
/// Компания-владелец.
@override final  String companyId;
/// Счёт, к которому относится оплата.
@override final  String settlementOperationId;
/// Дата оплаты.
@override final  DateTime paymentDate;
/// Сумма оплаты.
@override final  double amount;
/// Примечание.
@override final  String? note;
/// Дата создания.
@override final  DateTime? createdAt;
/// Автор записи.
@override final  String? createdBy;

/// Create a copy of SettlementPayment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SettlementPaymentCopyWith<_SettlementPayment> get copyWith => __$SettlementPaymentCopyWithImpl<_SettlementPayment>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SettlementPayment&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.settlementOperationId, settlementOperationId) || other.settlementOperationId == settlementOperationId)&&(identical(other.paymentDate, paymentDate) || other.paymentDate == paymentDate)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.note, note) || other.note == note)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,settlementOperationId,paymentDate,amount,note,createdAt,createdBy);

@override
String toString() {
  return 'SettlementPayment(id: $id, companyId: $companyId, settlementOperationId: $settlementOperationId, paymentDate: $paymentDate, amount: $amount, note: $note, createdAt: $createdAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class _$SettlementPaymentCopyWith<$Res> implements $SettlementPaymentCopyWith<$Res> {
  factory _$SettlementPaymentCopyWith(_SettlementPayment value, $Res Function(_SettlementPayment) _then) = __$SettlementPaymentCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String settlementOperationId, DateTime paymentDate, double amount, String? note, DateTime? createdAt, String? createdBy
});




}
/// @nodoc
class __$SettlementPaymentCopyWithImpl<$Res>
    implements _$SettlementPaymentCopyWith<$Res> {
  __$SettlementPaymentCopyWithImpl(this._self, this._then);

  final _SettlementPayment _self;
  final $Res Function(_SettlementPayment) _then;

/// Create a copy of SettlementPayment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? settlementOperationId = null,Object? paymentDate = null,Object? amount = null,Object? note = freezed,Object? createdAt = freezed,Object? createdBy = freezed,}) {
  return _then(_SettlementPayment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,settlementOperationId: null == settlementOperationId ? _self.settlementOperationId : settlementOperationId // ignore: cast_nullable_to_non_nullable
as String,paymentDate: null == paymentDate ? _self.paymentDate : paymentDate // ignore: cast_nullable_to_non_nullable
as DateTime,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
