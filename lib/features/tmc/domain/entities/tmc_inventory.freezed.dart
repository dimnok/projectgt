// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tmc_inventory.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TmcInventoryItem {

/// Идентификатор записи.
 String get id;/// Компания-владелец.
 String get companyId;/// Инвентаризация.
 String get inventoryId;/// Позиция каталога.
 String get itemId;/// Единица.
 String? get unitId;/// Количество по учёту.
 double get systemQuantity;/// Фактическое количество.
 double? get actualQuantity;/// Излишек (вычисляемое поле БД).
 double? get surplus;/// Недостача (вычисляемое поле БД).
 double? get shortage;/// Состояние.
 String? get conditionId;/// Комментарий.
 String? get comment;/// Дата создания.
 DateTime? get createdAt;/// Дата обновления.
 DateTime? get updatedAt;/// Наименование позиции (join).
 String? get itemName;/// Инвентарный номер (join).
 String? get inventoryNumber;
/// Create a copy of TmcInventoryItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TmcInventoryItemCopyWith<TmcInventoryItem> get copyWith => _$TmcInventoryItemCopyWithImpl<TmcInventoryItem>(this as TmcInventoryItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TmcInventoryItem&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.inventoryId, inventoryId) || other.inventoryId == inventoryId)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.systemQuantity, systemQuantity) || other.systemQuantity == systemQuantity)&&(identical(other.actualQuantity, actualQuantity) || other.actualQuantity == actualQuantity)&&(identical(other.surplus, surplus) || other.surplus == surplus)&&(identical(other.shortage, shortage) || other.shortage == shortage)&&(identical(other.conditionId, conditionId) || other.conditionId == conditionId)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.itemName, itemName) || other.itemName == itemName)&&(identical(other.inventoryNumber, inventoryNumber) || other.inventoryNumber == inventoryNumber));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,inventoryId,itemId,unitId,systemQuantity,actualQuantity,surplus,shortage,conditionId,comment,createdAt,updatedAt,itemName,inventoryNumber);

@override
String toString() {
  return 'TmcInventoryItem(id: $id, companyId: $companyId, inventoryId: $inventoryId, itemId: $itemId, unitId: $unitId, systemQuantity: $systemQuantity, actualQuantity: $actualQuantity, surplus: $surplus, shortage: $shortage, conditionId: $conditionId, comment: $comment, createdAt: $createdAt, updatedAt: $updatedAt, itemName: $itemName, inventoryNumber: $inventoryNumber)';
}


}

/// @nodoc
abstract mixin class $TmcInventoryItemCopyWith<$Res>  {
  factory $TmcInventoryItemCopyWith(TmcInventoryItem value, $Res Function(TmcInventoryItem) _then) = _$TmcInventoryItemCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String inventoryId, String itemId, String? unitId, double systemQuantity, double? actualQuantity, double? surplus, double? shortage, String? conditionId, String? comment, DateTime? createdAt, DateTime? updatedAt, String? itemName, String? inventoryNumber
});




}
/// @nodoc
class _$TmcInventoryItemCopyWithImpl<$Res>
    implements $TmcInventoryItemCopyWith<$Res> {
  _$TmcInventoryItemCopyWithImpl(this._self, this._then);

  final TmcInventoryItem _self;
  final $Res Function(TmcInventoryItem) _then;

/// Create a copy of TmcInventoryItem
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


class _TmcInventoryItem implements TmcInventoryItem {
  const _TmcInventoryItem({required this.id, required this.companyId, required this.inventoryId, required this.itemId, this.unitId, this.systemQuantity = 0, this.actualQuantity, this.surplus, this.shortage, this.conditionId, this.comment, this.createdAt, this.updatedAt, this.itemName, this.inventoryNumber});
  

/// Идентификатор записи.
@override final  String id;
/// Компания-владелец.
@override final  String companyId;
/// Инвентаризация.
@override final  String inventoryId;
/// Позиция каталога.
@override final  String itemId;
/// Единица.
@override final  String? unitId;
/// Количество по учёту.
@override@JsonKey() final  double systemQuantity;
/// Фактическое количество.
@override final  double? actualQuantity;
/// Излишек (вычисляемое поле БД).
@override final  double? surplus;
/// Недостача (вычисляемое поле БД).
@override final  double? shortage;
/// Состояние.
@override final  String? conditionId;
/// Комментарий.
@override final  String? comment;
/// Дата создания.
@override final  DateTime? createdAt;
/// Дата обновления.
@override final  DateTime? updatedAt;
/// Наименование позиции (join).
@override final  String? itemName;
/// Инвентарный номер (join).
@override final  String? inventoryNumber;

/// Create a copy of TmcInventoryItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TmcInventoryItemCopyWith<_TmcInventoryItem> get copyWith => __$TmcInventoryItemCopyWithImpl<_TmcInventoryItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TmcInventoryItem&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.inventoryId, inventoryId) || other.inventoryId == inventoryId)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.systemQuantity, systemQuantity) || other.systemQuantity == systemQuantity)&&(identical(other.actualQuantity, actualQuantity) || other.actualQuantity == actualQuantity)&&(identical(other.surplus, surplus) || other.surplus == surplus)&&(identical(other.shortage, shortage) || other.shortage == shortage)&&(identical(other.conditionId, conditionId) || other.conditionId == conditionId)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.itemName, itemName) || other.itemName == itemName)&&(identical(other.inventoryNumber, inventoryNumber) || other.inventoryNumber == inventoryNumber));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,inventoryId,itemId,unitId,systemQuantity,actualQuantity,surplus,shortage,conditionId,comment,createdAt,updatedAt,itemName,inventoryNumber);

@override
String toString() {
  return 'TmcInventoryItem(id: $id, companyId: $companyId, inventoryId: $inventoryId, itemId: $itemId, unitId: $unitId, systemQuantity: $systemQuantity, actualQuantity: $actualQuantity, surplus: $surplus, shortage: $shortage, conditionId: $conditionId, comment: $comment, createdAt: $createdAt, updatedAt: $updatedAt, itemName: $itemName, inventoryNumber: $inventoryNumber)';
}


}

/// @nodoc
abstract mixin class _$TmcInventoryItemCopyWith<$Res> implements $TmcInventoryItemCopyWith<$Res> {
  factory _$TmcInventoryItemCopyWith(_TmcInventoryItem value, $Res Function(_TmcInventoryItem) _then) = __$TmcInventoryItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String inventoryId, String itemId, String? unitId, double systemQuantity, double? actualQuantity, double? surplus, double? shortage, String? conditionId, String? comment, DateTime? createdAt, DateTime? updatedAt, String? itemName, String? inventoryNumber
});




}
/// @nodoc
class __$TmcInventoryItemCopyWithImpl<$Res>
    implements _$TmcInventoryItemCopyWith<$Res> {
  __$TmcInventoryItemCopyWithImpl(this._self, this._then);

  final _TmcInventoryItem _self;
  final $Res Function(_TmcInventoryItem) _then;

/// Create a copy of TmcInventoryItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? inventoryId = null,Object? itemId = null,Object? unitId = freezed,Object? systemQuantity = null,Object? actualQuantity = freezed,Object? surplus = freezed,Object? shortage = freezed,Object? conditionId = freezed,Object? comment = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? itemName = freezed,Object? inventoryNumber = freezed,}) {
  return _then(_TmcInventoryItem(
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
mixin _$TmcInventory {

/// Идентификатор записи.
 String get id;/// Компания-владелец.
 String get companyId;/// Название.
 String get title;/// Область инвентаризации.
 TmcInventoryScopeType get scopeType;/// Склад (при scope = warehouse).
 String? get warehouseId;/// Объект (при scope = object).
 String? get objectId;/// Сотрудник (при scope = employee).
 String? get employeeId;/// Категория (при scope = category).
 String? get categoryId;/// Статус.
 TmcInventoryStatus get status;/// Дата начала.
 DateTime get startedAt;/// Дата завершения.
 DateTime? get completedAt;/// Комментарий.
 String? get comment;/// Дата создания.
 DateTime? get createdAt;/// Дата обновления.
 DateTime? get updatedAt;/// Автор создания.
 String? get createdBy;/// Строки инвентаризации.
 List<TmcInventoryItem> get items;
/// Create a copy of TmcInventory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TmcInventoryCopyWith<TmcInventory> get copyWith => _$TmcInventoryCopyWithImpl<TmcInventory>(this as TmcInventory, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TmcInventory&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.title, title) || other.title == title)&&(identical(other.scopeType, scopeType) || other.scopeType == scopeType)&&(identical(other.warehouseId, warehouseId) || other.warehouseId == warehouseId)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.status, status) || other.status == status)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&const DeepCollectionEquality().equals(other.items, items));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,title,scopeType,warehouseId,objectId,employeeId,categoryId,status,startedAt,completedAt,comment,createdAt,updatedAt,createdBy,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'TmcInventory(id: $id, companyId: $companyId, title: $title, scopeType: $scopeType, warehouseId: $warehouseId, objectId: $objectId, employeeId: $employeeId, categoryId: $categoryId, status: $status, startedAt: $startedAt, completedAt: $completedAt, comment: $comment, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, items: $items)';
}


}

/// @nodoc
abstract mixin class $TmcInventoryCopyWith<$Res>  {
  factory $TmcInventoryCopyWith(TmcInventory value, $Res Function(TmcInventory) _then) = _$TmcInventoryCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String title, TmcInventoryScopeType scopeType, String? warehouseId, String? objectId, String? employeeId, String? categoryId, TmcInventoryStatus status, DateTime startedAt, DateTime? completedAt, String? comment, DateTime? createdAt, DateTime? updatedAt, String? createdBy, List<TmcInventoryItem> items
});




}
/// @nodoc
class _$TmcInventoryCopyWithImpl<$Res>
    implements $TmcInventoryCopyWith<$Res> {
  _$TmcInventoryCopyWithImpl(this._self, this._then);

  final TmcInventory _self;
  final $Res Function(TmcInventory) _then;

/// Create a copy of TmcInventory
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
as List<TmcInventoryItem>,
  ));
}

}


/// @nodoc


class _TmcInventory implements TmcInventory {
  const _TmcInventory({required this.id, required this.companyId, required this.title, this.scopeType = TmcInventoryScopeType.company, this.warehouseId, this.objectId, this.employeeId, this.categoryId, this.status = TmcInventoryStatus.draft, required this.startedAt, this.completedAt, this.comment, this.createdAt, this.updatedAt, this.createdBy, final  List<TmcInventoryItem> items = const []}): _items = items;
  

/// Идентификатор записи.
@override final  String id;
/// Компания-владелец.
@override final  String companyId;
/// Название.
@override final  String title;
/// Область инвентаризации.
@override@JsonKey() final  TmcInventoryScopeType scopeType;
/// Склад (при scope = warehouse).
@override final  String? warehouseId;
/// Объект (при scope = object).
@override final  String? objectId;
/// Сотрудник (при scope = employee).
@override final  String? employeeId;
/// Категория (при scope = category).
@override final  String? categoryId;
/// Статус.
@override@JsonKey() final  TmcInventoryStatus status;
/// Дата начала.
@override final  DateTime startedAt;
/// Дата завершения.
@override final  DateTime? completedAt;
/// Комментарий.
@override final  String? comment;
/// Дата создания.
@override final  DateTime? createdAt;
/// Дата обновления.
@override final  DateTime? updatedAt;
/// Автор создания.
@override final  String? createdBy;
/// Строки инвентаризации.
 final  List<TmcInventoryItem> _items;
/// Строки инвентаризации.
@override@JsonKey() List<TmcInventoryItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of TmcInventory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TmcInventoryCopyWith<_TmcInventory> get copyWith => __$TmcInventoryCopyWithImpl<_TmcInventory>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TmcInventory&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.title, title) || other.title == title)&&(identical(other.scopeType, scopeType) || other.scopeType == scopeType)&&(identical(other.warehouseId, warehouseId) || other.warehouseId == warehouseId)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.status, status) || other.status == status)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&const DeepCollectionEquality().equals(other._items, _items));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,title,scopeType,warehouseId,objectId,employeeId,categoryId,status,startedAt,completedAt,comment,createdAt,updatedAt,createdBy,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'TmcInventory(id: $id, companyId: $companyId, title: $title, scopeType: $scopeType, warehouseId: $warehouseId, objectId: $objectId, employeeId: $employeeId, categoryId: $categoryId, status: $status, startedAt: $startedAt, completedAt: $completedAt, comment: $comment, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, items: $items)';
}


}

/// @nodoc
abstract mixin class _$TmcInventoryCopyWith<$Res> implements $TmcInventoryCopyWith<$Res> {
  factory _$TmcInventoryCopyWith(_TmcInventory value, $Res Function(_TmcInventory) _then) = __$TmcInventoryCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String title, TmcInventoryScopeType scopeType, String? warehouseId, String? objectId, String? employeeId, String? categoryId, TmcInventoryStatus status, DateTime startedAt, DateTime? completedAt, String? comment, DateTime? createdAt, DateTime? updatedAt, String? createdBy, List<TmcInventoryItem> items
});




}
/// @nodoc
class __$TmcInventoryCopyWithImpl<$Res>
    implements _$TmcInventoryCopyWith<$Res> {
  __$TmcInventoryCopyWithImpl(this._self, this._then);

  final _TmcInventory _self;
  final $Res Function(_TmcInventory) _then;

/// Create a copy of TmcInventory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? title = null,Object? scopeType = null,Object? warehouseId = freezed,Object? objectId = freezed,Object? employeeId = freezed,Object? categoryId = freezed,Object? status = null,Object? startedAt = null,Object? completedAt = freezed,Object? comment = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,Object? items = null,}) {
  return _then(_TmcInventory(
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
as List<TmcInventoryItem>,
  ));
}


}

// dart format on
