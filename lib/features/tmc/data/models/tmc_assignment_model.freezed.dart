// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tmc_assignment_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TmcAssignmentModel {

 String get id; String get companyId; String get itemId; String? get unitId; String get employeeId; String? get objectId; double get quantity; DateTime get issuedAt;@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) DateTime? get plannedReturnDate; String? get conditionId; String? get issueOperationId; String? get clothingSize; double? get heightCm; String? get season; int? get serviceLifeDays;@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) DateTime? get nextReplacementDate; String? get comment; DateTime? get returnedAt; bool get isActive; DateTime? get createdAt; DateTime? get updatedAt; String? get createdBy;@JsonKey(includeToJson: false) String? get itemName;@JsonKey(includeToJson: false) String? get inventoryNumber;@JsonKey(includeToJson: false) String? get employeeName;@JsonKey(includeToJson: false) String? get objectName;@JsonKey(includeToJson: false, fromJson: tmcParseNullableDouble) double? get unitPrice;
/// Create a copy of TmcAssignmentModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TmcAssignmentModelCopyWith<TmcAssignmentModel> get copyWith => _$TmcAssignmentModelCopyWithImpl<TmcAssignmentModel>(this as TmcAssignmentModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TmcAssignmentModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt)&&(identical(other.plannedReturnDate, plannedReturnDate) || other.plannedReturnDate == plannedReturnDate)&&(identical(other.conditionId, conditionId) || other.conditionId == conditionId)&&(identical(other.issueOperationId, issueOperationId) || other.issueOperationId == issueOperationId)&&(identical(other.clothingSize, clothingSize) || other.clothingSize == clothingSize)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.season, season) || other.season == season)&&(identical(other.serviceLifeDays, serviceLifeDays) || other.serviceLifeDays == serviceLifeDays)&&(identical(other.nextReplacementDate, nextReplacementDate) || other.nextReplacementDate == nextReplacementDate)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.returnedAt, returnedAt) || other.returnedAt == returnedAt)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.itemName, itemName) || other.itemName == itemName)&&(identical(other.inventoryNumber, inventoryNumber) || other.inventoryNumber == inventoryNumber)&&(identical(other.employeeName, employeeName) || other.employeeName == employeeName)&&(identical(other.objectName, objectName) || other.objectName == objectName)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,itemId,unitId,employeeId,objectId,quantity,issuedAt,plannedReturnDate,conditionId,issueOperationId,clothingSize,heightCm,season,serviceLifeDays,nextReplacementDate,comment,returnedAt,isActive,createdAt,updatedAt,createdBy,itemName,inventoryNumber,employeeName,objectName,unitPrice]);

@override
String toString() {
  return 'TmcAssignmentModel(id: $id, companyId: $companyId, itemId: $itemId, unitId: $unitId, employeeId: $employeeId, objectId: $objectId, quantity: $quantity, issuedAt: $issuedAt, plannedReturnDate: $plannedReturnDate, conditionId: $conditionId, issueOperationId: $issueOperationId, clothingSize: $clothingSize, heightCm: $heightCm, season: $season, serviceLifeDays: $serviceLifeDays, nextReplacementDate: $nextReplacementDate, comment: $comment, returnedAt: $returnedAt, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, itemName: $itemName, inventoryNumber: $inventoryNumber, employeeName: $employeeName, objectName: $objectName, unitPrice: $unitPrice)';
}


}

/// @nodoc
abstract mixin class $TmcAssignmentModelCopyWith<$Res>  {
  factory $TmcAssignmentModelCopyWith(TmcAssignmentModel value, $Res Function(TmcAssignmentModel) _then) = _$TmcAssignmentModelCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String itemId, String? unitId, String employeeId, String? objectId, double quantity, DateTime issuedAt,@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) DateTime? plannedReturnDate, String? conditionId, String? issueOperationId, String? clothingSize, double? heightCm, String? season, int? serviceLifeDays,@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) DateTime? nextReplacementDate, String? comment, DateTime? returnedAt, bool isActive, DateTime? createdAt, DateTime? updatedAt, String? createdBy,@JsonKey(includeToJson: false) String? itemName,@JsonKey(includeToJson: false) String? inventoryNumber,@JsonKey(includeToJson: false) String? employeeName,@JsonKey(includeToJson: false) String? objectName,@JsonKey(includeToJson: false, fromJson: tmcParseNullableDouble) double? unitPrice
});




}
/// @nodoc
class _$TmcAssignmentModelCopyWithImpl<$Res>
    implements $TmcAssignmentModelCopyWith<$Res> {
  _$TmcAssignmentModelCopyWithImpl(this._self, this._then);

  final TmcAssignmentModel _self;
  final $Res Function(TmcAssignmentModel) _then;

/// Create a copy of TmcAssignmentModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? itemId = null,Object? unitId = freezed,Object? employeeId = null,Object? objectId = freezed,Object? quantity = null,Object? issuedAt = null,Object? plannedReturnDate = freezed,Object? conditionId = freezed,Object? issueOperationId = freezed,Object? clothingSize = freezed,Object? heightCm = freezed,Object? season = freezed,Object? serviceLifeDays = freezed,Object? nextReplacementDate = freezed,Object? comment = freezed,Object? returnedAt = freezed,Object? isActive = null,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,Object? itemName = freezed,Object? inventoryNumber = freezed,Object? employeeName = freezed,Object? objectName = freezed,Object? unitPrice = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,unitId: freezed == unitId ? _self.unitId : unitId // ignore: cast_nullable_to_non_nullable
as String?,employeeId: null == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String,objectId: freezed == objectId ? _self.objectId : objectId // ignore: cast_nullable_to_non_nullable
as String?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double,issuedAt: null == issuedAt ? _self.issuedAt : issuedAt // ignore: cast_nullable_to_non_nullable
as DateTime,plannedReturnDate: freezed == plannedReturnDate ? _self.plannedReturnDate : plannedReturnDate // ignore: cast_nullable_to_non_nullable
as DateTime?,conditionId: freezed == conditionId ? _self.conditionId : conditionId // ignore: cast_nullable_to_non_nullable
as String?,issueOperationId: freezed == issueOperationId ? _self.issueOperationId : issueOperationId // ignore: cast_nullable_to_non_nullable
as String?,clothingSize: freezed == clothingSize ? _self.clothingSize : clothingSize // ignore: cast_nullable_to_non_nullable
as String?,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as double?,season: freezed == season ? _self.season : season // ignore: cast_nullable_to_non_nullable
as String?,serviceLifeDays: freezed == serviceLifeDays ? _self.serviceLifeDays : serviceLifeDays // ignore: cast_nullable_to_non_nullable
as int?,nextReplacementDate: freezed == nextReplacementDate ? _self.nextReplacementDate : nextReplacementDate // ignore: cast_nullable_to_non_nullable
as DateTime?,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,returnedAt: freezed == returnedAt ? _self.returnedAt : returnedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,itemName: freezed == itemName ? _self.itemName : itemName // ignore: cast_nullable_to_non_nullable
as String?,inventoryNumber: freezed == inventoryNumber ? _self.inventoryNumber : inventoryNumber // ignore: cast_nullable_to_non_nullable
as String?,employeeName: freezed == employeeName ? _self.employeeName : employeeName // ignore: cast_nullable_to_non_nullable
as String?,objectName: freezed == objectName ? _self.objectName : objectName // ignore: cast_nullable_to_non_nullable
as String?,unitPrice: freezed == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _TmcAssignmentModel extends TmcAssignmentModel {
  const _TmcAssignmentModel({required this.id, required this.companyId, required this.itemId, this.unitId, required this.employeeId, this.objectId, this.quantity = 1, required this.issuedAt, @JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) this.plannedReturnDate, this.conditionId, this.issueOperationId, this.clothingSize, this.heightCm, this.season, this.serviceLifeDays, @JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) this.nextReplacementDate, this.comment, this.returnedAt, this.isActive = true, this.createdAt, this.updatedAt, this.createdBy, @JsonKey(includeToJson: false) this.itemName, @JsonKey(includeToJson: false) this.inventoryNumber, @JsonKey(includeToJson: false) this.employeeName, @JsonKey(includeToJson: false) this.objectName, @JsonKey(includeToJson: false, fromJson: tmcParseNullableDouble) this.unitPrice}): super._();
  

@override final  String id;
@override final  String companyId;
@override final  String itemId;
@override final  String? unitId;
@override final  String employeeId;
@override final  String? objectId;
@override@JsonKey() final  double quantity;
@override final  DateTime issuedAt;
@override@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) final  DateTime? plannedReturnDate;
@override final  String? conditionId;
@override final  String? issueOperationId;
@override final  String? clothingSize;
@override final  double? heightCm;
@override final  String? season;
@override final  int? serviceLifeDays;
@override@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) final  DateTime? nextReplacementDate;
@override final  String? comment;
@override final  DateTime? returnedAt;
@override@JsonKey() final  bool isActive;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;
@override final  String? createdBy;
@override@JsonKey(includeToJson: false) final  String? itemName;
@override@JsonKey(includeToJson: false) final  String? inventoryNumber;
@override@JsonKey(includeToJson: false) final  String? employeeName;
@override@JsonKey(includeToJson: false) final  String? objectName;
@override@JsonKey(includeToJson: false, fromJson: tmcParseNullableDouble) final  double? unitPrice;

/// Create a copy of TmcAssignmentModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TmcAssignmentModelCopyWith<_TmcAssignmentModel> get copyWith => __$TmcAssignmentModelCopyWithImpl<_TmcAssignmentModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TmcAssignmentModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt)&&(identical(other.plannedReturnDate, plannedReturnDate) || other.plannedReturnDate == plannedReturnDate)&&(identical(other.conditionId, conditionId) || other.conditionId == conditionId)&&(identical(other.issueOperationId, issueOperationId) || other.issueOperationId == issueOperationId)&&(identical(other.clothingSize, clothingSize) || other.clothingSize == clothingSize)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.season, season) || other.season == season)&&(identical(other.serviceLifeDays, serviceLifeDays) || other.serviceLifeDays == serviceLifeDays)&&(identical(other.nextReplacementDate, nextReplacementDate) || other.nextReplacementDate == nextReplacementDate)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.returnedAt, returnedAt) || other.returnedAt == returnedAt)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.itemName, itemName) || other.itemName == itemName)&&(identical(other.inventoryNumber, inventoryNumber) || other.inventoryNumber == inventoryNumber)&&(identical(other.employeeName, employeeName) || other.employeeName == employeeName)&&(identical(other.objectName, objectName) || other.objectName == objectName)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,itemId,unitId,employeeId,objectId,quantity,issuedAt,plannedReturnDate,conditionId,issueOperationId,clothingSize,heightCm,season,serviceLifeDays,nextReplacementDate,comment,returnedAt,isActive,createdAt,updatedAt,createdBy,itemName,inventoryNumber,employeeName,objectName,unitPrice]);

@override
String toString() {
  return 'TmcAssignmentModel(id: $id, companyId: $companyId, itemId: $itemId, unitId: $unitId, employeeId: $employeeId, objectId: $objectId, quantity: $quantity, issuedAt: $issuedAt, plannedReturnDate: $plannedReturnDate, conditionId: $conditionId, issueOperationId: $issueOperationId, clothingSize: $clothingSize, heightCm: $heightCm, season: $season, serviceLifeDays: $serviceLifeDays, nextReplacementDate: $nextReplacementDate, comment: $comment, returnedAt: $returnedAt, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, itemName: $itemName, inventoryNumber: $inventoryNumber, employeeName: $employeeName, objectName: $objectName, unitPrice: $unitPrice)';
}


}

/// @nodoc
abstract mixin class _$TmcAssignmentModelCopyWith<$Res> implements $TmcAssignmentModelCopyWith<$Res> {
  factory _$TmcAssignmentModelCopyWith(_TmcAssignmentModel value, $Res Function(_TmcAssignmentModel) _then) = __$TmcAssignmentModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String itemId, String? unitId, String employeeId, String? objectId, double quantity, DateTime issuedAt,@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) DateTime? plannedReturnDate, String? conditionId, String? issueOperationId, String? clothingSize, double? heightCm, String? season, int? serviceLifeDays,@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) DateTime? nextReplacementDate, String? comment, DateTime? returnedAt, bool isActive, DateTime? createdAt, DateTime? updatedAt, String? createdBy,@JsonKey(includeToJson: false) String? itemName,@JsonKey(includeToJson: false) String? inventoryNumber,@JsonKey(includeToJson: false) String? employeeName,@JsonKey(includeToJson: false) String? objectName,@JsonKey(includeToJson: false, fromJson: tmcParseNullableDouble) double? unitPrice
});




}
/// @nodoc
class __$TmcAssignmentModelCopyWithImpl<$Res>
    implements _$TmcAssignmentModelCopyWith<$Res> {
  __$TmcAssignmentModelCopyWithImpl(this._self, this._then);

  final _TmcAssignmentModel _self;
  final $Res Function(_TmcAssignmentModel) _then;

/// Create a copy of TmcAssignmentModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? itemId = null,Object? unitId = freezed,Object? employeeId = null,Object? objectId = freezed,Object? quantity = null,Object? issuedAt = null,Object? plannedReturnDate = freezed,Object? conditionId = freezed,Object? issueOperationId = freezed,Object? clothingSize = freezed,Object? heightCm = freezed,Object? season = freezed,Object? serviceLifeDays = freezed,Object? nextReplacementDate = freezed,Object? comment = freezed,Object? returnedAt = freezed,Object? isActive = null,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,Object? itemName = freezed,Object? inventoryNumber = freezed,Object? employeeName = freezed,Object? objectName = freezed,Object? unitPrice = freezed,}) {
  return _then(_TmcAssignmentModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,unitId: freezed == unitId ? _self.unitId : unitId // ignore: cast_nullable_to_non_nullable
as String?,employeeId: null == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String,objectId: freezed == objectId ? _self.objectId : objectId // ignore: cast_nullable_to_non_nullable
as String?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double,issuedAt: null == issuedAt ? _self.issuedAt : issuedAt // ignore: cast_nullable_to_non_nullable
as DateTime,plannedReturnDate: freezed == plannedReturnDate ? _self.plannedReturnDate : plannedReturnDate // ignore: cast_nullable_to_non_nullable
as DateTime?,conditionId: freezed == conditionId ? _self.conditionId : conditionId // ignore: cast_nullable_to_non_nullable
as String?,issueOperationId: freezed == issueOperationId ? _self.issueOperationId : issueOperationId // ignore: cast_nullable_to_non_nullable
as String?,clothingSize: freezed == clothingSize ? _self.clothingSize : clothingSize // ignore: cast_nullable_to_non_nullable
as String?,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as double?,season: freezed == season ? _self.season : season // ignore: cast_nullable_to_non_nullable
as String?,serviceLifeDays: freezed == serviceLifeDays ? _self.serviceLifeDays : serviceLifeDays // ignore: cast_nullable_to_non_nullable
as int?,nextReplacementDate: freezed == nextReplacementDate ? _self.nextReplacementDate : nextReplacementDate // ignore: cast_nullable_to_non_nullable
as DateTime?,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,returnedAt: freezed == returnedAt ? _self.returnedAt : returnedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,itemName: freezed == itemName ? _self.itemName : itemName // ignore: cast_nullable_to_non_nullable
as String?,inventoryNumber: freezed == inventoryNumber ? _self.inventoryNumber : inventoryNumber // ignore: cast_nullable_to_non_nullable
as String?,employeeName: freezed == employeeName ? _self.employeeName : employeeName // ignore: cast_nullable_to_non_nullable
as String?,objectName: freezed == objectName ? _self.objectName : objectName // ignore: cast_nullable_to_non_nullable
as String?,unitPrice: freezed == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
