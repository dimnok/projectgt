// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tmc_unit_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TmcUnitModel {

 String get id; String get companyId; String get itemId; String get inventoryNumber; String? get serialNumber; String? get barcode;@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) DateTime? get purchaseDate; double get purchasePrice; String? get conditionId; TmcUnitStatus get status; TmcLocationType get locationType; String? get warehouseId; String? get objectId; String? get employeeId; String? get locationNote; String? get usageObjectId; String? get responsibleEmployeeId;@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) DateTime? get lastIssueDate;@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) DateTime? get nextInspectionDate;@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) DateTime? get warrantyUntil; String? get comment; String? get photoUrl; bool get isArchived; DateTime? get archivedAt; DateTime? get createdAt; DateTime? get updatedAt; String? get createdBy;@JsonKey(includeToJson: false) String? get itemName;@JsonKey(includeToJson: false) String? get conditionName;@JsonKey(includeToJson: false) String? get warehouseName;@JsonKey(includeToJson: false) String? get objectName;@JsonKey(includeToJson: false) String? get employeeName;
/// Create a copy of TmcUnitModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TmcUnitModelCopyWith<TmcUnitModel> get copyWith => _$TmcUnitModelCopyWithImpl<TmcUnitModel>(this as TmcUnitModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TmcUnitModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.inventoryNumber, inventoryNumber) || other.inventoryNumber == inventoryNumber)&&(identical(other.serialNumber, serialNumber) || other.serialNumber == serialNumber)&&(identical(other.barcode, barcode) || other.barcode == barcode)&&(identical(other.purchaseDate, purchaseDate) || other.purchaseDate == purchaseDate)&&(identical(other.purchasePrice, purchasePrice) || other.purchasePrice == purchasePrice)&&(identical(other.conditionId, conditionId) || other.conditionId == conditionId)&&(identical(other.status, status) || other.status == status)&&(identical(other.locationType, locationType) || other.locationType == locationType)&&(identical(other.warehouseId, warehouseId) || other.warehouseId == warehouseId)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.locationNote, locationNote) || other.locationNote == locationNote)&&(identical(other.usageObjectId, usageObjectId) || other.usageObjectId == usageObjectId)&&(identical(other.responsibleEmployeeId, responsibleEmployeeId) || other.responsibleEmployeeId == responsibleEmployeeId)&&(identical(other.lastIssueDate, lastIssueDate) || other.lastIssueDate == lastIssueDate)&&(identical(other.nextInspectionDate, nextInspectionDate) || other.nextInspectionDate == nextInspectionDate)&&(identical(other.warrantyUntil, warrantyUntil) || other.warrantyUntil == warrantyUntil)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.itemName, itemName) || other.itemName == itemName)&&(identical(other.conditionName, conditionName) || other.conditionName == conditionName)&&(identical(other.warehouseName, warehouseName) || other.warehouseName == warehouseName)&&(identical(other.objectName, objectName) || other.objectName == objectName)&&(identical(other.employeeName, employeeName) || other.employeeName == employeeName));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,itemId,inventoryNumber,serialNumber,barcode,purchaseDate,purchasePrice,conditionId,status,locationType,warehouseId,objectId,employeeId,locationNote,usageObjectId,responsibleEmployeeId,lastIssueDate,nextInspectionDate,warrantyUntil,comment,photoUrl,isArchived,archivedAt,createdAt,updatedAt,createdBy,itemName,conditionName,warehouseName,objectName,employeeName]);

@override
String toString() {
  return 'TmcUnitModel(id: $id, companyId: $companyId, itemId: $itemId, inventoryNumber: $inventoryNumber, serialNumber: $serialNumber, barcode: $barcode, purchaseDate: $purchaseDate, purchasePrice: $purchasePrice, conditionId: $conditionId, status: $status, locationType: $locationType, warehouseId: $warehouseId, objectId: $objectId, employeeId: $employeeId, locationNote: $locationNote, usageObjectId: $usageObjectId, responsibleEmployeeId: $responsibleEmployeeId, lastIssueDate: $lastIssueDate, nextInspectionDate: $nextInspectionDate, warrantyUntil: $warrantyUntil, comment: $comment, photoUrl: $photoUrl, isArchived: $isArchived, archivedAt: $archivedAt, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, itemName: $itemName, conditionName: $conditionName, warehouseName: $warehouseName, objectName: $objectName, employeeName: $employeeName)';
}


}

/// @nodoc
abstract mixin class $TmcUnitModelCopyWith<$Res>  {
  factory $TmcUnitModelCopyWith(TmcUnitModel value, $Res Function(TmcUnitModel) _then) = _$TmcUnitModelCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String itemId, String inventoryNumber, String? serialNumber, String? barcode,@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) DateTime? purchaseDate, double purchasePrice, String? conditionId, TmcUnitStatus status, TmcLocationType locationType, String? warehouseId, String? objectId, String? employeeId, String? locationNote, String? usageObjectId, String? responsibleEmployeeId,@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) DateTime? lastIssueDate,@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) DateTime? nextInspectionDate,@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) DateTime? warrantyUntil, String? comment, String? photoUrl, bool isArchived, DateTime? archivedAt, DateTime? createdAt, DateTime? updatedAt, String? createdBy,@JsonKey(includeToJson: false) String? itemName,@JsonKey(includeToJson: false) String? conditionName,@JsonKey(includeToJson: false) String? warehouseName,@JsonKey(includeToJson: false) String? objectName,@JsonKey(includeToJson: false) String? employeeName
});




}
/// @nodoc
class _$TmcUnitModelCopyWithImpl<$Res>
    implements $TmcUnitModelCopyWith<$Res> {
  _$TmcUnitModelCopyWithImpl(this._self, this._then);

  final TmcUnitModel _self;
  final $Res Function(TmcUnitModel) _then;

/// Create a copy of TmcUnitModel
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

@JsonSerializable(fieldRename: FieldRename.snake)
class _TmcUnitModel extends TmcUnitModel {
  const _TmcUnitModel({required this.id, required this.companyId, required this.itemId, required this.inventoryNumber, this.serialNumber, this.barcode, @JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) this.purchaseDate, this.purchasePrice = 0, this.conditionId, this.status = TmcUnitStatus.inStock, this.locationType = TmcLocationType.warehouse, this.warehouseId, this.objectId, this.employeeId, this.locationNote, this.usageObjectId, this.responsibleEmployeeId, @JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) this.lastIssueDate, @JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) this.nextInspectionDate, @JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) this.warrantyUntil, this.comment, this.photoUrl, this.isArchived = false, this.archivedAt, this.createdAt, this.updatedAt, this.createdBy, @JsonKey(includeToJson: false) this.itemName, @JsonKey(includeToJson: false) this.conditionName, @JsonKey(includeToJson: false) this.warehouseName, @JsonKey(includeToJson: false) this.objectName, @JsonKey(includeToJson: false) this.employeeName}): super._();
  

@override final  String id;
@override final  String companyId;
@override final  String itemId;
@override final  String inventoryNumber;
@override final  String? serialNumber;
@override final  String? barcode;
@override@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) final  DateTime? purchaseDate;
@override@JsonKey() final  double purchasePrice;
@override final  String? conditionId;
@override@JsonKey() final  TmcUnitStatus status;
@override@JsonKey() final  TmcLocationType locationType;
@override final  String? warehouseId;
@override final  String? objectId;
@override final  String? employeeId;
@override final  String? locationNote;
@override final  String? usageObjectId;
@override final  String? responsibleEmployeeId;
@override@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) final  DateTime? lastIssueDate;
@override@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) final  DateTime? nextInspectionDate;
@override@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) final  DateTime? warrantyUntil;
@override final  String? comment;
@override final  String? photoUrl;
@override@JsonKey() final  bool isArchived;
@override final  DateTime? archivedAt;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;
@override final  String? createdBy;
@override@JsonKey(includeToJson: false) final  String? itemName;
@override@JsonKey(includeToJson: false) final  String? conditionName;
@override@JsonKey(includeToJson: false) final  String? warehouseName;
@override@JsonKey(includeToJson: false) final  String? objectName;
@override@JsonKey(includeToJson: false) final  String? employeeName;

/// Create a copy of TmcUnitModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TmcUnitModelCopyWith<_TmcUnitModel> get copyWith => __$TmcUnitModelCopyWithImpl<_TmcUnitModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TmcUnitModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.inventoryNumber, inventoryNumber) || other.inventoryNumber == inventoryNumber)&&(identical(other.serialNumber, serialNumber) || other.serialNumber == serialNumber)&&(identical(other.barcode, barcode) || other.barcode == barcode)&&(identical(other.purchaseDate, purchaseDate) || other.purchaseDate == purchaseDate)&&(identical(other.purchasePrice, purchasePrice) || other.purchasePrice == purchasePrice)&&(identical(other.conditionId, conditionId) || other.conditionId == conditionId)&&(identical(other.status, status) || other.status == status)&&(identical(other.locationType, locationType) || other.locationType == locationType)&&(identical(other.warehouseId, warehouseId) || other.warehouseId == warehouseId)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.locationNote, locationNote) || other.locationNote == locationNote)&&(identical(other.usageObjectId, usageObjectId) || other.usageObjectId == usageObjectId)&&(identical(other.responsibleEmployeeId, responsibleEmployeeId) || other.responsibleEmployeeId == responsibleEmployeeId)&&(identical(other.lastIssueDate, lastIssueDate) || other.lastIssueDate == lastIssueDate)&&(identical(other.nextInspectionDate, nextInspectionDate) || other.nextInspectionDate == nextInspectionDate)&&(identical(other.warrantyUntil, warrantyUntil) || other.warrantyUntil == warrantyUntil)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.itemName, itemName) || other.itemName == itemName)&&(identical(other.conditionName, conditionName) || other.conditionName == conditionName)&&(identical(other.warehouseName, warehouseName) || other.warehouseName == warehouseName)&&(identical(other.objectName, objectName) || other.objectName == objectName)&&(identical(other.employeeName, employeeName) || other.employeeName == employeeName));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,itemId,inventoryNumber,serialNumber,barcode,purchaseDate,purchasePrice,conditionId,status,locationType,warehouseId,objectId,employeeId,locationNote,usageObjectId,responsibleEmployeeId,lastIssueDate,nextInspectionDate,warrantyUntil,comment,photoUrl,isArchived,archivedAt,createdAt,updatedAt,createdBy,itemName,conditionName,warehouseName,objectName,employeeName]);

@override
String toString() {
  return 'TmcUnitModel(id: $id, companyId: $companyId, itemId: $itemId, inventoryNumber: $inventoryNumber, serialNumber: $serialNumber, barcode: $barcode, purchaseDate: $purchaseDate, purchasePrice: $purchasePrice, conditionId: $conditionId, status: $status, locationType: $locationType, warehouseId: $warehouseId, objectId: $objectId, employeeId: $employeeId, locationNote: $locationNote, usageObjectId: $usageObjectId, responsibleEmployeeId: $responsibleEmployeeId, lastIssueDate: $lastIssueDate, nextInspectionDate: $nextInspectionDate, warrantyUntil: $warrantyUntil, comment: $comment, photoUrl: $photoUrl, isArchived: $isArchived, archivedAt: $archivedAt, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, itemName: $itemName, conditionName: $conditionName, warehouseName: $warehouseName, objectName: $objectName, employeeName: $employeeName)';
}


}

/// @nodoc
abstract mixin class _$TmcUnitModelCopyWith<$Res> implements $TmcUnitModelCopyWith<$Res> {
  factory _$TmcUnitModelCopyWith(_TmcUnitModel value, $Res Function(_TmcUnitModel) _then) = __$TmcUnitModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String itemId, String inventoryNumber, String? serialNumber, String? barcode,@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) DateTime? purchaseDate, double purchasePrice, String? conditionId, TmcUnitStatus status, TmcLocationType locationType, String? warehouseId, String? objectId, String? employeeId, String? locationNote, String? usageObjectId, String? responsibleEmployeeId,@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) DateTime? lastIssueDate,@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) DateTime? nextInspectionDate,@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) DateTime? warrantyUntil, String? comment, String? photoUrl, bool isArchived, DateTime? archivedAt, DateTime? createdAt, DateTime? updatedAt, String? createdBy,@JsonKey(includeToJson: false) String? itemName,@JsonKey(includeToJson: false) String? conditionName,@JsonKey(includeToJson: false) String? warehouseName,@JsonKey(includeToJson: false) String? objectName,@JsonKey(includeToJson: false) String? employeeName
});




}
/// @nodoc
class __$TmcUnitModelCopyWithImpl<$Res>
    implements _$TmcUnitModelCopyWith<$Res> {
  __$TmcUnitModelCopyWithImpl(this._self, this._then);

  final _TmcUnitModel _self;
  final $Res Function(_TmcUnitModel) _then;

/// Create a copy of TmcUnitModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? itemId = null,Object? inventoryNumber = null,Object? serialNumber = freezed,Object? barcode = freezed,Object? purchaseDate = freezed,Object? purchasePrice = null,Object? conditionId = freezed,Object? status = null,Object? locationType = null,Object? warehouseId = freezed,Object? objectId = freezed,Object? employeeId = freezed,Object? locationNote = freezed,Object? usageObjectId = freezed,Object? responsibleEmployeeId = freezed,Object? lastIssueDate = freezed,Object? nextInspectionDate = freezed,Object? warrantyUntil = freezed,Object? comment = freezed,Object? photoUrl = freezed,Object? isArchived = null,Object? archivedAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,Object? itemName = freezed,Object? conditionName = freezed,Object? warehouseName = freezed,Object? objectName = freezed,Object? employeeName = freezed,}) {
  return _then(_TmcUnitModel(
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
