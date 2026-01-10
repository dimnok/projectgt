// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'inventory_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InventoryItem {

/// Уникальный идентификатор ТМЦ.
 String get id;/// Наименование ТМЦ.
 String get name;/// ID категории.
 String get categoryId;/// Название категории (для отображения).
 String? get categoryName;/// Серийный номер.
 String? get serialNumber;/// Единица измерения.
 String get unit;/// Количество единиц ТМЦ.
 double get quantity;/// URL фотографии.
 String? get photoUrl;/// Статус ТМЦ.
 InventoryItemStatus get status;/// Состояние при приходе.
 InventoryItemCondition get condition;/// Тип местоположения.
 InventoryLocationType get locationType;/// ID местоположения (объект или сотрудник).
 String? get locationId;/// Название местоположения (для отображения).
 String? get locationName;/// ID ответственного лица.
 String? get responsibleId;/// Имя ответственного (для отображения).
 String? get responsibleName;/// ID накладной прихода.
 String? get receiptId;/// ID позиции накладной.
 String? get receiptItemId;/// Цена за единицу.
 double? get price;/// Дата приобретения.
 DateTime? get purchaseDate;/// Дата окончания гарантии.
 DateTime? get warrantyExpiresAt;/// Срок службы в месяцах.
 int? get serviceLifeMonths;/// Дата выдачи.
 DateTime? get issuedAt;/// Примечания.
 String? get notes;/// Дата создания.
 DateTime? get createdAt;/// Дата обновления.
 DateTime? get updatedAt;/// Кто создал.
 String? get createdBy;/// Кто обновил.
 String? get updatedBy;
/// Create a copy of InventoryItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InventoryItemCopyWith<InventoryItem> get copyWith => _$InventoryItemCopyWithImpl<InventoryItem>(this as InventoryItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InventoryItem&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.serialNumber, serialNumber) || other.serialNumber == serialNumber)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.status, status) || other.status == status)&&(identical(other.condition, condition) || other.condition == condition)&&(identical(other.locationType, locationType) || other.locationType == locationType)&&(identical(other.locationId, locationId) || other.locationId == locationId)&&(identical(other.locationName, locationName) || other.locationName == locationName)&&(identical(other.responsibleId, responsibleId) || other.responsibleId == responsibleId)&&(identical(other.responsibleName, responsibleName) || other.responsibleName == responsibleName)&&(identical(other.receiptId, receiptId) || other.receiptId == receiptId)&&(identical(other.receiptItemId, receiptItemId) || other.receiptItemId == receiptItemId)&&(identical(other.price, price) || other.price == price)&&(identical(other.purchaseDate, purchaseDate) || other.purchaseDate == purchaseDate)&&(identical(other.warrantyExpiresAt, warrantyExpiresAt) || other.warrantyExpiresAt == warrantyExpiresAt)&&(identical(other.serviceLifeMonths, serviceLifeMonths) || other.serviceLifeMonths == serviceLifeMonths)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,name,categoryId,categoryName,serialNumber,unit,quantity,photoUrl,status,condition,locationType,locationId,locationName,responsibleId,responsibleName,receiptId,receiptItemId,price,purchaseDate,warrantyExpiresAt,serviceLifeMonths,issuedAt,notes,createdAt,updatedAt,createdBy,updatedBy]);

@override
String toString() {
  return 'InventoryItem(id: $id, name: $name, categoryId: $categoryId, categoryName: $categoryName, serialNumber: $serialNumber, unit: $unit, quantity: $quantity, photoUrl: $photoUrl, status: $status, condition: $condition, locationType: $locationType, locationId: $locationId, locationName: $locationName, responsibleId: $responsibleId, responsibleName: $responsibleName, receiptId: $receiptId, receiptItemId: $receiptItemId, price: $price, purchaseDate: $purchaseDate, warrantyExpiresAt: $warrantyExpiresAt, serviceLifeMonths: $serviceLifeMonths, issuedAt: $issuedAt, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, updatedBy: $updatedBy)';
}


}

/// @nodoc
abstract mixin class $InventoryItemCopyWith<$Res>  {
  factory $InventoryItemCopyWith(InventoryItem value, $Res Function(InventoryItem) _then) = _$InventoryItemCopyWithImpl;
@useResult
$Res call({
 String id, String name, String categoryId, String? categoryName, String? serialNumber, String unit, double quantity, String? photoUrl, InventoryItemStatus status, InventoryItemCondition condition, InventoryLocationType locationType, String? locationId, String? locationName, String? responsibleId, String? responsibleName, String? receiptId, String? receiptItemId, double? price, DateTime? purchaseDate, DateTime? warrantyExpiresAt, int? serviceLifeMonths, DateTime? issuedAt, String? notes, DateTime? createdAt, DateTime? updatedAt, String? createdBy, String? updatedBy
});




}
/// @nodoc
class _$InventoryItemCopyWithImpl<$Res>
    implements $InventoryItemCopyWith<$Res> {
  _$InventoryItemCopyWithImpl(this._self, this._then);

  final InventoryItem _self;
  final $Res Function(InventoryItem) _then;

/// Create a copy of InventoryItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? categoryId = null,Object? categoryName = freezed,Object? serialNumber = freezed,Object? unit = null,Object? quantity = null,Object? photoUrl = freezed,Object? status = null,Object? condition = null,Object? locationType = null,Object? locationId = freezed,Object? locationName = freezed,Object? responsibleId = freezed,Object? responsibleName = freezed,Object? receiptId = freezed,Object? receiptItemId = freezed,Object? price = freezed,Object? purchaseDate = freezed,Object? warrantyExpiresAt = freezed,Object? serviceLifeMonths = freezed,Object? issuedAt = freezed,Object? notes = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,Object? updatedBy = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,serialNumber: freezed == serialNumber ? _self.serialNumber : serialNumber // ignore: cast_nullable_to_non_nullable
as String?,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InventoryItemStatus,condition: null == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as InventoryItemCondition,locationType: null == locationType ? _self.locationType : locationType // ignore: cast_nullable_to_non_nullable
as InventoryLocationType,locationId: freezed == locationId ? _self.locationId : locationId // ignore: cast_nullable_to_non_nullable
as String?,locationName: freezed == locationName ? _self.locationName : locationName // ignore: cast_nullable_to_non_nullable
as String?,responsibleId: freezed == responsibleId ? _self.responsibleId : responsibleId // ignore: cast_nullable_to_non_nullable
as String?,responsibleName: freezed == responsibleName ? _self.responsibleName : responsibleName // ignore: cast_nullable_to_non_nullable
as String?,receiptId: freezed == receiptId ? _self.receiptId : receiptId // ignore: cast_nullable_to_non_nullable
as String?,receiptItemId: freezed == receiptItemId ? _self.receiptItemId : receiptItemId // ignore: cast_nullable_to_non_nullable
as String?,price: freezed == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double?,purchaseDate: freezed == purchaseDate ? _self.purchaseDate : purchaseDate // ignore: cast_nullable_to_non_nullable
as DateTime?,warrantyExpiresAt: freezed == warrantyExpiresAt ? _self.warrantyExpiresAt : warrantyExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,serviceLifeMonths: freezed == serviceLifeMonths ? _self.serviceLifeMonths : serviceLifeMonths // ignore: cast_nullable_to_non_nullable
as int?,issuedAt: freezed == issuedAt ? _self.issuedAt : issuedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,updatedBy: freezed == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc


class _InventoryItem implements InventoryItem {
  const _InventoryItem({required this.id, required this.name, required this.categoryId, this.categoryName, this.serialNumber, required this.unit, this.quantity = 1.0, this.photoUrl, this.status = InventoryItemStatus.new_, this.condition = InventoryItemCondition.new_, this.locationType = InventoryLocationType.warehouse, this.locationId, this.locationName, this.responsibleId, this.responsibleName, this.receiptId, this.receiptItemId, this.price, this.purchaseDate, this.warrantyExpiresAt, this.serviceLifeMonths, this.issuedAt, this.notes, this.createdAt, this.updatedAt, this.createdBy, this.updatedBy});
  

/// Уникальный идентификатор ТМЦ.
@override final  String id;
/// Наименование ТМЦ.
@override final  String name;
/// ID категории.
@override final  String categoryId;
/// Название категории (для отображения).
@override final  String? categoryName;
/// Серийный номер.
@override final  String? serialNumber;
/// Единица измерения.
@override final  String unit;
/// Количество единиц ТМЦ.
@override@JsonKey() final  double quantity;
/// URL фотографии.
@override final  String? photoUrl;
/// Статус ТМЦ.
@override@JsonKey() final  InventoryItemStatus status;
/// Состояние при приходе.
@override@JsonKey() final  InventoryItemCondition condition;
/// Тип местоположения.
@override@JsonKey() final  InventoryLocationType locationType;
/// ID местоположения (объект или сотрудник).
@override final  String? locationId;
/// Название местоположения (для отображения).
@override final  String? locationName;
/// ID ответственного лица.
@override final  String? responsibleId;
/// Имя ответственного (для отображения).
@override final  String? responsibleName;
/// ID накладной прихода.
@override final  String? receiptId;
/// ID позиции накладной.
@override final  String? receiptItemId;
/// Цена за единицу.
@override final  double? price;
/// Дата приобретения.
@override final  DateTime? purchaseDate;
/// Дата окончания гарантии.
@override final  DateTime? warrantyExpiresAt;
/// Срок службы в месяцах.
@override final  int? serviceLifeMonths;
/// Дата выдачи.
@override final  DateTime? issuedAt;
/// Примечания.
@override final  String? notes;
/// Дата создания.
@override final  DateTime? createdAt;
/// Дата обновления.
@override final  DateTime? updatedAt;
/// Кто создал.
@override final  String? createdBy;
/// Кто обновил.
@override final  String? updatedBy;

/// Create a copy of InventoryItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InventoryItemCopyWith<_InventoryItem> get copyWith => __$InventoryItemCopyWithImpl<_InventoryItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InventoryItem&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.serialNumber, serialNumber) || other.serialNumber == serialNumber)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.status, status) || other.status == status)&&(identical(other.condition, condition) || other.condition == condition)&&(identical(other.locationType, locationType) || other.locationType == locationType)&&(identical(other.locationId, locationId) || other.locationId == locationId)&&(identical(other.locationName, locationName) || other.locationName == locationName)&&(identical(other.responsibleId, responsibleId) || other.responsibleId == responsibleId)&&(identical(other.responsibleName, responsibleName) || other.responsibleName == responsibleName)&&(identical(other.receiptId, receiptId) || other.receiptId == receiptId)&&(identical(other.receiptItemId, receiptItemId) || other.receiptItemId == receiptItemId)&&(identical(other.price, price) || other.price == price)&&(identical(other.purchaseDate, purchaseDate) || other.purchaseDate == purchaseDate)&&(identical(other.warrantyExpiresAt, warrantyExpiresAt) || other.warrantyExpiresAt == warrantyExpiresAt)&&(identical(other.serviceLifeMonths, serviceLifeMonths) || other.serviceLifeMonths == serviceLifeMonths)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,name,categoryId,categoryName,serialNumber,unit,quantity,photoUrl,status,condition,locationType,locationId,locationName,responsibleId,responsibleName,receiptId,receiptItemId,price,purchaseDate,warrantyExpiresAt,serviceLifeMonths,issuedAt,notes,createdAt,updatedAt,createdBy,updatedBy]);

@override
String toString() {
  return 'InventoryItem(id: $id, name: $name, categoryId: $categoryId, categoryName: $categoryName, serialNumber: $serialNumber, unit: $unit, quantity: $quantity, photoUrl: $photoUrl, status: $status, condition: $condition, locationType: $locationType, locationId: $locationId, locationName: $locationName, responsibleId: $responsibleId, responsibleName: $responsibleName, receiptId: $receiptId, receiptItemId: $receiptItemId, price: $price, purchaseDate: $purchaseDate, warrantyExpiresAt: $warrantyExpiresAt, serviceLifeMonths: $serviceLifeMonths, issuedAt: $issuedAt, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, updatedBy: $updatedBy)';
}


}

/// @nodoc
abstract mixin class _$InventoryItemCopyWith<$Res> implements $InventoryItemCopyWith<$Res> {
  factory _$InventoryItemCopyWith(_InventoryItem value, $Res Function(_InventoryItem) _then) = __$InventoryItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String categoryId, String? categoryName, String? serialNumber, String unit, double quantity, String? photoUrl, InventoryItemStatus status, InventoryItemCondition condition, InventoryLocationType locationType, String? locationId, String? locationName, String? responsibleId, String? responsibleName, String? receiptId, String? receiptItemId, double? price, DateTime? purchaseDate, DateTime? warrantyExpiresAt, int? serviceLifeMonths, DateTime? issuedAt, String? notes, DateTime? createdAt, DateTime? updatedAt, String? createdBy, String? updatedBy
});




}
/// @nodoc
class __$InventoryItemCopyWithImpl<$Res>
    implements _$InventoryItemCopyWith<$Res> {
  __$InventoryItemCopyWithImpl(this._self, this._then);

  final _InventoryItem _self;
  final $Res Function(_InventoryItem) _then;

/// Create a copy of InventoryItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? categoryId = null,Object? categoryName = freezed,Object? serialNumber = freezed,Object? unit = null,Object? quantity = null,Object? photoUrl = freezed,Object? status = null,Object? condition = null,Object? locationType = null,Object? locationId = freezed,Object? locationName = freezed,Object? responsibleId = freezed,Object? responsibleName = freezed,Object? receiptId = freezed,Object? receiptItemId = freezed,Object? price = freezed,Object? purchaseDate = freezed,Object? warrantyExpiresAt = freezed,Object? serviceLifeMonths = freezed,Object? issuedAt = freezed,Object? notes = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,Object? updatedBy = freezed,}) {
  return _then(_InventoryItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,serialNumber: freezed == serialNumber ? _self.serialNumber : serialNumber // ignore: cast_nullable_to_non_nullable
as String?,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InventoryItemStatus,condition: null == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as InventoryItemCondition,locationType: null == locationType ? _self.locationType : locationType // ignore: cast_nullable_to_non_nullable
as InventoryLocationType,locationId: freezed == locationId ? _self.locationId : locationId // ignore: cast_nullable_to_non_nullable
as String?,locationName: freezed == locationName ? _self.locationName : locationName // ignore: cast_nullable_to_non_nullable
as String?,responsibleId: freezed == responsibleId ? _self.responsibleId : responsibleId // ignore: cast_nullable_to_non_nullable
as String?,responsibleName: freezed == responsibleName ? _self.responsibleName : responsibleName // ignore: cast_nullable_to_non_nullable
as String?,receiptId: freezed == receiptId ? _self.receiptId : receiptId // ignore: cast_nullable_to_non_nullable
as String?,receiptItemId: freezed == receiptItemId ? _self.receiptItemId : receiptItemId // ignore: cast_nullable_to_non_nullable
as String?,price: freezed == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double?,purchaseDate: freezed == purchaseDate ? _self.purchaseDate : purchaseDate // ignore: cast_nullable_to_non_nullable
as DateTime?,warrantyExpiresAt: freezed == warrantyExpiresAt ? _self.warrantyExpiresAt : warrantyExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,serviceLifeMonths: freezed == serviceLifeMonths ? _self.serviceLifeMonths : serviceLifeMonths // ignore: cast_nullable_to_non_nullable
as int?,issuedAt: freezed == issuedAt ? _self.issuedAt : issuedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,updatedBy: freezed == updatedBy ? _self.updatedBy : updatedBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
