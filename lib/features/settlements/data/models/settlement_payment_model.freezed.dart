// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settlement_payment_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SettlementPaymentModel {

 String get id; String get companyId; String get settlementOperationId;@JsonKey(toJson: dateOnlyToJson) DateTime get paymentDate; double get amount; String? get note; String? get cashFlowTransactionId; DateTime? get createdAt; String? get createdBy;
/// Create a copy of SettlementPaymentModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettlementPaymentModelCopyWith<SettlementPaymentModel> get copyWith => _$SettlementPaymentModelCopyWithImpl<SettlementPaymentModel>(this as SettlementPaymentModel, _$identity);

  /// Serializes this SettlementPaymentModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettlementPaymentModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.settlementOperationId, settlementOperationId) || other.settlementOperationId == settlementOperationId)&&(identical(other.paymentDate, paymentDate) || other.paymentDate == paymentDate)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.note, note) || other.note == note)&&(identical(other.cashFlowTransactionId, cashFlowTransactionId) || other.cashFlowTransactionId == cashFlowTransactionId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,settlementOperationId,paymentDate,amount,note,cashFlowTransactionId,createdAt,createdBy);

@override
String toString() {
  return 'SettlementPaymentModel(id: $id, companyId: $companyId, settlementOperationId: $settlementOperationId, paymentDate: $paymentDate, amount: $amount, note: $note, cashFlowTransactionId: $cashFlowTransactionId, createdAt: $createdAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class $SettlementPaymentModelCopyWith<$Res>  {
  factory $SettlementPaymentModelCopyWith(SettlementPaymentModel value, $Res Function(SettlementPaymentModel) _then) = _$SettlementPaymentModelCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String settlementOperationId,@JsonKey(toJson: dateOnlyToJson) DateTime paymentDate, double amount, String? note, String? cashFlowTransactionId, DateTime? createdAt, String? createdBy
});




}
/// @nodoc
class _$SettlementPaymentModelCopyWithImpl<$Res>
    implements $SettlementPaymentModelCopyWith<$Res> {
  _$SettlementPaymentModelCopyWithImpl(this._self, this._then);

  final SettlementPaymentModel _self;
  final $Res Function(SettlementPaymentModel) _then;

/// Create a copy of SettlementPaymentModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? settlementOperationId = null,Object? paymentDate = null,Object? amount = null,Object? note = freezed,Object? cashFlowTransactionId = freezed,Object? createdAt = freezed,Object? createdBy = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,settlementOperationId: null == settlementOperationId ? _self.settlementOperationId : settlementOperationId // ignore: cast_nullable_to_non_nullable
as String,paymentDate: null == paymentDate ? _self.paymentDate : paymentDate // ignore: cast_nullable_to_non_nullable
as DateTime,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,cashFlowTransactionId: freezed == cashFlowTransactionId ? _self.cashFlowTransactionId : cashFlowTransactionId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _SettlementPaymentModel extends SettlementPaymentModel {
  const _SettlementPaymentModel({required this.id, required this.companyId, required this.settlementOperationId, @JsonKey(toJson: dateOnlyToJson) required this.paymentDate, required this.amount, this.note, this.cashFlowTransactionId, this.createdAt, this.createdBy}): super._();
  factory _SettlementPaymentModel.fromJson(Map<String, dynamic> json) => _$SettlementPaymentModelFromJson(json);

@override final  String id;
@override final  String companyId;
@override final  String settlementOperationId;
@override@JsonKey(toJson: dateOnlyToJson) final  DateTime paymentDate;
@override final  double amount;
@override final  String? note;
@override final  String? cashFlowTransactionId;
@override final  DateTime? createdAt;
@override final  String? createdBy;

/// Create a copy of SettlementPaymentModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SettlementPaymentModelCopyWith<_SettlementPaymentModel> get copyWith => __$SettlementPaymentModelCopyWithImpl<_SettlementPaymentModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SettlementPaymentModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SettlementPaymentModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.settlementOperationId, settlementOperationId) || other.settlementOperationId == settlementOperationId)&&(identical(other.paymentDate, paymentDate) || other.paymentDate == paymentDate)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.note, note) || other.note == note)&&(identical(other.cashFlowTransactionId, cashFlowTransactionId) || other.cashFlowTransactionId == cashFlowTransactionId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,settlementOperationId,paymentDate,amount,note,cashFlowTransactionId,createdAt,createdBy);

@override
String toString() {
  return 'SettlementPaymentModel(id: $id, companyId: $companyId, settlementOperationId: $settlementOperationId, paymentDate: $paymentDate, amount: $amount, note: $note, cashFlowTransactionId: $cashFlowTransactionId, createdAt: $createdAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class _$SettlementPaymentModelCopyWith<$Res> implements $SettlementPaymentModelCopyWith<$Res> {
  factory _$SettlementPaymentModelCopyWith(_SettlementPaymentModel value, $Res Function(_SettlementPaymentModel) _then) = __$SettlementPaymentModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String settlementOperationId,@JsonKey(toJson: dateOnlyToJson) DateTime paymentDate, double amount, String? note, String? cashFlowTransactionId, DateTime? createdAt, String? createdBy
});




}
/// @nodoc
class __$SettlementPaymentModelCopyWithImpl<$Res>
    implements _$SettlementPaymentModelCopyWith<$Res> {
  __$SettlementPaymentModelCopyWithImpl(this._self, this._then);

  final _SettlementPaymentModel _self;
  final $Res Function(_SettlementPaymentModel) _then;

/// Create a copy of SettlementPaymentModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? settlementOperationId = null,Object? paymentDate = null,Object? amount = null,Object? note = freezed,Object? cashFlowTransactionId = freezed,Object? createdAt = freezed,Object? createdBy = freezed,}) {
  return _then(_SettlementPaymentModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,settlementOperationId: null == settlementOperationId ? _self.settlementOperationId : settlementOperationId // ignore: cast_nullable_to_non_nullable
as String,paymentDate: null == paymentDate ? _self.paymentDate : paymentDate // ignore: cast_nullable_to_non_nullable
as DateTime,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,cashFlowTransactionId: freezed == cashFlowTransactionId ? _self.cashFlowTransactionId : cashFlowTransactionId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
