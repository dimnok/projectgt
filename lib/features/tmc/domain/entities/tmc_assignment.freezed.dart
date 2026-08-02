// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tmc_assignment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TmcAssignment {

/// Идентификатор записи.
 String get id;/// Компания-владелец.
 String get companyId;/// Позиция каталога.
 String get itemId;/// Единица (индивидуальный учёт).
 String? get unitId;/// Сотрудник.
 String get employeeId;/// Объект.
 String? get objectId;/// Количество.
 double get quantity;/// Дата выдачи.
 DateTime get issuedAt;/// Плановая дата возврата.
 DateTime? get plannedReturnDate;/// Состояние при выдаче.
 String? get conditionId;/// Операция выдачи.
 String? get issueOperationId;/// Размер одежды.
 String? get clothingSize;/// Рост, см.
 double? get heightCm;/// Сезон.
 String? get season;/// Срок службы, дней.
 int? get serviceLifeDays;/// Дата следующей замены.
 DateTime? get nextReplacementDate;/// Комментарий.
 String? get comment;/// Дата возврата.
 DateTime? get returnedAt;/// Активна ли выдача.
 bool get isActive;/// Дата создания.
 DateTime? get createdAt;/// Дата обновления.
 DateTime? get updatedAt;/// Автор создания.
 String? get createdBy;/// Наименование позиции (join).
 String? get itemName;/// Инвентарный номер (join).
 String? get inventoryNumber;/// ФИО сотрудника (join).
 String? get employeeName;/// Название объекта (join).
 String? get objectName;
/// Create a copy of TmcAssignment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TmcAssignmentCopyWith<TmcAssignment> get copyWith => _$TmcAssignmentCopyWithImpl<TmcAssignment>(this as TmcAssignment, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TmcAssignment&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt)&&(identical(other.plannedReturnDate, plannedReturnDate) || other.plannedReturnDate == plannedReturnDate)&&(identical(other.conditionId, conditionId) || other.conditionId == conditionId)&&(identical(other.issueOperationId, issueOperationId) || other.issueOperationId == issueOperationId)&&(identical(other.clothingSize, clothingSize) || other.clothingSize == clothingSize)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.season, season) || other.season == season)&&(identical(other.serviceLifeDays, serviceLifeDays) || other.serviceLifeDays == serviceLifeDays)&&(identical(other.nextReplacementDate, nextReplacementDate) || other.nextReplacementDate == nextReplacementDate)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.returnedAt, returnedAt) || other.returnedAt == returnedAt)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.itemName, itemName) || other.itemName == itemName)&&(identical(other.inventoryNumber, inventoryNumber) || other.inventoryNumber == inventoryNumber)&&(identical(other.employeeName, employeeName) || other.employeeName == employeeName)&&(identical(other.objectName, objectName) || other.objectName == objectName));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,itemId,unitId,employeeId,objectId,quantity,issuedAt,plannedReturnDate,conditionId,issueOperationId,clothingSize,heightCm,season,serviceLifeDays,nextReplacementDate,comment,returnedAt,isActive,createdAt,updatedAt,createdBy,itemName,inventoryNumber,employeeName,objectName]);

@override
String toString() {
  return 'TmcAssignment(id: $id, companyId: $companyId, itemId: $itemId, unitId: $unitId, employeeId: $employeeId, objectId: $objectId, quantity: $quantity, issuedAt: $issuedAt, plannedReturnDate: $plannedReturnDate, conditionId: $conditionId, issueOperationId: $issueOperationId, clothingSize: $clothingSize, heightCm: $heightCm, season: $season, serviceLifeDays: $serviceLifeDays, nextReplacementDate: $nextReplacementDate, comment: $comment, returnedAt: $returnedAt, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, itemName: $itemName, inventoryNumber: $inventoryNumber, employeeName: $employeeName, objectName: $objectName)';
}


}

/// @nodoc
abstract mixin class $TmcAssignmentCopyWith<$Res>  {
  factory $TmcAssignmentCopyWith(TmcAssignment value, $Res Function(TmcAssignment) _then) = _$TmcAssignmentCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String itemId, String? unitId, String employeeId, String? objectId, double quantity, DateTime issuedAt, DateTime? plannedReturnDate, String? conditionId, String? issueOperationId, String? clothingSize, double? heightCm, String? season, int? serviceLifeDays, DateTime? nextReplacementDate, String? comment, DateTime? returnedAt, bool isActive, DateTime? createdAt, DateTime? updatedAt, String? createdBy, String? itemName, String? inventoryNumber, String? employeeName, String? objectName
});




}
/// @nodoc
class _$TmcAssignmentCopyWithImpl<$Res>
    implements $TmcAssignmentCopyWith<$Res> {
  _$TmcAssignmentCopyWithImpl(this._self, this._then);

  final TmcAssignment _self;
  final $Res Function(TmcAssignment) _then;

/// Create a copy of TmcAssignment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? itemId = null,Object? unitId = freezed,Object? employeeId = null,Object? objectId = freezed,Object? quantity = null,Object? issuedAt = null,Object? plannedReturnDate = freezed,Object? conditionId = freezed,Object? issueOperationId = freezed,Object? clothingSize = freezed,Object? heightCm = freezed,Object? season = freezed,Object? serviceLifeDays = freezed,Object? nextReplacementDate = freezed,Object? comment = freezed,Object? returnedAt = freezed,Object? isActive = null,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,Object? itemName = freezed,Object? inventoryNumber = freezed,Object? employeeName = freezed,Object? objectName = freezed,}) {
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
as String?,
  ));
}

}


/// @nodoc


class _TmcAssignment implements TmcAssignment {
  const _TmcAssignment({required this.id, required this.companyId, required this.itemId, this.unitId, required this.employeeId, this.objectId, this.quantity = 1, required this.issuedAt, this.plannedReturnDate, this.conditionId, this.issueOperationId, this.clothingSize, this.heightCm, this.season, this.serviceLifeDays, this.nextReplacementDate, this.comment, this.returnedAt, this.isActive = true, this.createdAt, this.updatedAt, this.createdBy, this.itemName, this.inventoryNumber, this.employeeName, this.objectName});
  

/// Идентификатор записи.
@override final  String id;
/// Компания-владелец.
@override final  String companyId;
/// Позиция каталога.
@override final  String itemId;
/// Единица (индивидуальный учёт).
@override final  String? unitId;
/// Сотрудник.
@override final  String employeeId;
/// Объект.
@override final  String? objectId;
/// Количество.
@override@JsonKey() final  double quantity;
/// Дата выдачи.
@override final  DateTime issuedAt;
/// Плановая дата возврата.
@override final  DateTime? plannedReturnDate;
/// Состояние при выдаче.
@override final  String? conditionId;
/// Операция выдачи.
@override final  String? issueOperationId;
/// Размер одежды.
@override final  String? clothingSize;
/// Рост, см.
@override final  double? heightCm;
/// Сезон.
@override final  String? season;
/// Срок службы, дней.
@override final  int? serviceLifeDays;
/// Дата следующей замены.
@override final  DateTime? nextReplacementDate;
/// Комментарий.
@override final  String? comment;
/// Дата возврата.
@override final  DateTime? returnedAt;
/// Активна ли выдача.
@override@JsonKey() final  bool isActive;
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
/// ФИО сотрудника (join).
@override final  String? employeeName;
/// Название объекта (join).
@override final  String? objectName;

/// Create a copy of TmcAssignment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TmcAssignmentCopyWith<_TmcAssignment> get copyWith => __$TmcAssignmentCopyWithImpl<_TmcAssignment>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TmcAssignment&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt)&&(identical(other.plannedReturnDate, plannedReturnDate) || other.plannedReturnDate == plannedReturnDate)&&(identical(other.conditionId, conditionId) || other.conditionId == conditionId)&&(identical(other.issueOperationId, issueOperationId) || other.issueOperationId == issueOperationId)&&(identical(other.clothingSize, clothingSize) || other.clothingSize == clothingSize)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.season, season) || other.season == season)&&(identical(other.serviceLifeDays, serviceLifeDays) || other.serviceLifeDays == serviceLifeDays)&&(identical(other.nextReplacementDate, nextReplacementDate) || other.nextReplacementDate == nextReplacementDate)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.returnedAt, returnedAt) || other.returnedAt == returnedAt)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.itemName, itemName) || other.itemName == itemName)&&(identical(other.inventoryNumber, inventoryNumber) || other.inventoryNumber == inventoryNumber)&&(identical(other.employeeName, employeeName) || other.employeeName == employeeName)&&(identical(other.objectName, objectName) || other.objectName == objectName));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,itemId,unitId,employeeId,objectId,quantity,issuedAt,plannedReturnDate,conditionId,issueOperationId,clothingSize,heightCm,season,serviceLifeDays,nextReplacementDate,comment,returnedAt,isActive,createdAt,updatedAt,createdBy,itemName,inventoryNumber,employeeName,objectName]);

@override
String toString() {
  return 'TmcAssignment(id: $id, companyId: $companyId, itemId: $itemId, unitId: $unitId, employeeId: $employeeId, objectId: $objectId, quantity: $quantity, issuedAt: $issuedAt, plannedReturnDate: $plannedReturnDate, conditionId: $conditionId, issueOperationId: $issueOperationId, clothingSize: $clothingSize, heightCm: $heightCm, season: $season, serviceLifeDays: $serviceLifeDays, nextReplacementDate: $nextReplacementDate, comment: $comment, returnedAt: $returnedAt, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, itemName: $itemName, inventoryNumber: $inventoryNumber, employeeName: $employeeName, objectName: $objectName)';
}


}

/// @nodoc
abstract mixin class _$TmcAssignmentCopyWith<$Res> implements $TmcAssignmentCopyWith<$Res> {
  factory _$TmcAssignmentCopyWith(_TmcAssignment value, $Res Function(_TmcAssignment) _then) = __$TmcAssignmentCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String itemId, String? unitId, String employeeId, String? objectId, double quantity, DateTime issuedAt, DateTime? plannedReturnDate, String? conditionId, String? issueOperationId, String? clothingSize, double? heightCm, String? season, int? serviceLifeDays, DateTime? nextReplacementDate, String? comment, DateTime? returnedAt, bool isActive, DateTime? createdAt, DateTime? updatedAt, String? createdBy, String? itemName, String? inventoryNumber, String? employeeName, String? objectName
});




}
/// @nodoc
class __$TmcAssignmentCopyWithImpl<$Res>
    implements _$TmcAssignmentCopyWith<$Res> {
  __$TmcAssignmentCopyWithImpl(this._self, this._then);

  final _TmcAssignment _self;
  final $Res Function(_TmcAssignment) _then;

/// Create a copy of TmcAssignment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? itemId = null,Object? unitId = freezed,Object? employeeId = null,Object? objectId = freezed,Object? quantity = null,Object? issuedAt = null,Object? plannedReturnDate = freezed,Object? conditionId = freezed,Object? issueOperationId = freezed,Object? clothingSize = freezed,Object? heightCm = freezed,Object? season = freezed,Object? serviceLifeDays = freezed,Object? nextReplacementDate = freezed,Object? comment = freezed,Object? returnedAt = freezed,Object? isActive = null,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,Object? itemName = freezed,Object? inventoryNumber = freezed,Object? employeeName = freezed,Object? objectName = freezed,}) {
  return _then(_TmcAssignment(
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
as String?,
  ));
}


}

// dart format on
