// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tmc_operation_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TmcOperationItemModel {

 String get id; String get companyId; String get operationId; String get itemId; String? get unitId; double get quantity; double? get unitPrice; String? get conditionId; String? get completenessNote; String? get comment; String? get clothingSize; double? get heightCm; String? get season; int? get serviceLifeDays;@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) DateTime? get nextReplacementDate; DateTime? get createdAt;@JsonKey(includeToJson: false) String? get itemName;@JsonKey(includeToJson: false) String? get inventoryNumber;
/// Create a copy of TmcOperationItemModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TmcOperationItemModelCopyWith<TmcOperationItemModel> get copyWith => _$TmcOperationItemModelCopyWithImpl<TmcOperationItemModel>(this as TmcOperationItemModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TmcOperationItemModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.operationId, operationId) || other.operationId == operationId)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.conditionId, conditionId) || other.conditionId == conditionId)&&(identical(other.completenessNote, completenessNote) || other.completenessNote == completenessNote)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.clothingSize, clothingSize) || other.clothingSize == clothingSize)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.season, season) || other.season == season)&&(identical(other.serviceLifeDays, serviceLifeDays) || other.serviceLifeDays == serviceLifeDays)&&(identical(other.nextReplacementDate, nextReplacementDate) || other.nextReplacementDate == nextReplacementDate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.itemName, itemName) || other.itemName == itemName)&&(identical(other.inventoryNumber, inventoryNumber) || other.inventoryNumber == inventoryNumber));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,operationId,itemId,unitId,quantity,unitPrice,conditionId,completenessNote,comment,clothingSize,heightCm,season,serviceLifeDays,nextReplacementDate,createdAt,itemName,inventoryNumber);

@override
String toString() {
  return 'TmcOperationItemModel(id: $id, companyId: $companyId, operationId: $operationId, itemId: $itemId, unitId: $unitId, quantity: $quantity, unitPrice: $unitPrice, conditionId: $conditionId, completenessNote: $completenessNote, comment: $comment, clothingSize: $clothingSize, heightCm: $heightCm, season: $season, serviceLifeDays: $serviceLifeDays, nextReplacementDate: $nextReplacementDate, createdAt: $createdAt, itemName: $itemName, inventoryNumber: $inventoryNumber)';
}


}

/// @nodoc
abstract mixin class $TmcOperationItemModelCopyWith<$Res>  {
  factory $TmcOperationItemModelCopyWith(TmcOperationItemModel value, $Res Function(TmcOperationItemModel) _then) = _$TmcOperationItemModelCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String operationId, String itemId, String? unitId, double quantity, double? unitPrice, String? conditionId, String? completenessNote, String? comment, String? clothingSize, double? heightCm, String? season, int? serviceLifeDays,@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) DateTime? nextReplacementDate, DateTime? createdAt,@JsonKey(includeToJson: false) String? itemName,@JsonKey(includeToJson: false) String? inventoryNumber
});




}
/// @nodoc
class _$TmcOperationItemModelCopyWithImpl<$Res>
    implements $TmcOperationItemModelCopyWith<$Res> {
  _$TmcOperationItemModelCopyWithImpl(this._self, this._then);

  final TmcOperationItemModel _self;
  final $Res Function(TmcOperationItemModel) _then;

/// Create a copy of TmcOperationItemModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? operationId = null,Object? itemId = null,Object? unitId = freezed,Object? quantity = null,Object? unitPrice = freezed,Object? conditionId = freezed,Object? completenessNote = freezed,Object? comment = freezed,Object? clothingSize = freezed,Object? heightCm = freezed,Object? season = freezed,Object? serviceLifeDays = freezed,Object? nextReplacementDate = freezed,Object? createdAt = freezed,Object? itemName = freezed,Object? inventoryNumber = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,operationId: null == operationId ? _self.operationId : operationId // ignore: cast_nullable_to_non_nullable
as String,itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,unitId: freezed == unitId ? _self.unitId : unitId // ignore: cast_nullable_to_non_nullable
as String?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double,unitPrice: freezed == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as double?,conditionId: freezed == conditionId ? _self.conditionId : conditionId // ignore: cast_nullable_to_non_nullable
as String?,completenessNote: freezed == completenessNote ? _self.completenessNote : completenessNote // ignore: cast_nullable_to_non_nullable
as String?,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,clothingSize: freezed == clothingSize ? _self.clothingSize : clothingSize // ignore: cast_nullable_to_non_nullable
as String?,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as double?,season: freezed == season ? _self.season : season // ignore: cast_nullable_to_non_nullable
as String?,serviceLifeDays: freezed == serviceLifeDays ? _self.serviceLifeDays : serviceLifeDays // ignore: cast_nullable_to_non_nullable
as int?,nextReplacementDate: freezed == nextReplacementDate ? _self.nextReplacementDate : nextReplacementDate // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,itemName: freezed == itemName ? _self.itemName : itemName // ignore: cast_nullable_to_non_nullable
as String?,inventoryNumber: freezed == inventoryNumber ? _self.inventoryNumber : inventoryNumber // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _TmcOperationItemModel extends TmcOperationItemModel {
  const _TmcOperationItemModel({required this.id, required this.companyId, required this.operationId, required this.itemId, this.unitId, this.quantity = 1, this.unitPrice, this.conditionId, this.completenessNote, this.comment, this.clothingSize, this.heightCm, this.season, this.serviceLifeDays, @JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) this.nextReplacementDate, this.createdAt, @JsonKey(includeToJson: false) this.itemName, @JsonKey(includeToJson: false) this.inventoryNumber}): super._();
  

@override final  String id;
@override final  String companyId;
@override final  String operationId;
@override final  String itemId;
@override final  String? unitId;
@override@JsonKey() final  double quantity;
@override final  double? unitPrice;
@override final  String? conditionId;
@override final  String? completenessNote;
@override final  String? comment;
@override final  String? clothingSize;
@override final  double? heightCm;
@override final  String? season;
@override final  int? serviceLifeDays;
@override@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) final  DateTime? nextReplacementDate;
@override final  DateTime? createdAt;
@override@JsonKey(includeToJson: false) final  String? itemName;
@override@JsonKey(includeToJson: false) final  String? inventoryNumber;

/// Create a copy of TmcOperationItemModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TmcOperationItemModelCopyWith<_TmcOperationItemModel> get copyWith => __$TmcOperationItemModelCopyWithImpl<_TmcOperationItemModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TmcOperationItemModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.operationId, operationId) || other.operationId == operationId)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.conditionId, conditionId) || other.conditionId == conditionId)&&(identical(other.completenessNote, completenessNote) || other.completenessNote == completenessNote)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.clothingSize, clothingSize) || other.clothingSize == clothingSize)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.season, season) || other.season == season)&&(identical(other.serviceLifeDays, serviceLifeDays) || other.serviceLifeDays == serviceLifeDays)&&(identical(other.nextReplacementDate, nextReplacementDate) || other.nextReplacementDate == nextReplacementDate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.itemName, itemName) || other.itemName == itemName)&&(identical(other.inventoryNumber, inventoryNumber) || other.inventoryNumber == inventoryNumber));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,operationId,itemId,unitId,quantity,unitPrice,conditionId,completenessNote,comment,clothingSize,heightCm,season,serviceLifeDays,nextReplacementDate,createdAt,itemName,inventoryNumber);

@override
String toString() {
  return 'TmcOperationItemModel(id: $id, companyId: $companyId, operationId: $operationId, itemId: $itemId, unitId: $unitId, quantity: $quantity, unitPrice: $unitPrice, conditionId: $conditionId, completenessNote: $completenessNote, comment: $comment, clothingSize: $clothingSize, heightCm: $heightCm, season: $season, serviceLifeDays: $serviceLifeDays, nextReplacementDate: $nextReplacementDate, createdAt: $createdAt, itemName: $itemName, inventoryNumber: $inventoryNumber)';
}


}

/// @nodoc
abstract mixin class _$TmcOperationItemModelCopyWith<$Res> implements $TmcOperationItemModelCopyWith<$Res> {
  factory _$TmcOperationItemModelCopyWith(_TmcOperationItemModel value, $Res Function(_TmcOperationItemModel) _then) = __$TmcOperationItemModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String operationId, String itemId, String? unitId, double quantity, double? unitPrice, String? conditionId, String? completenessNote, String? comment, String? clothingSize, double? heightCm, String? season, int? serviceLifeDays,@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) DateTime? nextReplacementDate, DateTime? createdAt,@JsonKey(includeToJson: false) String? itemName,@JsonKey(includeToJson: false) String? inventoryNumber
});




}
/// @nodoc
class __$TmcOperationItemModelCopyWithImpl<$Res>
    implements _$TmcOperationItemModelCopyWith<$Res> {
  __$TmcOperationItemModelCopyWithImpl(this._self, this._then);

  final _TmcOperationItemModel _self;
  final $Res Function(_TmcOperationItemModel) _then;

/// Create a copy of TmcOperationItemModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? operationId = null,Object? itemId = null,Object? unitId = freezed,Object? quantity = null,Object? unitPrice = freezed,Object? conditionId = freezed,Object? completenessNote = freezed,Object? comment = freezed,Object? clothingSize = freezed,Object? heightCm = freezed,Object? season = freezed,Object? serviceLifeDays = freezed,Object? nextReplacementDate = freezed,Object? createdAt = freezed,Object? itemName = freezed,Object? inventoryNumber = freezed,}) {
  return _then(_TmcOperationItemModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,operationId: null == operationId ? _self.operationId : operationId // ignore: cast_nullable_to_non_nullable
as String,itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,unitId: freezed == unitId ? _self.unitId : unitId // ignore: cast_nullable_to_non_nullable
as String?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double,unitPrice: freezed == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as double?,conditionId: freezed == conditionId ? _self.conditionId : conditionId // ignore: cast_nullable_to_non_nullable
as String?,completenessNote: freezed == completenessNote ? _self.completenessNote : completenessNote // ignore: cast_nullable_to_non_nullable
as String?,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,clothingSize: freezed == clothingSize ? _self.clothingSize : clothingSize // ignore: cast_nullable_to_non_nullable
as String?,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as double?,season: freezed == season ? _self.season : season // ignore: cast_nullable_to_non_nullable
as String?,serviceLifeDays: freezed == serviceLifeDays ? _self.serviceLifeDays : serviceLifeDays // ignore: cast_nullable_to_non_nullable
as int?,nextReplacementDate: freezed == nextReplacementDate ? _self.nextReplacementDate : nextReplacementDate // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,itemName: freezed == itemName ? _self.itemName : itemName // ignore: cast_nullable_to_non_nullable
as String?,inventoryNumber: freezed == inventoryNumber ? _self.inventoryNumber : inventoryNumber // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$TmcOperationModel {

 String get id; String get companyId; TmcOperationType get operationType; DateTime get operatedAt; String? get documentNumber; String? get basis; String? get comment; TmcLocationType? get fromLocationType; String? get fromWarehouseId; String? get fromObjectId; String? get fromEmployeeId; String? get fromLocationNote; TmcLocationType? get toLocationType; String? get toWarehouseId; String? get toObjectId; String? get toEmployeeId; String? get toLocationNote; String? get responsibleEmployeeId; String? get objectId; String? get reversesOperationId;@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) DateTime? get plannedReturnDate; String? get conditionId; DateTime? get createdAt; DateTime? get updatedAt; String? get createdBy;@JsonKey(includeToJson: false) List<TmcOperationItemModel> get items;
/// Create a copy of TmcOperationModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TmcOperationModelCopyWith<TmcOperationModel> get copyWith => _$TmcOperationModelCopyWithImpl<TmcOperationModel>(this as TmcOperationModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TmcOperationModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.operationType, operationType) || other.operationType == operationType)&&(identical(other.operatedAt, operatedAt) || other.operatedAt == operatedAt)&&(identical(other.documentNumber, documentNumber) || other.documentNumber == documentNumber)&&(identical(other.basis, basis) || other.basis == basis)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.fromLocationType, fromLocationType) || other.fromLocationType == fromLocationType)&&(identical(other.fromWarehouseId, fromWarehouseId) || other.fromWarehouseId == fromWarehouseId)&&(identical(other.fromObjectId, fromObjectId) || other.fromObjectId == fromObjectId)&&(identical(other.fromEmployeeId, fromEmployeeId) || other.fromEmployeeId == fromEmployeeId)&&(identical(other.fromLocationNote, fromLocationNote) || other.fromLocationNote == fromLocationNote)&&(identical(other.toLocationType, toLocationType) || other.toLocationType == toLocationType)&&(identical(other.toWarehouseId, toWarehouseId) || other.toWarehouseId == toWarehouseId)&&(identical(other.toObjectId, toObjectId) || other.toObjectId == toObjectId)&&(identical(other.toEmployeeId, toEmployeeId) || other.toEmployeeId == toEmployeeId)&&(identical(other.toLocationNote, toLocationNote) || other.toLocationNote == toLocationNote)&&(identical(other.responsibleEmployeeId, responsibleEmployeeId) || other.responsibleEmployeeId == responsibleEmployeeId)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.reversesOperationId, reversesOperationId) || other.reversesOperationId == reversesOperationId)&&(identical(other.plannedReturnDate, plannedReturnDate) || other.plannedReturnDate == plannedReturnDate)&&(identical(other.conditionId, conditionId) || other.conditionId == conditionId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&const DeepCollectionEquality().equals(other.items, items));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,operationType,operatedAt,documentNumber,basis,comment,fromLocationType,fromWarehouseId,fromObjectId,fromEmployeeId,fromLocationNote,toLocationType,toWarehouseId,toObjectId,toEmployeeId,toLocationNote,responsibleEmployeeId,objectId,reversesOperationId,plannedReturnDate,conditionId,createdAt,updatedAt,createdBy,const DeepCollectionEquality().hash(items)]);

@override
String toString() {
  return 'TmcOperationModel(id: $id, companyId: $companyId, operationType: $operationType, operatedAt: $operatedAt, documentNumber: $documentNumber, basis: $basis, comment: $comment, fromLocationType: $fromLocationType, fromWarehouseId: $fromWarehouseId, fromObjectId: $fromObjectId, fromEmployeeId: $fromEmployeeId, fromLocationNote: $fromLocationNote, toLocationType: $toLocationType, toWarehouseId: $toWarehouseId, toObjectId: $toObjectId, toEmployeeId: $toEmployeeId, toLocationNote: $toLocationNote, responsibleEmployeeId: $responsibleEmployeeId, objectId: $objectId, reversesOperationId: $reversesOperationId, plannedReturnDate: $plannedReturnDate, conditionId: $conditionId, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, items: $items)';
}


}

/// @nodoc
abstract mixin class $TmcOperationModelCopyWith<$Res>  {
  factory $TmcOperationModelCopyWith(TmcOperationModel value, $Res Function(TmcOperationModel) _then) = _$TmcOperationModelCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, TmcOperationType operationType, DateTime operatedAt, String? documentNumber, String? basis, String? comment, TmcLocationType? fromLocationType, String? fromWarehouseId, String? fromObjectId, String? fromEmployeeId, String? fromLocationNote, TmcLocationType? toLocationType, String? toWarehouseId, String? toObjectId, String? toEmployeeId, String? toLocationNote, String? responsibleEmployeeId, String? objectId, String? reversesOperationId,@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) DateTime? plannedReturnDate, String? conditionId, DateTime? createdAt, DateTime? updatedAt, String? createdBy,@JsonKey(includeToJson: false) List<TmcOperationItemModel> items
});




}
/// @nodoc
class _$TmcOperationModelCopyWithImpl<$Res>
    implements $TmcOperationModelCopyWith<$Res> {
  _$TmcOperationModelCopyWithImpl(this._self, this._then);

  final TmcOperationModel _self;
  final $Res Function(TmcOperationModel) _then;

/// Create a copy of TmcOperationModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? operationType = null,Object? operatedAt = null,Object? documentNumber = freezed,Object? basis = freezed,Object? comment = freezed,Object? fromLocationType = freezed,Object? fromWarehouseId = freezed,Object? fromObjectId = freezed,Object? fromEmployeeId = freezed,Object? fromLocationNote = freezed,Object? toLocationType = freezed,Object? toWarehouseId = freezed,Object? toObjectId = freezed,Object? toEmployeeId = freezed,Object? toLocationNote = freezed,Object? responsibleEmployeeId = freezed,Object? objectId = freezed,Object? reversesOperationId = freezed,Object? plannedReturnDate = freezed,Object? conditionId = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,Object? items = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,operationType: null == operationType ? _self.operationType : operationType // ignore: cast_nullable_to_non_nullable
as TmcOperationType,operatedAt: null == operatedAt ? _self.operatedAt : operatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,documentNumber: freezed == documentNumber ? _self.documentNumber : documentNumber // ignore: cast_nullable_to_non_nullable
as String?,basis: freezed == basis ? _self.basis : basis // ignore: cast_nullable_to_non_nullable
as String?,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,fromLocationType: freezed == fromLocationType ? _self.fromLocationType : fromLocationType // ignore: cast_nullable_to_non_nullable
as TmcLocationType?,fromWarehouseId: freezed == fromWarehouseId ? _self.fromWarehouseId : fromWarehouseId // ignore: cast_nullable_to_non_nullable
as String?,fromObjectId: freezed == fromObjectId ? _self.fromObjectId : fromObjectId // ignore: cast_nullable_to_non_nullable
as String?,fromEmployeeId: freezed == fromEmployeeId ? _self.fromEmployeeId : fromEmployeeId // ignore: cast_nullable_to_non_nullable
as String?,fromLocationNote: freezed == fromLocationNote ? _self.fromLocationNote : fromLocationNote // ignore: cast_nullable_to_non_nullable
as String?,toLocationType: freezed == toLocationType ? _self.toLocationType : toLocationType // ignore: cast_nullable_to_non_nullable
as TmcLocationType?,toWarehouseId: freezed == toWarehouseId ? _self.toWarehouseId : toWarehouseId // ignore: cast_nullable_to_non_nullable
as String?,toObjectId: freezed == toObjectId ? _self.toObjectId : toObjectId // ignore: cast_nullable_to_non_nullable
as String?,toEmployeeId: freezed == toEmployeeId ? _self.toEmployeeId : toEmployeeId // ignore: cast_nullable_to_non_nullable
as String?,toLocationNote: freezed == toLocationNote ? _self.toLocationNote : toLocationNote // ignore: cast_nullable_to_non_nullable
as String?,responsibleEmployeeId: freezed == responsibleEmployeeId ? _self.responsibleEmployeeId : responsibleEmployeeId // ignore: cast_nullable_to_non_nullable
as String?,objectId: freezed == objectId ? _self.objectId : objectId // ignore: cast_nullable_to_non_nullable
as String?,reversesOperationId: freezed == reversesOperationId ? _self.reversesOperationId : reversesOperationId // ignore: cast_nullable_to_non_nullable
as String?,plannedReturnDate: freezed == plannedReturnDate ? _self.plannedReturnDate : plannedReturnDate // ignore: cast_nullable_to_non_nullable
as DateTime?,conditionId: freezed == conditionId ? _self.conditionId : conditionId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<TmcOperationItemModel>,
  ));
}

}


/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _TmcOperationModel extends TmcOperationModel {
  const _TmcOperationModel({required this.id, required this.companyId, required this.operationType, required this.operatedAt, this.documentNumber, this.basis, this.comment, this.fromLocationType, this.fromWarehouseId, this.fromObjectId, this.fromEmployeeId, this.fromLocationNote, this.toLocationType, this.toWarehouseId, this.toObjectId, this.toEmployeeId, this.toLocationNote, this.responsibleEmployeeId, this.objectId, this.reversesOperationId, @JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) this.plannedReturnDate, this.conditionId, this.createdAt, this.updatedAt, this.createdBy, @JsonKey(includeToJson: false) final  List<TmcOperationItemModel> items = const []}): _items = items,super._();
  

@override final  String id;
@override final  String companyId;
@override final  TmcOperationType operationType;
@override final  DateTime operatedAt;
@override final  String? documentNumber;
@override final  String? basis;
@override final  String? comment;
@override final  TmcLocationType? fromLocationType;
@override final  String? fromWarehouseId;
@override final  String? fromObjectId;
@override final  String? fromEmployeeId;
@override final  String? fromLocationNote;
@override final  TmcLocationType? toLocationType;
@override final  String? toWarehouseId;
@override final  String? toObjectId;
@override final  String? toEmployeeId;
@override final  String? toLocationNote;
@override final  String? responsibleEmployeeId;
@override final  String? objectId;
@override final  String? reversesOperationId;
@override@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) final  DateTime? plannedReturnDate;
@override final  String? conditionId;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;
@override final  String? createdBy;
 final  List<TmcOperationItemModel> _items;
@override@JsonKey(includeToJson: false) List<TmcOperationItemModel> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of TmcOperationModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TmcOperationModelCopyWith<_TmcOperationModel> get copyWith => __$TmcOperationModelCopyWithImpl<_TmcOperationModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TmcOperationModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.operationType, operationType) || other.operationType == operationType)&&(identical(other.operatedAt, operatedAt) || other.operatedAt == operatedAt)&&(identical(other.documentNumber, documentNumber) || other.documentNumber == documentNumber)&&(identical(other.basis, basis) || other.basis == basis)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.fromLocationType, fromLocationType) || other.fromLocationType == fromLocationType)&&(identical(other.fromWarehouseId, fromWarehouseId) || other.fromWarehouseId == fromWarehouseId)&&(identical(other.fromObjectId, fromObjectId) || other.fromObjectId == fromObjectId)&&(identical(other.fromEmployeeId, fromEmployeeId) || other.fromEmployeeId == fromEmployeeId)&&(identical(other.fromLocationNote, fromLocationNote) || other.fromLocationNote == fromLocationNote)&&(identical(other.toLocationType, toLocationType) || other.toLocationType == toLocationType)&&(identical(other.toWarehouseId, toWarehouseId) || other.toWarehouseId == toWarehouseId)&&(identical(other.toObjectId, toObjectId) || other.toObjectId == toObjectId)&&(identical(other.toEmployeeId, toEmployeeId) || other.toEmployeeId == toEmployeeId)&&(identical(other.toLocationNote, toLocationNote) || other.toLocationNote == toLocationNote)&&(identical(other.responsibleEmployeeId, responsibleEmployeeId) || other.responsibleEmployeeId == responsibleEmployeeId)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.reversesOperationId, reversesOperationId) || other.reversesOperationId == reversesOperationId)&&(identical(other.plannedReturnDate, plannedReturnDate) || other.plannedReturnDate == plannedReturnDate)&&(identical(other.conditionId, conditionId) || other.conditionId == conditionId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&const DeepCollectionEquality().equals(other._items, _items));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,operationType,operatedAt,documentNumber,basis,comment,fromLocationType,fromWarehouseId,fromObjectId,fromEmployeeId,fromLocationNote,toLocationType,toWarehouseId,toObjectId,toEmployeeId,toLocationNote,responsibleEmployeeId,objectId,reversesOperationId,plannedReturnDate,conditionId,createdAt,updatedAt,createdBy,const DeepCollectionEquality().hash(_items)]);

@override
String toString() {
  return 'TmcOperationModel(id: $id, companyId: $companyId, operationType: $operationType, operatedAt: $operatedAt, documentNumber: $documentNumber, basis: $basis, comment: $comment, fromLocationType: $fromLocationType, fromWarehouseId: $fromWarehouseId, fromObjectId: $fromObjectId, fromEmployeeId: $fromEmployeeId, fromLocationNote: $fromLocationNote, toLocationType: $toLocationType, toWarehouseId: $toWarehouseId, toObjectId: $toObjectId, toEmployeeId: $toEmployeeId, toLocationNote: $toLocationNote, responsibleEmployeeId: $responsibleEmployeeId, objectId: $objectId, reversesOperationId: $reversesOperationId, plannedReturnDate: $plannedReturnDate, conditionId: $conditionId, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, items: $items)';
}


}

/// @nodoc
abstract mixin class _$TmcOperationModelCopyWith<$Res> implements $TmcOperationModelCopyWith<$Res> {
  factory _$TmcOperationModelCopyWith(_TmcOperationModel value, $Res Function(_TmcOperationModel) _then) = __$TmcOperationModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, TmcOperationType operationType, DateTime operatedAt, String? documentNumber, String? basis, String? comment, TmcLocationType? fromLocationType, String? fromWarehouseId, String? fromObjectId, String? fromEmployeeId, String? fromLocationNote, TmcLocationType? toLocationType, String? toWarehouseId, String? toObjectId, String? toEmployeeId, String? toLocationNote, String? responsibleEmployeeId, String? objectId, String? reversesOperationId,@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) DateTime? plannedReturnDate, String? conditionId, DateTime? createdAt, DateTime? updatedAt, String? createdBy,@JsonKey(includeToJson: false) List<TmcOperationItemModel> items
});




}
/// @nodoc
class __$TmcOperationModelCopyWithImpl<$Res>
    implements _$TmcOperationModelCopyWith<$Res> {
  __$TmcOperationModelCopyWithImpl(this._self, this._then);

  final _TmcOperationModel _self;
  final $Res Function(_TmcOperationModel) _then;

/// Create a copy of TmcOperationModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? operationType = null,Object? operatedAt = null,Object? documentNumber = freezed,Object? basis = freezed,Object? comment = freezed,Object? fromLocationType = freezed,Object? fromWarehouseId = freezed,Object? fromObjectId = freezed,Object? fromEmployeeId = freezed,Object? fromLocationNote = freezed,Object? toLocationType = freezed,Object? toWarehouseId = freezed,Object? toObjectId = freezed,Object? toEmployeeId = freezed,Object? toLocationNote = freezed,Object? responsibleEmployeeId = freezed,Object? objectId = freezed,Object? reversesOperationId = freezed,Object? plannedReturnDate = freezed,Object? conditionId = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,Object? items = null,}) {
  return _then(_TmcOperationModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,operationType: null == operationType ? _self.operationType : operationType // ignore: cast_nullable_to_non_nullable
as TmcOperationType,operatedAt: null == operatedAt ? _self.operatedAt : operatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,documentNumber: freezed == documentNumber ? _self.documentNumber : documentNumber // ignore: cast_nullable_to_non_nullable
as String?,basis: freezed == basis ? _self.basis : basis // ignore: cast_nullable_to_non_nullable
as String?,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,fromLocationType: freezed == fromLocationType ? _self.fromLocationType : fromLocationType // ignore: cast_nullable_to_non_nullable
as TmcLocationType?,fromWarehouseId: freezed == fromWarehouseId ? _self.fromWarehouseId : fromWarehouseId // ignore: cast_nullable_to_non_nullable
as String?,fromObjectId: freezed == fromObjectId ? _self.fromObjectId : fromObjectId // ignore: cast_nullable_to_non_nullable
as String?,fromEmployeeId: freezed == fromEmployeeId ? _self.fromEmployeeId : fromEmployeeId // ignore: cast_nullable_to_non_nullable
as String?,fromLocationNote: freezed == fromLocationNote ? _self.fromLocationNote : fromLocationNote // ignore: cast_nullable_to_non_nullable
as String?,toLocationType: freezed == toLocationType ? _self.toLocationType : toLocationType // ignore: cast_nullable_to_non_nullable
as TmcLocationType?,toWarehouseId: freezed == toWarehouseId ? _self.toWarehouseId : toWarehouseId // ignore: cast_nullable_to_non_nullable
as String?,toObjectId: freezed == toObjectId ? _self.toObjectId : toObjectId // ignore: cast_nullable_to_non_nullable
as String?,toEmployeeId: freezed == toEmployeeId ? _self.toEmployeeId : toEmployeeId // ignore: cast_nullable_to_non_nullable
as String?,toLocationNote: freezed == toLocationNote ? _self.toLocationNote : toLocationNote // ignore: cast_nullable_to_non_nullable
as String?,responsibleEmployeeId: freezed == responsibleEmployeeId ? _self.responsibleEmployeeId : responsibleEmployeeId // ignore: cast_nullable_to_non_nullable
as String?,objectId: freezed == objectId ? _self.objectId : objectId // ignore: cast_nullable_to_non_nullable
as String?,reversesOperationId: freezed == reversesOperationId ? _self.reversesOperationId : reversesOperationId // ignore: cast_nullable_to_non_nullable
as String?,plannedReturnDate: freezed == plannedReturnDate ? _self.plannedReturnDate : plannedReturnDate // ignore: cast_nullable_to_non_nullable
as DateTime?,conditionId: freezed == conditionId ? _self.conditionId : conditionId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<TmcOperationItemModel>,
  ));
}


}

// dart format on
