// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tmc_operation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TmcOperationItem {

/// Идентификатор записи.
 String get id;/// Компания-владелец.
 String get companyId;/// Операция.
 String get operationId;/// Позиция каталога.
 String get itemId;/// Единица (индивидуальный учёт).
 String? get unitId;/// Количество.
 double get quantity;/// Цена за единицу.
 double? get unitPrice;/// Состояние.
 String? get conditionId;/// Примечание о комплектности.
 String? get completenessNote;/// Комментарий.
 String? get comment;/// Размер одежды (спецодежда).
 String? get clothingSize;/// Рост, см (спецодежда).
 double? get heightCm;/// Сезон (спецодежда).
 String? get season;/// Срок службы, дней.
 int? get serviceLifeDays;/// Дата следующей замены.
 DateTime? get nextReplacementDate;/// Дата создания.
 DateTime? get createdAt;/// Наименование позиции (join).
 String? get itemName;/// Инвентарный номер (join).
 String? get inventoryNumber;
/// Create a copy of TmcOperationItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TmcOperationItemCopyWith<TmcOperationItem> get copyWith => _$TmcOperationItemCopyWithImpl<TmcOperationItem>(this as TmcOperationItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TmcOperationItem&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.operationId, operationId) || other.operationId == operationId)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.conditionId, conditionId) || other.conditionId == conditionId)&&(identical(other.completenessNote, completenessNote) || other.completenessNote == completenessNote)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.clothingSize, clothingSize) || other.clothingSize == clothingSize)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.season, season) || other.season == season)&&(identical(other.serviceLifeDays, serviceLifeDays) || other.serviceLifeDays == serviceLifeDays)&&(identical(other.nextReplacementDate, nextReplacementDate) || other.nextReplacementDate == nextReplacementDate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.itemName, itemName) || other.itemName == itemName)&&(identical(other.inventoryNumber, inventoryNumber) || other.inventoryNumber == inventoryNumber));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,operationId,itemId,unitId,quantity,unitPrice,conditionId,completenessNote,comment,clothingSize,heightCm,season,serviceLifeDays,nextReplacementDate,createdAt,itemName,inventoryNumber);

@override
String toString() {
  return 'TmcOperationItem(id: $id, companyId: $companyId, operationId: $operationId, itemId: $itemId, unitId: $unitId, quantity: $quantity, unitPrice: $unitPrice, conditionId: $conditionId, completenessNote: $completenessNote, comment: $comment, clothingSize: $clothingSize, heightCm: $heightCm, season: $season, serviceLifeDays: $serviceLifeDays, nextReplacementDate: $nextReplacementDate, createdAt: $createdAt, itemName: $itemName, inventoryNumber: $inventoryNumber)';
}


}

/// @nodoc
abstract mixin class $TmcOperationItemCopyWith<$Res>  {
  factory $TmcOperationItemCopyWith(TmcOperationItem value, $Res Function(TmcOperationItem) _then) = _$TmcOperationItemCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String operationId, String itemId, String? unitId, double quantity, double? unitPrice, String? conditionId, String? completenessNote, String? comment, String? clothingSize, double? heightCm, String? season, int? serviceLifeDays, DateTime? nextReplacementDate, DateTime? createdAt, String? itemName, String? inventoryNumber
});




}
/// @nodoc
class _$TmcOperationItemCopyWithImpl<$Res>
    implements $TmcOperationItemCopyWith<$Res> {
  _$TmcOperationItemCopyWithImpl(this._self, this._then);

  final TmcOperationItem _self;
  final $Res Function(TmcOperationItem) _then;

/// Create a copy of TmcOperationItem
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


class _TmcOperationItem implements TmcOperationItem {
  const _TmcOperationItem({required this.id, required this.companyId, required this.operationId, required this.itemId, this.unitId, this.quantity = 1, this.unitPrice, this.conditionId, this.completenessNote, this.comment, this.clothingSize, this.heightCm, this.season, this.serviceLifeDays, this.nextReplacementDate, this.createdAt, this.itemName, this.inventoryNumber});
  

/// Идентификатор записи.
@override final  String id;
/// Компания-владелец.
@override final  String companyId;
/// Операция.
@override final  String operationId;
/// Позиция каталога.
@override final  String itemId;
/// Единица (индивидуальный учёт).
@override final  String? unitId;
/// Количество.
@override@JsonKey() final  double quantity;
/// Цена за единицу.
@override final  double? unitPrice;
/// Состояние.
@override final  String? conditionId;
/// Примечание о комплектности.
@override final  String? completenessNote;
/// Комментарий.
@override final  String? comment;
/// Размер одежды (спецодежда).
@override final  String? clothingSize;
/// Рост, см (спецодежда).
@override final  double? heightCm;
/// Сезон (спецодежда).
@override final  String? season;
/// Срок службы, дней.
@override final  int? serviceLifeDays;
/// Дата следующей замены.
@override final  DateTime? nextReplacementDate;
/// Дата создания.
@override final  DateTime? createdAt;
/// Наименование позиции (join).
@override final  String? itemName;
/// Инвентарный номер (join).
@override final  String? inventoryNumber;

/// Create a copy of TmcOperationItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TmcOperationItemCopyWith<_TmcOperationItem> get copyWith => __$TmcOperationItemCopyWithImpl<_TmcOperationItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TmcOperationItem&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.operationId, operationId) || other.operationId == operationId)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.conditionId, conditionId) || other.conditionId == conditionId)&&(identical(other.completenessNote, completenessNote) || other.completenessNote == completenessNote)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.clothingSize, clothingSize) || other.clothingSize == clothingSize)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.season, season) || other.season == season)&&(identical(other.serviceLifeDays, serviceLifeDays) || other.serviceLifeDays == serviceLifeDays)&&(identical(other.nextReplacementDate, nextReplacementDate) || other.nextReplacementDate == nextReplacementDate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.itemName, itemName) || other.itemName == itemName)&&(identical(other.inventoryNumber, inventoryNumber) || other.inventoryNumber == inventoryNumber));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,operationId,itemId,unitId,quantity,unitPrice,conditionId,completenessNote,comment,clothingSize,heightCm,season,serviceLifeDays,nextReplacementDate,createdAt,itemName,inventoryNumber);

@override
String toString() {
  return 'TmcOperationItem(id: $id, companyId: $companyId, operationId: $operationId, itemId: $itemId, unitId: $unitId, quantity: $quantity, unitPrice: $unitPrice, conditionId: $conditionId, completenessNote: $completenessNote, comment: $comment, clothingSize: $clothingSize, heightCm: $heightCm, season: $season, serviceLifeDays: $serviceLifeDays, nextReplacementDate: $nextReplacementDate, createdAt: $createdAt, itemName: $itemName, inventoryNumber: $inventoryNumber)';
}


}

/// @nodoc
abstract mixin class _$TmcOperationItemCopyWith<$Res> implements $TmcOperationItemCopyWith<$Res> {
  factory _$TmcOperationItemCopyWith(_TmcOperationItem value, $Res Function(_TmcOperationItem) _then) = __$TmcOperationItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String operationId, String itemId, String? unitId, double quantity, double? unitPrice, String? conditionId, String? completenessNote, String? comment, String? clothingSize, double? heightCm, String? season, int? serviceLifeDays, DateTime? nextReplacementDate, DateTime? createdAt, String? itemName, String? inventoryNumber
});




}
/// @nodoc
class __$TmcOperationItemCopyWithImpl<$Res>
    implements _$TmcOperationItemCopyWith<$Res> {
  __$TmcOperationItemCopyWithImpl(this._self, this._then);

  final _TmcOperationItem _self;
  final $Res Function(_TmcOperationItem) _then;

/// Create a copy of TmcOperationItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? operationId = null,Object? itemId = null,Object? unitId = freezed,Object? quantity = null,Object? unitPrice = freezed,Object? conditionId = freezed,Object? completenessNote = freezed,Object? comment = freezed,Object? clothingSize = freezed,Object? heightCm = freezed,Object? season = freezed,Object? serviceLifeDays = freezed,Object? nextReplacementDate = freezed,Object? createdAt = freezed,Object? itemName = freezed,Object? inventoryNumber = freezed,}) {
  return _then(_TmcOperationItem(
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
mixin _$TmcOperation {

/// Идентификатор записи.
 String get id;/// Компания-владелец.
 String get companyId;/// Тип операции.
 TmcOperationType get operationType;/// Дата и время операции.
 DateTime get operatedAt;/// Номер документа.
 String? get documentNumber;/// Основание.
 String? get basis;/// Комментарий.
 String? get comment;/// Тип места «откуда».
 TmcLocationType? get fromLocationType;/// Склад «откуда».
 String? get fromWarehouseId;/// Объект «откуда».
 String? get fromObjectId;/// Сотрудник «откуда».
 String? get fromEmployeeId;/// Примечание к месту «откуда».
 String? get fromLocationNote;/// Тип места «куда».
 TmcLocationType? get toLocationType;/// Склад «куда».
 String? get toWarehouseId;/// Объект «куда».
 String? get toObjectId;/// Сотрудник «куда».
 String? get toEmployeeId;/// Примечание к месту «куда».
 String? get toLocationNote;/// Ответственный сотрудник.
 String? get responsibleEmployeeId;/// Связанный объект.
 String? get objectId;/// Сторнируемая операция.
 String? get reversesOperationId;/// Плановая дата возврата.
 DateTime? get plannedReturnDate;/// Состояние после операции.
 String? get conditionId;/// Дата создания.
 DateTime? get createdAt;/// Дата обновления.
 DateTime? get updatedAt;/// Автор создания.
 String? get createdBy;/// Строки операции.
 List<TmcOperationItem> get items;
/// Create a copy of TmcOperation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TmcOperationCopyWith<TmcOperation> get copyWith => _$TmcOperationCopyWithImpl<TmcOperation>(this as TmcOperation, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TmcOperation&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.operationType, operationType) || other.operationType == operationType)&&(identical(other.operatedAt, operatedAt) || other.operatedAt == operatedAt)&&(identical(other.documentNumber, documentNumber) || other.documentNumber == documentNumber)&&(identical(other.basis, basis) || other.basis == basis)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.fromLocationType, fromLocationType) || other.fromLocationType == fromLocationType)&&(identical(other.fromWarehouseId, fromWarehouseId) || other.fromWarehouseId == fromWarehouseId)&&(identical(other.fromObjectId, fromObjectId) || other.fromObjectId == fromObjectId)&&(identical(other.fromEmployeeId, fromEmployeeId) || other.fromEmployeeId == fromEmployeeId)&&(identical(other.fromLocationNote, fromLocationNote) || other.fromLocationNote == fromLocationNote)&&(identical(other.toLocationType, toLocationType) || other.toLocationType == toLocationType)&&(identical(other.toWarehouseId, toWarehouseId) || other.toWarehouseId == toWarehouseId)&&(identical(other.toObjectId, toObjectId) || other.toObjectId == toObjectId)&&(identical(other.toEmployeeId, toEmployeeId) || other.toEmployeeId == toEmployeeId)&&(identical(other.toLocationNote, toLocationNote) || other.toLocationNote == toLocationNote)&&(identical(other.responsibleEmployeeId, responsibleEmployeeId) || other.responsibleEmployeeId == responsibleEmployeeId)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.reversesOperationId, reversesOperationId) || other.reversesOperationId == reversesOperationId)&&(identical(other.plannedReturnDate, plannedReturnDate) || other.plannedReturnDate == plannedReturnDate)&&(identical(other.conditionId, conditionId) || other.conditionId == conditionId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&const DeepCollectionEquality().equals(other.items, items));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,operationType,operatedAt,documentNumber,basis,comment,fromLocationType,fromWarehouseId,fromObjectId,fromEmployeeId,fromLocationNote,toLocationType,toWarehouseId,toObjectId,toEmployeeId,toLocationNote,responsibleEmployeeId,objectId,reversesOperationId,plannedReturnDate,conditionId,createdAt,updatedAt,createdBy,const DeepCollectionEquality().hash(items)]);

@override
String toString() {
  return 'TmcOperation(id: $id, companyId: $companyId, operationType: $operationType, operatedAt: $operatedAt, documentNumber: $documentNumber, basis: $basis, comment: $comment, fromLocationType: $fromLocationType, fromWarehouseId: $fromWarehouseId, fromObjectId: $fromObjectId, fromEmployeeId: $fromEmployeeId, fromLocationNote: $fromLocationNote, toLocationType: $toLocationType, toWarehouseId: $toWarehouseId, toObjectId: $toObjectId, toEmployeeId: $toEmployeeId, toLocationNote: $toLocationNote, responsibleEmployeeId: $responsibleEmployeeId, objectId: $objectId, reversesOperationId: $reversesOperationId, plannedReturnDate: $plannedReturnDate, conditionId: $conditionId, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, items: $items)';
}


}

/// @nodoc
abstract mixin class $TmcOperationCopyWith<$Res>  {
  factory $TmcOperationCopyWith(TmcOperation value, $Res Function(TmcOperation) _then) = _$TmcOperationCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, TmcOperationType operationType, DateTime operatedAt, String? documentNumber, String? basis, String? comment, TmcLocationType? fromLocationType, String? fromWarehouseId, String? fromObjectId, String? fromEmployeeId, String? fromLocationNote, TmcLocationType? toLocationType, String? toWarehouseId, String? toObjectId, String? toEmployeeId, String? toLocationNote, String? responsibleEmployeeId, String? objectId, String? reversesOperationId, DateTime? plannedReturnDate, String? conditionId, DateTime? createdAt, DateTime? updatedAt, String? createdBy, List<TmcOperationItem> items
});




}
/// @nodoc
class _$TmcOperationCopyWithImpl<$Res>
    implements $TmcOperationCopyWith<$Res> {
  _$TmcOperationCopyWithImpl(this._self, this._then);

  final TmcOperation _self;
  final $Res Function(TmcOperation) _then;

/// Create a copy of TmcOperation
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
as List<TmcOperationItem>,
  ));
}

}


/// @nodoc


class _TmcOperation implements TmcOperation {
  const _TmcOperation({required this.id, required this.companyId, required this.operationType, required this.operatedAt, this.documentNumber, this.basis, this.comment, this.fromLocationType, this.fromWarehouseId, this.fromObjectId, this.fromEmployeeId, this.fromLocationNote, this.toLocationType, this.toWarehouseId, this.toObjectId, this.toEmployeeId, this.toLocationNote, this.responsibleEmployeeId, this.objectId, this.reversesOperationId, this.plannedReturnDate, this.conditionId, this.createdAt, this.updatedAt, this.createdBy, final  List<TmcOperationItem> items = const []}): _items = items;
  

/// Идентификатор записи.
@override final  String id;
/// Компания-владелец.
@override final  String companyId;
/// Тип операции.
@override final  TmcOperationType operationType;
/// Дата и время операции.
@override final  DateTime operatedAt;
/// Номер документа.
@override final  String? documentNumber;
/// Основание.
@override final  String? basis;
/// Комментарий.
@override final  String? comment;
/// Тип места «откуда».
@override final  TmcLocationType? fromLocationType;
/// Склад «откуда».
@override final  String? fromWarehouseId;
/// Объект «откуда».
@override final  String? fromObjectId;
/// Сотрудник «откуда».
@override final  String? fromEmployeeId;
/// Примечание к месту «откуда».
@override final  String? fromLocationNote;
/// Тип места «куда».
@override final  TmcLocationType? toLocationType;
/// Склад «куда».
@override final  String? toWarehouseId;
/// Объект «куда».
@override final  String? toObjectId;
/// Сотрудник «куда».
@override final  String? toEmployeeId;
/// Примечание к месту «куда».
@override final  String? toLocationNote;
/// Ответственный сотрудник.
@override final  String? responsibleEmployeeId;
/// Связанный объект.
@override final  String? objectId;
/// Сторнируемая операция.
@override final  String? reversesOperationId;
/// Плановая дата возврата.
@override final  DateTime? plannedReturnDate;
/// Состояние после операции.
@override final  String? conditionId;
/// Дата создания.
@override final  DateTime? createdAt;
/// Дата обновления.
@override final  DateTime? updatedAt;
/// Автор создания.
@override final  String? createdBy;
/// Строки операции.
 final  List<TmcOperationItem> _items;
/// Строки операции.
@override@JsonKey() List<TmcOperationItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of TmcOperation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TmcOperationCopyWith<_TmcOperation> get copyWith => __$TmcOperationCopyWithImpl<_TmcOperation>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TmcOperation&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.operationType, operationType) || other.operationType == operationType)&&(identical(other.operatedAt, operatedAt) || other.operatedAt == operatedAt)&&(identical(other.documentNumber, documentNumber) || other.documentNumber == documentNumber)&&(identical(other.basis, basis) || other.basis == basis)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.fromLocationType, fromLocationType) || other.fromLocationType == fromLocationType)&&(identical(other.fromWarehouseId, fromWarehouseId) || other.fromWarehouseId == fromWarehouseId)&&(identical(other.fromObjectId, fromObjectId) || other.fromObjectId == fromObjectId)&&(identical(other.fromEmployeeId, fromEmployeeId) || other.fromEmployeeId == fromEmployeeId)&&(identical(other.fromLocationNote, fromLocationNote) || other.fromLocationNote == fromLocationNote)&&(identical(other.toLocationType, toLocationType) || other.toLocationType == toLocationType)&&(identical(other.toWarehouseId, toWarehouseId) || other.toWarehouseId == toWarehouseId)&&(identical(other.toObjectId, toObjectId) || other.toObjectId == toObjectId)&&(identical(other.toEmployeeId, toEmployeeId) || other.toEmployeeId == toEmployeeId)&&(identical(other.toLocationNote, toLocationNote) || other.toLocationNote == toLocationNote)&&(identical(other.responsibleEmployeeId, responsibleEmployeeId) || other.responsibleEmployeeId == responsibleEmployeeId)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.reversesOperationId, reversesOperationId) || other.reversesOperationId == reversesOperationId)&&(identical(other.plannedReturnDate, plannedReturnDate) || other.plannedReturnDate == plannedReturnDate)&&(identical(other.conditionId, conditionId) || other.conditionId == conditionId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&const DeepCollectionEquality().equals(other._items, _items));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,operationType,operatedAt,documentNumber,basis,comment,fromLocationType,fromWarehouseId,fromObjectId,fromEmployeeId,fromLocationNote,toLocationType,toWarehouseId,toObjectId,toEmployeeId,toLocationNote,responsibleEmployeeId,objectId,reversesOperationId,plannedReturnDate,conditionId,createdAt,updatedAt,createdBy,const DeepCollectionEquality().hash(_items)]);

@override
String toString() {
  return 'TmcOperation(id: $id, companyId: $companyId, operationType: $operationType, operatedAt: $operatedAt, documentNumber: $documentNumber, basis: $basis, comment: $comment, fromLocationType: $fromLocationType, fromWarehouseId: $fromWarehouseId, fromObjectId: $fromObjectId, fromEmployeeId: $fromEmployeeId, fromLocationNote: $fromLocationNote, toLocationType: $toLocationType, toWarehouseId: $toWarehouseId, toObjectId: $toObjectId, toEmployeeId: $toEmployeeId, toLocationNote: $toLocationNote, responsibleEmployeeId: $responsibleEmployeeId, objectId: $objectId, reversesOperationId: $reversesOperationId, plannedReturnDate: $plannedReturnDate, conditionId: $conditionId, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, items: $items)';
}


}

/// @nodoc
abstract mixin class _$TmcOperationCopyWith<$Res> implements $TmcOperationCopyWith<$Res> {
  factory _$TmcOperationCopyWith(_TmcOperation value, $Res Function(_TmcOperation) _then) = __$TmcOperationCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, TmcOperationType operationType, DateTime operatedAt, String? documentNumber, String? basis, String? comment, TmcLocationType? fromLocationType, String? fromWarehouseId, String? fromObjectId, String? fromEmployeeId, String? fromLocationNote, TmcLocationType? toLocationType, String? toWarehouseId, String? toObjectId, String? toEmployeeId, String? toLocationNote, String? responsibleEmployeeId, String? objectId, String? reversesOperationId, DateTime? plannedReturnDate, String? conditionId, DateTime? createdAt, DateTime? updatedAt, String? createdBy, List<TmcOperationItem> items
});




}
/// @nodoc
class __$TmcOperationCopyWithImpl<$Res>
    implements _$TmcOperationCopyWith<$Res> {
  __$TmcOperationCopyWithImpl(this._self, this._then);

  final _TmcOperation _self;
  final $Res Function(_TmcOperation) _then;

/// Create a copy of TmcOperation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? operationType = null,Object? operatedAt = null,Object? documentNumber = freezed,Object? basis = freezed,Object? comment = freezed,Object? fromLocationType = freezed,Object? fromWarehouseId = freezed,Object? fromObjectId = freezed,Object? fromEmployeeId = freezed,Object? fromLocationNote = freezed,Object? toLocationType = freezed,Object? toWarehouseId = freezed,Object? toObjectId = freezed,Object? toEmployeeId = freezed,Object? toLocationNote = freezed,Object? responsibleEmployeeId = freezed,Object? objectId = freezed,Object? reversesOperationId = freezed,Object? plannedReturnDate = freezed,Object? conditionId = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,Object? items = null,}) {
  return _then(_TmcOperation(
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
as List<TmcOperationItem>,
  ));
}


}

// dart format on
