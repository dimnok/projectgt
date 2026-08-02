// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tmc_write_off.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TmcWriteOff {

/// Идентификатор записи.
 String get id;/// Компания-владелец.
 String get companyId;/// Позиция каталога.
 String get itemId;/// Единица.
 String? get unitId;/// Дата списания.
 DateTime get writtenOffAt;/// Причина списания.
 TmcWriteOffReason get reason;/// Количество.
 double get quantity;/// Состояние.
 String? get conditionId;/// Балансовая стоимость.
 double? get bookValue;/// Ответственный сотрудник.
 String? get responsibleEmployeeId;/// Объект.
 String? get objectId;/// Номер акта.
 String? get actNumber;/// Комментарий.
 String? get comment;/// Связанная операция.
 String? get operationId;/// Дата создания.
 DateTime? get createdAt;/// Дата обновления.
 DateTime? get updatedAt;/// Автор создания.
 String? get createdBy;/// Наименование позиции (join).
 String? get itemName;/// Инвентарный номер (join).
 String? get inventoryNumber;
/// Create a copy of TmcWriteOff
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TmcWriteOffCopyWith<TmcWriteOff> get copyWith => _$TmcWriteOffCopyWithImpl<TmcWriteOff>(this as TmcWriteOff, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TmcWriteOff&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.writtenOffAt, writtenOffAt) || other.writtenOffAt == writtenOffAt)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.conditionId, conditionId) || other.conditionId == conditionId)&&(identical(other.bookValue, bookValue) || other.bookValue == bookValue)&&(identical(other.responsibleEmployeeId, responsibleEmployeeId) || other.responsibleEmployeeId == responsibleEmployeeId)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.actNumber, actNumber) || other.actNumber == actNumber)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.operationId, operationId) || other.operationId == operationId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.itemName, itemName) || other.itemName == itemName)&&(identical(other.inventoryNumber, inventoryNumber) || other.inventoryNumber == inventoryNumber));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,itemId,unitId,writtenOffAt,reason,quantity,conditionId,bookValue,responsibleEmployeeId,objectId,actNumber,comment,operationId,createdAt,updatedAt,createdBy,itemName,inventoryNumber]);

@override
String toString() {
  return 'TmcWriteOff(id: $id, companyId: $companyId, itemId: $itemId, unitId: $unitId, writtenOffAt: $writtenOffAt, reason: $reason, quantity: $quantity, conditionId: $conditionId, bookValue: $bookValue, responsibleEmployeeId: $responsibleEmployeeId, objectId: $objectId, actNumber: $actNumber, comment: $comment, operationId: $operationId, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, itemName: $itemName, inventoryNumber: $inventoryNumber)';
}


}

/// @nodoc
abstract mixin class $TmcWriteOffCopyWith<$Res>  {
  factory $TmcWriteOffCopyWith(TmcWriteOff value, $Res Function(TmcWriteOff) _then) = _$TmcWriteOffCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String itemId, String? unitId, DateTime writtenOffAt, TmcWriteOffReason reason, double quantity, String? conditionId, double? bookValue, String? responsibleEmployeeId, String? objectId, String? actNumber, String? comment, String? operationId, DateTime? createdAt, DateTime? updatedAt, String? createdBy, String? itemName, String? inventoryNumber
});




}
/// @nodoc
class _$TmcWriteOffCopyWithImpl<$Res>
    implements $TmcWriteOffCopyWith<$Res> {
  _$TmcWriteOffCopyWithImpl(this._self, this._then);

  final TmcWriteOff _self;
  final $Res Function(TmcWriteOff) _then;

/// Create a copy of TmcWriteOff
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


class _TmcWriteOff implements TmcWriteOff {
  const _TmcWriteOff({required this.id, required this.companyId, required this.itemId, this.unitId, required this.writtenOffAt, required this.reason, this.quantity = 1, this.conditionId, this.bookValue, this.responsibleEmployeeId, this.objectId, this.actNumber, this.comment, this.operationId, this.createdAt, this.updatedAt, this.createdBy, this.itemName, this.inventoryNumber});
  

/// Идентификатор записи.
@override final  String id;
/// Компания-владелец.
@override final  String companyId;
/// Позиция каталога.
@override final  String itemId;
/// Единица.
@override final  String? unitId;
/// Дата списания.
@override final  DateTime writtenOffAt;
/// Причина списания.
@override final  TmcWriteOffReason reason;
/// Количество.
@override@JsonKey() final  double quantity;
/// Состояние.
@override final  String? conditionId;
/// Балансовая стоимость.
@override final  double? bookValue;
/// Ответственный сотрудник.
@override final  String? responsibleEmployeeId;
/// Объект.
@override final  String? objectId;
/// Номер акта.
@override final  String? actNumber;
/// Комментарий.
@override final  String? comment;
/// Связанная операция.
@override final  String? operationId;
/// Дата создания.
@override final  DateTime? createdAt;
/// Дата обновления.
@override final  DateTime? updatedAt;
/// Автор создания.
@override final  String? createdBy;
/// Наименование позиции (join).
@override final  String? itemName;
/// Инвентарный номер (join).
@override final  String? inventoryNumber;

/// Create a copy of TmcWriteOff
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TmcWriteOffCopyWith<_TmcWriteOff> get copyWith => __$TmcWriteOffCopyWithImpl<_TmcWriteOff>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TmcWriteOff&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.writtenOffAt, writtenOffAt) || other.writtenOffAt == writtenOffAt)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.conditionId, conditionId) || other.conditionId == conditionId)&&(identical(other.bookValue, bookValue) || other.bookValue == bookValue)&&(identical(other.responsibleEmployeeId, responsibleEmployeeId) || other.responsibleEmployeeId == responsibleEmployeeId)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.actNumber, actNumber) || other.actNumber == actNumber)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.operationId, operationId) || other.operationId == operationId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.itemName, itemName) || other.itemName == itemName)&&(identical(other.inventoryNumber, inventoryNumber) || other.inventoryNumber == inventoryNumber));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,itemId,unitId,writtenOffAt,reason,quantity,conditionId,bookValue,responsibleEmployeeId,objectId,actNumber,comment,operationId,createdAt,updatedAt,createdBy,itemName,inventoryNumber]);

@override
String toString() {
  return 'TmcWriteOff(id: $id, companyId: $companyId, itemId: $itemId, unitId: $unitId, writtenOffAt: $writtenOffAt, reason: $reason, quantity: $quantity, conditionId: $conditionId, bookValue: $bookValue, responsibleEmployeeId: $responsibleEmployeeId, objectId: $objectId, actNumber: $actNumber, comment: $comment, operationId: $operationId, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, itemName: $itemName, inventoryNumber: $inventoryNumber)';
}


}

/// @nodoc
abstract mixin class _$TmcWriteOffCopyWith<$Res> implements $TmcWriteOffCopyWith<$Res> {
  factory _$TmcWriteOffCopyWith(_TmcWriteOff value, $Res Function(_TmcWriteOff) _then) = __$TmcWriteOffCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String itemId, String? unitId, DateTime writtenOffAt, TmcWriteOffReason reason, double quantity, String? conditionId, double? bookValue, String? responsibleEmployeeId, String? objectId, String? actNumber, String? comment, String? operationId, DateTime? createdAt, DateTime? updatedAt, String? createdBy, String? itemName, String? inventoryNumber
});




}
/// @nodoc
class __$TmcWriteOffCopyWithImpl<$Res>
    implements _$TmcWriteOffCopyWith<$Res> {
  __$TmcWriteOffCopyWithImpl(this._self, this._then);

  final _TmcWriteOff _self;
  final $Res Function(_TmcWriteOff) _then;

/// Create a copy of TmcWriteOff
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? itemId = null,Object? unitId = freezed,Object? writtenOffAt = null,Object? reason = null,Object? quantity = null,Object? conditionId = freezed,Object? bookValue = freezed,Object? responsibleEmployeeId = freezed,Object? objectId = freezed,Object? actNumber = freezed,Object? comment = freezed,Object? operationId = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,Object? itemName = freezed,Object? inventoryNumber = freezed,}) {
  return _then(_TmcWriteOff(
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
