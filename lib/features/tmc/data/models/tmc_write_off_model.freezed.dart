// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tmc_write_off_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TmcWriteOffModel {

 String get id; String get companyId; String get itemId; String? get unitId;@JsonKey(fromJson: tmcParseRequiredDate, toJson: tmcDateOnlyToJson) DateTime get writtenOffAt; TmcWriteOffReason get reason; double get quantity; String? get conditionId; double? get bookValue; String? get responsibleEmployeeId; String? get objectId; String? get actNumber; String? get comment; String? get operationId; DateTime? get createdAt; DateTime? get updatedAt; String? get createdBy;@JsonKey(includeToJson: false) String? get itemName;@JsonKey(includeToJson: false) String? get inventoryNumber;
/// Create a copy of TmcWriteOffModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TmcWriteOffModelCopyWith<TmcWriteOffModel> get copyWith => _$TmcWriteOffModelCopyWithImpl<TmcWriteOffModel>(this as TmcWriteOffModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TmcWriteOffModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.writtenOffAt, writtenOffAt) || other.writtenOffAt == writtenOffAt)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.conditionId, conditionId) || other.conditionId == conditionId)&&(identical(other.bookValue, bookValue) || other.bookValue == bookValue)&&(identical(other.responsibleEmployeeId, responsibleEmployeeId) || other.responsibleEmployeeId == responsibleEmployeeId)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.actNumber, actNumber) || other.actNumber == actNumber)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.operationId, operationId) || other.operationId == operationId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.itemName, itemName) || other.itemName == itemName)&&(identical(other.inventoryNumber, inventoryNumber) || other.inventoryNumber == inventoryNumber));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,itemId,unitId,writtenOffAt,reason,quantity,conditionId,bookValue,responsibleEmployeeId,objectId,actNumber,comment,operationId,createdAt,updatedAt,createdBy,itemName,inventoryNumber]);

@override
String toString() {
  return 'TmcWriteOffModel(id: $id, companyId: $companyId, itemId: $itemId, unitId: $unitId, writtenOffAt: $writtenOffAt, reason: $reason, quantity: $quantity, conditionId: $conditionId, bookValue: $bookValue, responsibleEmployeeId: $responsibleEmployeeId, objectId: $objectId, actNumber: $actNumber, comment: $comment, operationId: $operationId, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, itemName: $itemName, inventoryNumber: $inventoryNumber)';
}


}

/// @nodoc
abstract mixin class $TmcWriteOffModelCopyWith<$Res>  {
  factory $TmcWriteOffModelCopyWith(TmcWriteOffModel value, $Res Function(TmcWriteOffModel) _then) = _$TmcWriteOffModelCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String itemId, String? unitId,@JsonKey(fromJson: tmcParseRequiredDate, toJson: tmcDateOnlyToJson) DateTime writtenOffAt, TmcWriteOffReason reason, double quantity, String? conditionId, double? bookValue, String? responsibleEmployeeId, String? objectId, String? actNumber, String? comment, String? operationId, DateTime? createdAt, DateTime? updatedAt, String? createdBy,@JsonKey(includeToJson: false) String? itemName,@JsonKey(includeToJson: false) String? inventoryNumber
});




}
/// @nodoc
class _$TmcWriteOffModelCopyWithImpl<$Res>
    implements $TmcWriteOffModelCopyWith<$Res> {
  _$TmcWriteOffModelCopyWithImpl(this._self, this._then);

  final TmcWriteOffModel _self;
  final $Res Function(TmcWriteOffModel) _then;

/// Create a copy of TmcWriteOffModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? itemId = null,Object? unitId = freezed,Object? writtenOffAt = null,Object? reason = null,Object? quantity = null,Object? conditionId = freezed,Object? bookValue = freezed,Object? responsibleEmployeeId = freezed,Object? objectId = freezed,Object? actNumber = freezed,Object? comment = freezed,Object? operationId = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,Object? itemName = freezed,Object? inventoryNumber = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,unitId: freezed == unitId ? _self.unitId : unitId // ignore: cast_nullable_to_non_nullable
as String?,writtenOffAt: null == writtenOffAt ? _self.writtenOffAt : writtenOffAt // ignore: cast_nullable_to_non_nullable
as DateTime,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as TmcWriteOffReason,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double,conditionId: freezed == conditionId ? _self.conditionId : conditionId // ignore: cast_nullable_to_non_nullable
as String?,bookValue: freezed == bookValue ? _self.bookValue : bookValue // ignore: cast_nullable_to_non_nullable
as double?,responsibleEmployeeId: freezed == responsibleEmployeeId ? _self.responsibleEmployeeId : responsibleEmployeeId // ignore: cast_nullable_to_non_nullable
as String?,objectId: freezed == objectId ? _self.objectId : objectId // ignore: cast_nullable_to_non_nullable
as String?,actNumber: freezed == actNumber ? _self.actNumber : actNumber // ignore: cast_nullable_to_non_nullable
as String?,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,operationId: freezed == operationId ? _self.operationId : operationId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,itemName: freezed == itemName ? _self.itemName : itemName // ignore: cast_nullable_to_non_nullable
as String?,inventoryNumber: freezed == inventoryNumber ? _self.inventoryNumber : inventoryNumber // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _TmcWriteOffModel extends TmcWriteOffModel {
  const _TmcWriteOffModel({required this.id, required this.companyId, required this.itemId, this.unitId, @JsonKey(fromJson: tmcParseRequiredDate, toJson: tmcDateOnlyToJson) required this.writtenOffAt, required this.reason, this.quantity = 1, this.conditionId, this.bookValue, this.responsibleEmployeeId, this.objectId, this.actNumber, this.comment, this.operationId, this.createdAt, this.updatedAt, this.createdBy, @JsonKey(includeToJson: false) this.itemName, @JsonKey(includeToJson: false) this.inventoryNumber}): super._();
  

@override final  String id;
@override final  String companyId;
@override final  String itemId;
@override final  String? unitId;
@override@JsonKey(fromJson: tmcParseRequiredDate, toJson: tmcDateOnlyToJson) final  DateTime writtenOffAt;
@override final  TmcWriteOffReason reason;
@override@JsonKey() final  double quantity;
@override final  String? conditionId;
@override final  double? bookValue;
@override final  String? responsibleEmployeeId;
@override final  String? objectId;
@override final  String? actNumber;
@override final  String? comment;
@override final  String? operationId;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;
@override final  String? createdBy;
@override@JsonKey(includeToJson: false) final  String? itemName;
@override@JsonKey(includeToJson: false) final  String? inventoryNumber;

/// Create a copy of TmcWriteOffModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TmcWriteOffModelCopyWith<_TmcWriteOffModel> get copyWith => __$TmcWriteOffModelCopyWithImpl<_TmcWriteOffModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TmcWriteOffModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.writtenOffAt, writtenOffAt) || other.writtenOffAt == writtenOffAt)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.conditionId, conditionId) || other.conditionId == conditionId)&&(identical(other.bookValue, bookValue) || other.bookValue == bookValue)&&(identical(other.responsibleEmployeeId, responsibleEmployeeId) || other.responsibleEmployeeId == responsibleEmployeeId)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.actNumber, actNumber) || other.actNumber == actNumber)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.operationId, operationId) || other.operationId == operationId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.itemName, itemName) || other.itemName == itemName)&&(identical(other.inventoryNumber, inventoryNumber) || other.inventoryNumber == inventoryNumber));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,itemId,unitId,writtenOffAt,reason,quantity,conditionId,bookValue,responsibleEmployeeId,objectId,actNumber,comment,operationId,createdAt,updatedAt,createdBy,itemName,inventoryNumber]);

@override
String toString() {
  return 'TmcWriteOffModel(id: $id, companyId: $companyId, itemId: $itemId, unitId: $unitId, writtenOffAt: $writtenOffAt, reason: $reason, quantity: $quantity, conditionId: $conditionId, bookValue: $bookValue, responsibleEmployeeId: $responsibleEmployeeId, objectId: $objectId, actNumber: $actNumber, comment: $comment, operationId: $operationId, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, itemName: $itemName, inventoryNumber: $inventoryNumber)';
}


}

/// @nodoc
abstract mixin class _$TmcWriteOffModelCopyWith<$Res> implements $TmcWriteOffModelCopyWith<$Res> {
  factory _$TmcWriteOffModelCopyWith(_TmcWriteOffModel value, $Res Function(_TmcWriteOffModel) _then) = __$TmcWriteOffModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String itemId, String? unitId,@JsonKey(fromJson: tmcParseRequiredDate, toJson: tmcDateOnlyToJson) DateTime writtenOffAt, TmcWriteOffReason reason, double quantity, String? conditionId, double? bookValue, String? responsibleEmployeeId, String? objectId, String? actNumber, String? comment, String? operationId, DateTime? createdAt, DateTime? updatedAt, String? createdBy,@JsonKey(includeToJson: false) String? itemName,@JsonKey(includeToJson: false) String? inventoryNumber
});




}
/// @nodoc
class __$TmcWriteOffModelCopyWithImpl<$Res>
    implements _$TmcWriteOffModelCopyWith<$Res> {
  __$TmcWriteOffModelCopyWithImpl(this._self, this._then);

  final _TmcWriteOffModel _self;
  final $Res Function(_TmcWriteOffModel) _then;

/// Create a copy of TmcWriteOffModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? itemId = null,Object? unitId = freezed,Object? writtenOffAt = null,Object? reason = null,Object? quantity = null,Object? conditionId = freezed,Object? bookValue = freezed,Object? responsibleEmployeeId = freezed,Object? objectId = freezed,Object? actNumber = freezed,Object? comment = freezed,Object? operationId = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,Object? itemName = freezed,Object? inventoryNumber = freezed,}) {
  return _then(_TmcWriteOffModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,unitId: freezed == unitId ? _self.unitId : unitId // ignore: cast_nullable_to_non_nullable
as String?,writtenOffAt: null == writtenOffAt ? _self.writtenOffAt : writtenOffAt // ignore: cast_nullable_to_non_nullable
as DateTime,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as TmcWriteOffReason,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double,conditionId: freezed == conditionId ? _self.conditionId : conditionId // ignore: cast_nullable_to_non_nullable
as String?,bookValue: freezed == bookValue ? _self.bookValue : bookValue // ignore: cast_nullable_to_non_nullable
as double?,responsibleEmployeeId: freezed == responsibleEmployeeId ? _self.responsibleEmployeeId : responsibleEmployeeId // ignore: cast_nullable_to_non_nullable
as String?,objectId: freezed == objectId ? _self.objectId : objectId // ignore: cast_nullable_to_non_nullable
as String?,actNumber: freezed == actNumber ? _self.actNumber : actNumber // ignore: cast_nullable_to_non_nullable
as String?,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,operationId: freezed == operationId ? _self.operationId : operationId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,itemName: freezed == itemName ? _self.itemName : itemName // ignore: cast_nullable_to_non_nullable
as String?,inventoryNumber: freezed == inventoryNumber ? _self.inventoryNumber : inventoryNumber // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
