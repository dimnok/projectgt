// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tmc_unit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TmcUnit {

/// Идентификатор записи.
 String get id;/// Компания-владелец.
 String get companyId;/// Позиция каталога.
 String get itemId;/// Инвентарный номер.
 String get inventoryNumber;/// Серийный номер.
 String? get serialNumber;/// Штрихкод.
 String? get barcode;/// Дата покупки.
 DateTime? get purchaseDate;/// Цена покупки.
 double get purchasePrice;/// Состояние.
 String? get conditionId;/// Статус единицы.
 TmcUnitStatus get status;/// Тип местоположения.
 TmcLocationType get locationType;/// Склад.
 String? get warehouseId;/// Объект.
 String? get objectId;/// Сотрудник (держатель).
 String? get employeeId;/// Примечание к местоположению.
 String? get locationNote;/// Объект использования.
 String? get usageObjectId;/// Ответственный сотрудник.
 String? get responsibleEmployeeId;/// Дата последней выдачи.
 DateTime? get lastIssueDate;/// Дата следующей проверки.
 DateTime? get nextInspectionDate;/// Гарантия до.
 DateTime? get warrantyUntil;/// Комментарий.
 String? get comment;/// URL фото.
 String? get photoUrl;/// В архиве.
 bool get isArchived;/// Дата архивации.
 DateTime? get archivedAt;/// Дата создания.
 DateTime? get createdAt;/// Дата обновления.
 DateTime? get updatedAt;/// Автор создания.
 String? get createdBy;/// Наименование позиции (join).
 String? get itemName;/// Название состояния (join).
 String? get conditionName;/// Название склада (join).
 String? get warehouseName;/// Название объекта (join).
 String? get objectName;/// ФИО сотрудника (join).
 String? get employeeName;
/// Create a copy of TmcUnit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TmcUnitCopyWith<TmcUnit> get copyWith => _$TmcUnitCopyWithImpl<TmcUnit>(this as TmcUnit, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TmcUnit&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.inventoryNumber, inventoryNumber) || other.inventoryNumber == inventoryNumber)&&(identical(other.serialNumber, serialNumber) || other.serialNumber == serialNumber)&&(identical(other.barcode, barcode) || other.barcode == barcode)&&(identical(other.purchaseDate, purchaseDate) || other.purchaseDate == purchaseDate)&&(identical(other.purchasePrice, purchasePrice) || other.purchasePrice == purchasePrice)&&(identical(other.conditionId, conditionId) || other.conditionId == conditionId)&&(identical(other.status, status) || other.status == status)&&(identical(other.locationType, locationType) || other.locationType == locationType)&&(identical(other.warehouseId, warehouseId) || other.warehouseId == warehouseId)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.locationNote, locationNote) || other.locationNote == locationNote)&&(identical(other.usageObjectId, usageObjectId) || other.usageObjectId == usageObjectId)&&(identical(other.responsibleEmployeeId, responsibleEmployeeId) || other.responsibleEmployeeId == responsibleEmployeeId)&&(identical(other.lastIssueDate, lastIssueDate) || other.lastIssueDate == lastIssueDate)&&(identical(other.nextInspectionDate, nextInspectionDate) || other.nextInspectionDate == nextInspectionDate)&&(identical(other.warrantyUntil, warrantyUntil) || other.warrantyUntil == warrantyUntil)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.itemName, itemName) || other.itemName == itemName)&&(identical(other.conditionName, conditionName) || other.conditionName == conditionName)&&(identical(other.warehouseName, warehouseName) || other.warehouseName == warehouseName)&&(identical(other.objectName, objectName) || other.objectName == objectName)&&(identical(other.employeeName, employeeName) || other.employeeName == employeeName));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,itemId,inventoryNumber,serialNumber,barcode,purchaseDate,purchasePrice,conditionId,status,locationType,warehouseId,objectId,employeeId,locationNote,usageObjectId,responsibleEmployeeId,lastIssueDate,nextInspectionDate,warrantyUntil,comment,photoUrl,isArchived,archivedAt,createdAt,updatedAt,createdBy,itemName,conditionName,warehouseName,objectName,employeeName]);

@override
String toString() {
  return 'TmcUnit(id: $id, companyId: $companyId, itemId: $itemId, inventoryNumber: $inventoryNumber, serialNumber: $serialNumber, barcode: $barcode, purchaseDate: $purchaseDate, purchasePrice: $purchasePrice, conditionId: $conditionId, status: $status, locationType: $locationType, warehouseId: $warehouseId, objectId: $objectId, employeeId: $employeeId, locationNote: $locationNote, usageObjectId: $usageObjectId, responsibleEmployeeId: $responsibleEmployeeId, lastIssueDate: $lastIssueDate, nextInspectionDate: $nextInspectionDate, warrantyUntil: $warrantyUntil, comment: $comment, photoUrl: $photoUrl, isArchived: $isArchived, archivedAt: $archivedAt, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, itemName: $itemName, conditionName: $conditionName, warehouseName: $warehouseName, objectName: $objectName, employeeName: $employeeName)';
}


}

/// @nodoc
abstract mixin class $TmcUnitCopyWith<$Res>  {
  factory $TmcUnitCopyWith(TmcUnit value, $Res Function(TmcUnit) _then) = _$TmcUnitCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String itemId, String inventoryNumber, String? serialNumber, String? barcode, DateTime? purchaseDate, double purchasePrice, String? conditionId, TmcUnitStatus status, TmcLocationType locationType, String? warehouseId, String? objectId, String? employeeId, String? locationNote, String? usageObjectId, String? responsibleEmployeeId, DateTime? lastIssueDate, DateTime? nextInspectionDate, DateTime? warrantyUntil, String? comment, String? photoUrl, bool isArchived, DateTime? archivedAt, DateTime? createdAt, DateTime? updatedAt, String? createdBy, String? itemName, String? conditionName, String? warehouseName, String? objectName, String? employeeName
});




}
/// @nodoc
class _$TmcUnitCopyWithImpl<$Res>
    implements $TmcUnitCopyWith<$Res> {
  _$TmcUnitCopyWithImpl(this._self, this._then);

  final TmcUnit _self;
  final $Res Function(TmcUnit) _then;

/// Create a copy of TmcUnit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? itemId = null,Object? inventoryNumber = null,Object? serialNumber = freezed,Object? barcode = freezed,Object? purchaseDate = freezed,Object? purchasePrice = null,Object? conditionId = freezed,Object? status = null,Object? locationType = null,Object? warehouseId = freezed,Object? objectId = freezed,Object? employeeId = freezed,Object? locationNote = freezed,Object? usageObjectId = freezed,Object? responsibleEmployeeId = freezed,Object? lastIssueDate = freezed,Object? nextInspectionDate = freezed,Object? warrantyUntil = freezed,Object? comment = freezed,Object? photoUrl = freezed,Object? isArchived = null,Object? archivedAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,Object? itemName = freezed,Object? conditionName = freezed,Object? warehouseName = freezed,Object? objectName = freezed,Object? employeeName = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,inventoryNumber: null == inventoryNumber ? _self.inventoryNumber : inventoryNumber // ignore: cast_nullable_to_non_nullable
as String,serialNumber: freezed == serialNumber ? _self.serialNumber : serialNumber // ignore: cast_nullable_to_non_nullable
as String?,barcode: freezed == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String?,purchaseDate: freezed == purchaseDate ? _self.purchaseDate : purchaseDate // ignore: cast_nullable_to_non_nullable
as DateTime?,purchasePrice: null == purchasePrice ? _self.purchasePrice : purchasePrice // ignore: cast_nullable_to_non_nullable
as double,conditionId: freezed == conditionId ? _self.conditionId : conditionId // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TmcUnitStatus,locationType: null == locationType ? _self.locationType : locationType // ignore: cast_nullable_to_non_nullable
as TmcLocationType,warehouseId: freezed == warehouseId ? _self.warehouseId : warehouseId // ignore: cast_nullable_to_non_nullable
as String?,objectId: freezed == objectId ? _self.objectId : objectId // ignore: cast_nullable_to_non_nullable
as String?,employeeId: freezed == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String?,locationNote: freezed == locationNote ? _self.locationNote : locationNote // ignore: cast_nullable_to_non_nullable
as String?,usageObjectId: freezed == usageObjectId ? _self.usageObjectId : usageObjectId // ignore: cast_nullable_to_non_nullable
as String?,responsibleEmployeeId: freezed == responsibleEmployeeId ? _self.responsibleEmployeeId : responsibleEmployeeId // ignore: cast_nullable_to_non_nullable
as String?,lastIssueDate: freezed == lastIssueDate ? _self.lastIssueDate : lastIssueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,nextInspectionDate: freezed == nextInspectionDate ? _self.nextInspectionDate : nextInspectionDate // ignore: cast_nullable_to_non_nullable
as DateTime?,warrantyUntil: freezed == warrantyUntil ? _self.warrantyUntil : warrantyUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,itemName: freezed == itemName ? _self.itemName : itemName // ignore: cast_nullable_to_non_nullable
as String?,conditionName: freezed == conditionName ? _self.conditionName : conditionName // ignore: cast_nullable_to_non_nullable
as String?,warehouseName: freezed == warehouseName ? _self.warehouseName : warehouseName // ignore: cast_nullable_to_non_nullable
as String?,objectName: freezed == objectName ? _self.objectName : objectName // ignore: cast_nullable_to_non_nullable
as String?,employeeName: freezed == employeeName ? _self.employeeName : employeeName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc


class _TmcUnit implements TmcUnit {
  const _TmcUnit({required this.id, required this.companyId, required this.itemId, required this.inventoryNumber, this.serialNumber, this.barcode, this.purchaseDate, this.purchasePrice = 0, this.conditionId, this.status = TmcUnitStatus.inStock, this.locationType = TmcLocationType.warehouse, this.warehouseId, this.objectId, this.employeeId, this.locationNote, this.usageObjectId, this.responsibleEmployeeId, this.lastIssueDate, this.nextInspectionDate, this.warrantyUntil, this.comment, this.photoUrl, this.isArchived = false, this.archivedAt, this.createdAt, this.updatedAt, this.createdBy, this.itemName, this.conditionName, this.warehouseName, this.objectName, this.employeeName});
  

/// Идентификатор записи.
@override final  String id;
/// Компания-владелец.
@override final  String companyId;
/// Позиция каталога.
@override final  String itemId;
/// Инвентарный номер.
@override final  String inventoryNumber;
/// Серийный номер.
@override final  String? serialNumber;
/// Штрихкод.
@override final  String? barcode;
/// Дата покупки.
@override final  DateTime? purchaseDate;
/// Цена покупки.
@override@JsonKey() final  double purchasePrice;
/// Состояние.
@override final  String? conditionId;
/// Статус единицы.
@override@JsonKey() final  TmcUnitStatus status;
/// Тип местоположения.
@override@JsonKey() final  TmcLocationType locationType;
/// Склад.
@override final  String? warehouseId;
/// Объект.
@override final  String? objectId;
/// Сотрудник (держатель).
@override final  String? employeeId;
/// Примечание к местоположению.
@override final  String? locationNote;
/// Объект использования.
@override final  String? usageObjectId;
/// Ответственный сотрудник.
@override final  String? responsibleEmployeeId;
/// Дата последней выдачи.
@override final  DateTime? lastIssueDate;
/// Дата следующей проверки.
@override final  DateTime? nextInspectionDate;
/// Гарантия до.
@override final  DateTime? warrantyUntil;
/// Комментарий.
@override final  String? comment;
/// URL фото.
@override final  String? photoUrl;
/// В архиве.
@override@JsonKey() final  bool isArchived;
/// Дата архивации.
@override final  DateTime? archivedAt;
/// Дата создания.
@override final  DateTime? createdAt;
/// Дата обновления.
@override final  DateTime? updatedAt;
/// Автор создания.
@override final  String? createdBy;
/// Наименование позиции (join).
@override final  String? itemName;
/// Название состояния (join).
@override final  String? conditionName;
/// Название склада (join).
@override final  String? warehouseName;
/// Название объекта (join).
@override final  String? objectName;
/// ФИО сотрудника (join).
@override final  String? employeeName;

/// Create a copy of TmcUnit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TmcUnitCopyWith<_TmcUnit> get copyWith => __$TmcUnitCopyWithImpl<_TmcUnit>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TmcUnit&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.inventoryNumber, inventoryNumber) || other.inventoryNumber == inventoryNumber)&&(identical(other.serialNumber, serialNumber) || other.serialNumber == serialNumber)&&(identical(other.barcode, barcode) || other.barcode == barcode)&&(identical(other.purchaseDate, purchaseDate) || other.purchaseDate == purchaseDate)&&(identical(other.purchasePrice, purchasePrice) || other.purchasePrice == purchasePrice)&&(identical(other.conditionId, conditionId) || other.conditionId == conditionId)&&(identical(other.status, status) || other.status == status)&&(identical(other.locationType, locationType) || other.locationType == locationType)&&(identical(other.warehouseId, warehouseId) || other.warehouseId == warehouseId)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.locationNote, locationNote) || other.locationNote == locationNote)&&(identical(other.usageObjectId, usageObjectId) || other.usageObjectId == usageObjectId)&&(identical(other.responsibleEmployeeId, responsibleEmployeeId) || other.responsibleEmployeeId == responsibleEmployeeId)&&(identical(other.lastIssueDate, lastIssueDate) || other.lastIssueDate == lastIssueDate)&&(identical(other.nextInspectionDate, nextInspectionDate) || other.nextInspectionDate == nextInspectionDate)&&(identical(other.warrantyUntil, warrantyUntil) || other.warrantyUntil == warrantyUntil)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.itemName, itemName) || other.itemName == itemName)&&(identical(other.conditionName, conditionName) || other.conditionName == conditionName)&&(identical(other.warehouseName, warehouseName) || other.warehouseName == warehouseName)&&(identical(other.objectName, objectName) || other.objectName == objectName)&&(identical(other.employeeName, employeeName) || other.employeeName == employeeName));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,itemId,inventoryNumber,serialNumber,barcode,purchaseDate,purchasePrice,conditionId,status,locationType,warehouseId,objectId,employeeId,locationNote,usageObjectId,responsibleEmployeeId,lastIssueDate,nextInspectionDate,warrantyUntil,comment,photoUrl,isArchived,archivedAt,createdAt,updatedAt,createdBy,itemName,conditionName,warehouseName,objectName,employeeName]);

@override
String toString() {
  return 'TmcUnit(id: $id, companyId: $companyId, itemId: $itemId, inventoryNumber: $inventoryNumber, serialNumber: $serialNumber, barcode: $barcode, purchaseDate: $purchaseDate, purchasePrice: $purchasePrice, conditionId: $conditionId, status: $status, locationType: $locationType, warehouseId: $warehouseId, objectId: $objectId, employeeId: $employeeId, locationNote: $locationNote, usageObjectId: $usageObjectId, responsibleEmployeeId: $responsibleEmployeeId, lastIssueDate: $lastIssueDate, nextInspectionDate: $nextInspectionDate, warrantyUntil: $warrantyUntil, comment: $comment, photoUrl: $photoUrl, isArchived: $isArchived, archivedAt: $archivedAt, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, itemName: $itemName, conditionName: $conditionName, warehouseName: $warehouseName, objectName: $objectName, employeeName: $employeeName)';
}


}

/// @nodoc
abstract mixin class _$TmcUnitCopyWith<$Res> implements $TmcUnitCopyWith<$Res> {
  factory _$TmcUnitCopyWith(_TmcUnit value, $Res Function(_TmcUnit) _then) = __$TmcUnitCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String itemId, String inventoryNumber, String? serialNumber, String? barcode, DateTime? purchaseDate, double purchasePrice, String? conditionId, TmcUnitStatus status, TmcLocationType locationType, String? warehouseId, String? objectId, String? employeeId, String? locationNote, String? usageObjectId, String? responsibleEmployeeId, DateTime? lastIssueDate, DateTime? nextInspectionDate, DateTime? warrantyUntil, String? comment, String? photoUrl, bool isArchived, DateTime? archivedAt, DateTime? createdAt, DateTime? updatedAt, String? createdBy, String? itemName, String? conditionName, String? warehouseName, String? objectName, String? employeeName
});




}
/// @nodoc
class __$TmcUnitCopyWithImpl<$Res>
    implements _$TmcUnitCopyWith<$Res> {
  __$TmcUnitCopyWithImpl(this._self, this._then);

  final _TmcUnit _self;
  final $Res Function(_TmcUnit) _then;

/// Create a copy of TmcUnit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? itemId = null,Object? inventoryNumber = null,Object? serialNumber = freezed,Object? barcode = freezed,Object? purchaseDate = freezed,Object? purchasePrice = null,Object? conditionId = freezed,Object? status = null,Object? locationType = null,Object? warehouseId = freezed,Object? objectId = freezed,Object? employeeId = freezed,Object? locationNote = freezed,Object? usageObjectId = freezed,Object? responsibleEmployeeId = freezed,Object? lastIssueDate = freezed,Object? nextInspectionDate = freezed,Object? warrantyUntil = freezed,Object? comment = freezed,Object? photoUrl = freezed,Object? isArchived = null,Object? archivedAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,Object? itemName = freezed,Object? conditionName = freezed,Object? warehouseName = freezed,Object? objectName = freezed,Object? employeeName = freezed,}) {
  return _then(_TmcUnit(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,inventoryNumber: null == inventoryNumber ? _self.inventoryNumber : inventoryNumber // ignore: cast_nullable_to_non_nullable
as String,serialNumber: freezed == serialNumber ? _self.serialNumber : serialNumber // ignore: cast_nullable_to_non_nullable
as String?,barcode: freezed == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String?,purchaseDate: freezed == purchaseDate ? _self.purchaseDate : purchaseDate // ignore: cast_nullable_to_non_nullable
as DateTime?,purchasePrice: null == purchasePrice ? _self.purchasePrice : purchasePrice // ignore: cast_nullable_to_non_nullable
as double,conditionId: freezed == conditionId ? _self.conditionId : conditionId // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TmcUnitStatus,locationType: null == locationType ? _self.locationType : locationType // ignore: cast_nullable_to_non_nullable
as TmcLocationType,warehouseId: freezed == warehouseId ? _self.warehouseId : warehouseId // ignore: cast_nullable_to_non_nullable
as String?,objectId: freezed == objectId ? _self.objectId : objectId // ignore: cast_nullable_to_non_nullable
as String?,employeeId: freezed == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String?,locationNote: freezed == locationNote ? _self.locationNote : locationNote // ignore: cast_nullable_to_non_nullable
as String?,usageObjectId: freezed == usageObjectId ? _self.usageObjectId : usageObjectId // ignore: cast_nullable_to_non_nullable
as String?,responsibleEmployeeId: freezed == responsibleEmployeeId ? _self.responsibleEmployeeId : responsibleEmployeeId // ignore: cast_nullable_to_non_nullable
as String?,lastIssueDate: freezed == lastIssueDate ? _self.lastIssueDate : lastIssueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,nextInspectionDate: freezed == nextInspectionDate ? _self.nextInspectionDate : nextInspectionDate // ignore: cast_nullable_to_non_nullable
as DateTime?,warrantyUntil: freezed == warrantyUntil ? _self.warrantyUntil : warrantyUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,itemName: freezed == itemName ? _self.itemName : itemName // ignore: cast_nullable_to_non_nullable
as String?,conditionName: freezed == conditionName ? _self.conditionName : conditionName // ignore: cast_nullable_to_non_nullable
as String?,warehouseName: freezed == warehouseName ? _self.warehouseName : warehouseName // ignore: cast_nullable_to_non_nullable
as String?,objectName: freezed == objectName ? _self.objectName : objectName // ignore: cast_nullable_to_non_nullable
as String?,employeeName: freezed == employeeName ? _self.employeeName : employeeName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
