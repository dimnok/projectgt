// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tmc_inventory_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TmcInventoryItemModel {

 String get id; String get companyId; String get inventoryId; String get itemId; String? get unitId; double get systemQuantity; double? get actualQuantity; double? get surplus; double? get shortage; String? get conditionId; String? get comment; DateTime? get createdAt; DateTime? get updatedAt;@JsonKey(includeToJson: false) String? get itemName;@JsonKey(includeToJson: false) String? get inventoryNumber;
/// Create a copy of TmcInventoryItemModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TmcInventoryItemModelCopyWith<TmcInventoryItemModel> get copyWith => _$TmcInventoryItemModelCopyWithImpl<TmcInventoryItemModel>(this as TmcInventoryItemModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TmcInventoryItemModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.inventoryId, inventoryId) || other.inventoryId == inventoryId)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.systemQuantity, systemQuantity) || other.systemQuantity == systemQuantity)&&(identical(other.actualQuantity, actualQuantity) || other.actualQuantity == actualQuantity)&&(identical(other.surplus, surplus) || other.surplus == surplus)&&(identical(other.shortage, shortage) || other.shortage == shortage)&&(identical(other.conditionId, conditionId) || other.conditionId == conditionId)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.itemName, itemName) || other.itemName == itemName)&&(identical(other.inventoryNumber, inventoryNumber) || other.inventoryNumber == inventoryNumber));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,inventoryId,itemId,unitId,systemQuantity,actualQuantity,surplus,shortage,conditionId,comment,createdAt,updatedAt,itemName,inventoryNumber);

@override
String toString() {
  return 'TmcInventoryItemModel(id: $id, companyId: $companyId, inventoryId: $inventoryId, itemId: $itemId, unitId: $unitId, systemQuantity: $systemQuantity, actualQuantity: $actualQuantity, surplus: $surplus, shortage: $shortage, conditionId: $conditionId, comment: $comment, createdAt: $createdAt, updatedAt: $updatedAt, itemName: $itemName, inventoryNumber: $inventoryNumber)';
}


}

/// @nodoc
abstract mixin class $TmcInventoryItemModelCopyWith<$Res>  {
  factory $TmcInventoryItemModelCopyWith(TmcInventoryItemModel value, $Res Function(TmcInventoryItemModel) _then) = _$TmcInventoryItemModelCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String inventoryId, String itemId, String? unitId, double systemQuantity, double? actualQuantity, double? surplus, double? shortage, String? conditionId, String? comment, DateTime? createdAt, DateTime? updatedAt,@JsonKey(includeToJson: false) String? itemName,@JsonKey(includeToJson: false) String? inventoryNumber
});




}
/// @nodoc
class _$TmcInventoryItemModelCopyWithImpl<$Res>
    implements $TmcInventoryItemModelCopyWith<$Res> {
  _$TmcInventoryItemModelCopyWithImpl(this._self, this._then);

  final TmcInventoryItemModel _self;
  final $Res Function(TmcInventoryItemModel) _then;

/// Create a copy of TmcInventoryItemModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? inventoryId = null,Object? itemId = null,Object? unitId = freezed,Object? systemQuantity = null,Object? actualQuantity = freezed,Object? surplus = freezed,Object? shortage = freezed,Object? conditionId = freezed,Object? comment = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? itemName = freezed,Object? inventoryNumber = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,inventoryId: null == inventoryId ? _self.inventoryId : inventoryId // ignore: cast_nullable_to_non_nullable
as String,itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,unitId: freezed == unitId ? _self.unitId : unitId // ignore: cast_nullable_to_non_nullable
as String?,systemQuantity: null == systemQuantity ? _self.systemQuantity : systemQuantity // ignore: cast_nullable_to_non_nullable
as double,actualQuantity: freezed == actualQuantity ? _self.actualQuantity : actualQuantity // ignore: cast_nullable_to_non_nullable
as double?,surplus: freezed == surplus ? _self.surplus : surplus // ignore: cast_nullable_to_non_nullable
as double?,shortage: freezed == shortage ? _self.shortage : shortage // ignore: cast_nullable_to_non_nullable
as double?,conditionId: freezed == conditionId ? _self.conditionId : conditionId // ignore: cast_nullable_to_non_nullable
as String?,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,itemName: freezed == itemName ? _self.itemName : itemName // ignore: cast_nullable_to_non_nullable
as String?,inventoryNumber: freezed == inventoryNumber ? _self.inventoryNumber : inventoryNumber // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _TmcInventoryItemModel extends TmcInventoryItemModel {
  const _TmcInventoryItemModel({required this.id, required this.companyId, required this.inventoryId, required this.itemId, this.unitId, this.systemQuantity = 0, this.actualQuantity, this.surplus, this.shortage, this.conditionId, this.comment, this.createdAt, this.updatedAt, @JsonKey(includeToJson: false) this.itemName, @JsonKey(includeToJson: false) this.inventoryNumber}): super._();
  

@override final  String id;
@override final  String companyId;
@override final  String inventoryId;
@override final  String itemId;
@override final  String? unitId;
@override@JsonKey() final  double systemQuantity;
@override final  double? actualQuantity;
@override final  double? surplus;
@override final  double? shortage;
@override final  String? conditionId;
@override final  String? comment;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;
@override@JsonKey(includeToJson: false) final  String? itemName;
@override@JsonKey(includeToJson: false) final  String? inventoryNumber;

/// Create a copy of TmcInventoryItemModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TmcInventoryItemModelCopyWith<_TmcInventoryItemModel> get copyWith => __$TmcInventoryItemModelCopyWithImpl<_TmcInventoryItemModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TmcInventoryItemModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.inventoryId, inventoryId) || other.inventoryId == inventoryId)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.systemQuantity, systemQuantity) || other.systemQuantity == systemQuantity)&&(identical(other.actualQuantity, actualQuantity) || other.actualQuantity == actualQuantity)&&(identical(other.surplus, surplus) || other.surplus == surplus)&&(identical(other.shortage, shortage) || other.shortage == shortage)&&(identical(other.conditionId, conditionId) || other.conditionId == conditionId)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.itemName, itemName) || other.itemName == itemName)&&(identical(other.inventoryNumber, inventoryNumber) || other.inventoryNumber == inventoryNumber));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,inventoryId,itemId,unitId,systemQuantity,actualQuantity,surplus,shortage,conditionId,comment,createdAt,updatedAt,itemName,inventoryNumber);

@override
String toString() {
  return 'TmcInventoryItemModel(id: $id, companyId: $companyId, inventoryId: $inventoryId, itemId: $itemId, unitId: $unitId, systemQuantity: $systemQuantity, actualQuantity: $actualQuantity, surplus: $surplus, shortage: $shortage, conditionId: $conditionId, comment: $comment, createdAt: $createdAt, updatedAt: $updatedAt, itemName: $itemName, inventoryNumber: $inventoryNumber)';
}


}

/// @nodoc
abstract mixin class _$TmcInventoryItemModelCopyWith<$Res> implements $TmcInventoryItemModelCopyWith<$Res> {
  factory _$TmcInventoryItemModelCopyWith(_TmcInventoryItemModel value, $Res Function(_TmcInventoryItemModel) _then) = __$TmcInventoryItemModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String inventoryId, String itemId, String? unitId, double systemQuantity, double? actualQuantity, double? surplus, double? shortage, String? conditionId, String? comment, DateTime? createdAt, DateTime? updatedAt,@JsonKey(includeToJson: false) String? itemName,@JsonKey(includeToJson: false) String? inventoryNumber
});




}
/// @nodoc
class __$TmcInventoryItemModelCopyWithImpl<$Res>
    implements _$TmcInventoryItemModelCopyWith<$Res> {
  __$TmcInventoryItemModelCopyWithImpl(this._self, this._then);

  final _TmcInventoryItemModel _self;
  final $Res Function(_TmcInventoryItemModel) _then;

/// Create a copy of TmcInventoryItemModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? inventoryId = null,Object? itemId = null,Object? unitId = freezed,Object? systemQuantity = null,Object? actualQuantity = freezed,Object? surplus = freezed,Object? shortage = freezed,Object? conditionId = freezed,Object? comment = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? itemName = freezed,Object? inventoryNumber = freezed,}) {
  return _then(_TmcInventoryItemModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,inventoryId: null == inventoryId ? _self.inventoryId : inventoryId // ignore: cast_nullable_to_non_nullable
as String,itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,unitId: freezed == unitId ? _self.unitId : unitId // ignore: cast_nullable_to_non_nullable
as String?,systemQuantity: null == systemQuantity ? _self.systemQuantity : systemQuantity // ignore: cast_nullable_to_non_nullable
as double,actualQuantity: freezed == actualQuantity ? _self.actualQuantity : actualQuantity // ignore: cast_nullable_to_non_nullable
as double?,surplus: freezed == surplus ? _self.surplus : surplus // ignore: cast_nullable_to_non_nullable
as double?,shortage: freezed == shortage ? _self.shortage : shortage // ignore: cast_nullable_to_non_nullable
as double?,conditionId: freezed == conditionId ? _self.conditionId : conditionId // ignore: cast_nullable_to_non_nullable
as String?,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,itemName: freezed == itemName ? _self.itemName : itemName // ignore: cast_nullable_to_non_nullable
as String?,inventoryNumber: freezed == inventoryNumber ? _self.inventoryNumber : inventoryNumber // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$TmcInventoryModel {

 String get id; String get companyId; String get title; TmcInventoryScopeType get scopeType; String? get warehouseId; String? get objectId; String? get employeeId; String? get categoryId; TmcInventoryStatus get status; DateTime get startedAt; DateTime? get completedAt; String? get comment; DateTime? get createdAt; DateTime? get updatedAt; String? get createdBy;@JsonKey(includeToJson: false) List<TmcInventoryItemModel> get items;
/// Create a copy of TmcInventoryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TmcInventoryModelCopyWith<TmcInventoryModel> get copyWith => _$TmcInventoryModelCopyWithImpl<TmcInventoryModel>(this as TmcInventoryModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TmcInventoryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.title, title) || other.title == title)&&(identical(other.scopeType, scopeType) || other.scopeType == scopeType)&&(identical(other.warehouseId, warehouseId) || other.warehouseId == warehouseId)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.status, status) || other.status == status)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&const DeepCollectionEquality().equals(other.items, items));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,title,scopeType,warehouseId,objectId,employeeId,categoryId,status,startedAt,completedAt,comment,createdAt,updatedAt,createdBy,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'TmcInventoryModel(id: $id, companyId: $companyId, title: $title, scopeType: $scopeType, warehouseId: $warehouseId, objectId: $objectId, employeeId: $employeeId, categoryId: $categoryId, status: $status, startedAt: $startedAt, completedAt: $completedAt, comment: $comment, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, items: $items)';
}


}

/// @nodoc
abstract mixin class $TmcInventoryModelCopyWith<$Res>  {
  factory $TmcInventoryModelCopyWith(TmcInventoryModel value, $Res Function(TmcInventoryModel) _then) = _$TmcInventoryModelCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String title, TmcInventoryScopeType scopeType, String? warehouseId, String? objectId, String? employeeId, String? categoryId, TmcInventoryStatus status, DateTime startedAt, DateTime? completedAt, String? comment, DateTime? createdAt, DateTime? updatedAt, String? createdBy,@JsonKey(includeToJson: false) List<TmcInventoryItemModel> items
});




}
/// @nodoc
class _$TmcInventoryModelCopyWithImpl<$Res>
    implements $TmcInventoryModelCopyWith<$Res> {
  _$TmcInventoryModelCopyWithImpl(this._self, this._then);

  final TmcInventoryModel _self;
  final $Res Function(TmcInventoryModel) _then;

/// Create a copy of TmcInventoryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? title = null,Object? scopeType = null,Object? warehouseId = freezed,Object? objectId = freezed,Object? employeeId = freezed,Object? categoryId = freezed,Object? status = null,Object? startedAt = null,Object? completedAt = freezed,Object? comment = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,Object? items = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,scopeType: null == scopeType ? _self.scopeType : scopeType // ignore: cast_nullable_to_non_nullable
as TmcInventoryScopeType,warehouseId: freezed == warehouseId ? _self.warehouseId : warehouseId // ignore: cast_nullable_to_non_nullable
as String?,objectId: freezed == objectId ? _self.objectId : objectId // ignore: cast_nullable_to_non_nullable
as String?,employeeId: freezed == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TmcInventoryStatus,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<TmcInventoryItemModel>,
  ));
}

}


/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _TmcInventoryModel extends TmcInventoryModel {
  const _TmcInventoryModel({required this.id, required this.companyId, required this.title, this.scopeType = TmcInventoryScopeType.company, this.warehouseId, this.objectId, this.employeeId, this.categoryId, this.status = TmcInventoryStatus.draft, required this.startedAt, this.completedAt, this.comment, this.createdAt, this.updatedAt, this.createdBy, @JsonKey(includeToJson: false) final  List<TmcInventoryItemModel> items = const []}): _items = items,super._();
  

@override final  String id;
@override final  String companyId;
@override final  String title;
@override@JsonKey() final  TmcInventoryScopeType scopeType;
@override final  String? warehouseId;
@override final  String? objectId;
@override final  String? employeeId;
@override final  String? categoryId;
@override@JsonKey() final  TmcInventoryStatus status;
@override final  DateTime startedAt;
@override final  DateTime? completedAt;
@override final  String? comment;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;
@override final  String? createdBy;
 final  List<TmcInventoryItemModel> _items;
@override@JsonKey(includeToJson: false) List<TmcInventoryItemModel> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of TmcInventoryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TmcInventoryModelCopyWith<_TmcInventoryModel> get copyWith => __$TmcInventoryModelCopyWithImpl<_TmcInventoryModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TmcInventoryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.title, title) || other.title == title)&&(identical(other.scopeType, scopeType) || other.scopeType == scopeType)&&(identical(other.warehouseId, warehouseId) || other.warehouseId == warehouseId)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.status, status) || other.status == status)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&const DeepCollectionEquality().equals(other._items, _items));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,title,scopeType,warehouseId,objectId,employeeId,categoryId,status,startedAt,completedAt,comment,createdAt,updatedAt,createdBy,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'TmcInventoryModel(id: $id, companyId: $companyId, title: $title, scopeType: $scopeType, warehouseId: $warehouseId, objectId: $objectId, employeeId: $employeeId, categoryId: $categoryId, status: $status, startedAt: $startedAt, completedAt: $completedAt, comment: $comment, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, items: $items)';
}


}

/// @nodoc
abstract mixin class _$TmcInventoryModelCopyWith<$Res> implements $TmcInventoryModelCopyWith<$Res> {
  factory _$TmcInventoryModelCopyWith(_TmcInventoryModel value, $Res Function(_TmcInventoryModel) _then) = __$TmcInventoryModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String title, TmcInventoryScopeType scopeType, String? warehouseId, String? objectId, String? employeeId, String? categoryId, TmcInventoryStatus status, DateTime startedAt, DateTime? completedAt, String? comment, DateTime? createdAt, DateTime? updatedAt, String? createdBy,@JsonKey(includeToJson: false) List<TmcInventoryItemModel> items
});




}
/// @nodoc
class __$TmcInventoryModelCopyWithImpl<$Res>
    implements _$TmcInventoryModelCopyWith<$Res> {
  __$TmcInventoryModelCopyWithImpl(this._self, this._then);

  final _TmcInventoryModel _self;
  final $Res Function(_TmcInventoryModel) _then;

/// Create a copy of TmcInventoryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? title = null,Object? scopeType = null,Object? warehouseId = freezed,Object? objectId = freezed,Object? employeeId = freezed,Object? categoryId = freezed,Object? status = null,Object? startedAt = null,Object? completedAt = freezed,Object? comment = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,Object? items = null,}) {
  return _then(_TmcInventoryModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,scopeType: null == scopeType ? _self.scopeType : scopeType // ignore: cast_nullable_to_non_nullable
as TmcInventoryScopeType,warehouseId: freezed == warehouseId ? _self.warehouseId : warehouseId // ignore: cast_nullable_to_non_nullable
as String?,objectId: freezed == objectId ? _self.objectId : objectId // ignore: cast_nullable_to_non_nullable
as String?,employeeId: freezed == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TmcInventoryStatus,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<TmcInventoryItemModel>,
  ));
}


}

// dart format on
