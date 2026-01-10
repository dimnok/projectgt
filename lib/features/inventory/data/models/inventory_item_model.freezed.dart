// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'inventory_item_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InventoryItemModel {

 String get id; String get name;@JsonKey(name: 'category_id') String get categoryId;@JsonKey(name: 'serial_number') String? get serialNumber; String get unit; double get quantity;@JsonKey(name: 'photo_url') String? get photoUrl; String get status; String get condition;@JsonKey(name: 'location_type') String get locationType;@JsonKey(name: 'location_id') String? get locationId;@JsonKey(name: 'responsible_id') String? get responsibleId;@JsonKey(name: 'receipt_id') String? get receiptId;@JsonKey(name: 'receipt_item_id') String? get receiptItemId; double? get price;@JsonKey(name: 'purchase_date') DateTime? get purchaseDate;@JsonKey(name: 'warranty_expires_at') DateTime? get warrantyExpiresAt;@JsonKey(name: 'service_life_months') int? get serviceLifeMonths;@JsonKey(name: 'issued_at') DateTime? get issuedAt; String? get notes;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;@JsonKey(name: 'created_by') String? get createdBy;@JsonKey(name: 'updated_by') String? get updatedBy;
/// Create a copy of InventoryItemModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InventoryItemModelCopyWith<InventoryItemModel> get copyWith => _$InventoryItemModelCopyWithImpl<InventoryItemModel>(this as InventoryItemModel, _$identity);

  /// Serializes this InventoryItemModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InventoryItemModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.serialNumber, serialNumber) || other.serialNumber == serialNumber)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.status, status) || other.status == status)&&(identical(other.condition, condition) || other.condition == condition)&&(identical(other.locationType, locationType) || other.locationType == locationType)&&(identical(other.locationId, locationId) || other.locationId == locationId)&&(identical(other.responsibleId, responsibleId) || other.responsibleId == responsibleId)&&(identical(other.receiptId, receiptId) || other.receiptId == receiptId)&&(identical(other.receiptItemId, receiptItemId) || other.receiptItemId == receiptItemId)&&(identical(other.price, price) || other.price == price)&&(identical(other.purchaseDate, purchaseDate) || other.purchaseDate == purchaseDate)&&(identical(other.warrantyExpiresAt, warrantyExpiresAt) || other.warrantyExpiresAt == warrantyExpiresAt)&&(identical(other.serviceLifeMonths, serviceLifeMonths) || other.serviceLifeMonths == serviceLifeMonths)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,name,categoryId,serialNumber,unit,quantity,photoUrl,status,condition,locationType,locationId,responsibleId,receiptId,receiptItemId,price,purchaseDate,warrantyExpiresAt,serviceLifeMonths,issuedAt,notes,createdAt,updatedAt,createdBy,updatedBy]);

@override
String toString() {
  return 'InventoryItemModel(id: $id, name: $name, categoryId: $categoryId, serialNumber: $serialNumber, unit: $unit, quantity: $quantity, photoUrl: $photoUrl, status: $status, condition: $condition, locationType: $locationType, locationId: $locationId, responsibleId: $responsibleId, receiptId: $receiptId, receiptItemId: $receiptItemId, price: $price, purchaseDate: $purchaseDate, warrantyExpiresAt: $warrantyExpiresAt, serviceLifeMonths: $serviceLifeMonths, issuedAt: $issuedAt, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, updatedBy: $updatedBy)';
}


}

/// @nodoc
abstract mixin class $InventoryItemModelCopyWith<$Res>  {
  factory $InventoryItemModelCopyWith(InventoryItemModel value, $Res Function(InventoryItemModel) _then) = _$InventoryItemModelCopyWithImpl;
@useResult
$Res call({
 String id, String name,@JsonKey(name: 'category_id') String categoryId,@JsonKey(name: 'serial_number') String? serialNumber, String unit, double quantity,@JsonKey(name: 'photo_url') String? photoUrl, String status, String condition,@JsonKey(name: 'location_type') String locationType,@JsonKey(name: 'location_id') String? locationId,@JsonKey(name: 'responsible_id') String? responsibleId,@JsonKey(name: 'receipt_id') String? receiptId,@JsonKey(name: 'receipt_item_id') String? receiptItemId, double? price,@JsonKey(name: 'purchase_date') DateTime? purchaseDate,@JsonKey(name: 'warranty_expires_at') DateTime? warrantyExpiresAt,@JsonKey(name: 'service_life_months') int? serviceLifeMonths,@JsonKey(name: 'issued_at') DateTime? issuedAt, String? notes,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt,@JsonKey(name: 'created_by') String? createdBy,@JsonKey(name: 'updated_by') String? updatedBy
});




}
/// @nodoc
class _$InventoryItemModelCopyWithImpl<$Res>
    implements $InventoryItemModelCopyWith<$Res> {
  _$InventoryItemModelCopyWithImpl(this._self, this._then);

  final InventoryItemModel _self;
  final $Res Function(InventoryItemModel) _then;

/// Create a copy of InventoryItemModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? categoryId = null,Object? serialNumber = freezed,Object? unit = null,Object? quantity = null,Object? photoUrl = freezed,Object? status = null,Object? condition = null,Object? locationType = null,Object? locationId = freezed,Object? responsibleId = freezed,Object? receiptId = freezed,Object? receiptItemId = freezed,Object? price = freezed,Object? purchaseDate = freezed,Object? warrantyExpiresAt = freezed,Object? serviceLifeMonths = freezed,Object? issuedAt = freezed,Object? notes = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,Object? updatedBy = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,serialNumber: freezed == serialNumber ? _self.serialNumber : serialNumber // ignore: cast_nullable_to_non_nullable
as String?,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,condition: null == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as String,locationType: null == locationType ? _self.locationType : locationType // ignore: cast_nullable_to_non_nullable
as String,locationId: freezed == locationId ? _self.locationId : locationId // ignore: cast_nullable_to_non_nullable
as String?,responsibleId: freezed == responsibleId ? _self.responsibleId : responsibleId // ignore: cast_nullable_to_non_nullable
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

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class _InventoryItemModel extends InventoryItemModel {
  const _InventoryItemModel({required this.id, required this.name, @JsonKey(name: 'category_id') required this.categoryId, @JsonKey(name: 'serial_number') this.serialNumber, required this.unit, this.quantity = 1.0, @JsonKey(name: 'photo_url') this.photoUrl, required this.status, required this.condition, @JsonKey(name: 'location_type') required this.locationType, @JsonKey(name: 'location_id') this.locationId, @JsonKey(name: 'responsible_id') this.responsibleId, @JsonKey(name: 'receipt_id') this.receiptId, @JsonKey(name: 'receipt_item_id') this.receiptItemId, this.price, @JsonKey(name: 'purchase_date') this.purchaseDate, @JsonKey(name: 'warranty_expires_at') this.warrantyExpiresAt, @JsonKey(name: 'service_life_months') this.serviceLifeMonths, @JsonKey(name: 'issued_at') this.issuedAt, this.notes, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt, @JsonKey(name: 'created_by') this.createdBy, @JsonKey(name: 'updated_by') this.updatedBy}): super._();
  factory _InventoryItemModel.fromJson(Map<String, dynamic> json) => _$InventoryItemModelFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey(name: 'category_id') final  String categoryId;
@override@JsonKey(name: 'serial_number') final  String? serialNumber;
@override final  String unit;
@override@JsonKey() final  double quantity;
@override@JsonKey(name: 'photo_url') final  String? photoUrl;
@override final  String status;
@override final  String condition;
@override@JsonKey(name: 'location_type') final  String locationType;
@override@JsonKey(name: 'location_id') final  String? locationId;
@override@JsonKey(name: 'responsible_id') final  String? responsibleId;
@override@JsonKey(name: 'receipt_id') final  String? receiptId;
@override@JsonKey(name: 'receipt_item_id') final  String? receiptItemId;
@override final  double? price;
@override@JsonKey(name: 'purchase_date') final  DateTime? purchaseDate;
@override@JsonKey(name: 'warranty_expires_at') final  DateTime? warrantyExpiresAt;
@override@JsonKey(name: 'service_life_months') final  int? serviceLifeMonths;
@override@JsonKey(name: 'issued_at') final  DateTime? issuedAt;
@override final  String? notes;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;
@override@JsonKey(name: 'created_by') final  String? createdBy;
@override@JsonKey(name: 'updated_by') final  String? updatedBy;

/// Create a copy of InventoryItemModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InventoryItemModelCopyWith<_InventoryItemModel> get copyWith => __$InventoryItemModelCopyWithImpl<_InventoryItemModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InventoryItemModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InventoryItemModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.serialNumber, serialNumber) || other.serialNumber == serialNumber)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.status, status) || other.status == status)&&(identical(other.condition, condition) || other.condition == condition)&&(identical(other.locationType, locationType) || other.locationType == locationType)&&(identical(other.locationId, locationId) || other.locationId == locationId)&&(identical(other.responsibleId, responsibleId) || other.responsibleId == responsibleId)&&(identical(other.receiptId, receiptId) || other.receiptId == receiptId)&&(identical(other.receiptItemId, receiptItemId) || other.receiptItemId == receiptItemId)&&(identical(other.price, price) || other.price == price)&&(identical(other.purchaseDate, purchaseDate) || other.purchaseDate == purchaseDate)&&(identical(other.warrantyExpiresAt, warrantyExpiresAt) || other.warrantyExpiresAt == warrantyExpiresAt)&&(identical(other.serviceLifeMonths, serviceLifeMonths) || other.serviceLifeMonths == serviceLifeMonths)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.updatedBy, updatedBy) || other.updatedBy == updatedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,name,categoryId,serialNumber,unit,quantity,photoUrl,status,condition,locationType,locationId,responsibleId,receiptId,receiptItemId,price,purchaseDate,warrantyExpiresAt,serviceLifeMonths,issuedAt,notes,createdAt,updatedAt,createdBy,updatedBy]);

@override
String toString() {
  return 'InventoryItemModel(id: $id, name: $name, categoryId: $categoryId, serialNumber: $serialNumber, unit: $unit, quantity: $quantity, photoUrl: $photoUrl, status: $status, condition: $condition, locationType: $locationType, locationId: $locationId, responsibleId: $responsibleId, receiptId: $receiptId, receiptItemId: $receiptItemId, price: $price, purchaseDate: $purchaseDate, warrantyExpiresAt: $warrantyExpiresAt, serviceLifeMonths: $serviceLifeMonths, issuedAt: $issuedAt, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, updatedBy: $updatedBy)';
}


}

/// @nodoc
abstract mixin class _$InventoryItemModelCopyWith<$Res> implements $InventoryItemModelCopyWith<$Res> {
  factory _$InventoryItemModelCopyWith(_InventoryItemModel value, $Res Function(_InventoryItemModel) _then) = __$InventoryItemModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String name,@JsonKey(name: 'category_id') String categoryId,@JsonKey(name: 'serial_number') String? serialNumber, String unit, double quantity,@JsonKey(name: 'photo_url') String? photoUrl, String status, String condition,@JsonKey(name: 'location_type') String locationType,@JsonKey(name: 'location_id') String? locationId,@JsonKey(name: 'responsible_id') String? responsibleId,@JsonKey(name: 'receipt_id') String? receiptId,@JsonKey(name: 'receipt_item_id') String? receiptItemId, double? price,@JsonKey(name: 'purchase_date') DateTime? purchaseDate,@JsonKey(name: 'warranty_expires_at') DateTime? warrantyExpiresAt,@JsonKey(name: 'service_life_months') int? serviceLifeMonths,@JsonKey(name: 'issued_at') DateTime? issuedAt, String? notes,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt,@JsonKey(name: 'created_by') String? createdBy,@JsonKey(name: 'updated_by') String? updatedBy
});




}
/// @nodoc
class __$InventoryItemModelCopyWithImpl<$Res>
    implements _$InventoryItemModelCopyWith<$Res> {
  __$InventoryItemModelCopyWithImpl(this._self, this._then);

  final _InventoryItemModel _self;
  final $Res Function(_InventoryItemModel) _then;

/// Create a copy of InventoryItemModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? categoryId = null,Object? serialNumber = freezed,Object? unit = null,Object? quantity = null,Object? photoUrl = freezed,Object? status = null,Object? condition = null,Object? locationType = null,Object? locationId = freezed,Object? responsibleId = freezed,Object? receiptId = freezed,Object? receiptItemId = freezed,Object? price = freezed,Object? purchaseDate = freezed,Object? warrantyExpiresAt = freezed,Object? serviceLifeMonths = freezed,Object? issuedAt = freezed,Object? notes = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,Object? updatedBy = freezed,}) {
  return _then(_InventoryItemModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,serialNumber: freezed == serialNumber ? _self.serialNumber : serialNumber // ignore: cast_nullable_to_non_nullable
as String?,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,condition: null == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as String,locationType: null == locationType ? _self.locationType : locationType // ignore: cast_nullable_to_non_nullable
as String,locationId: freezed == locationId ? _self.locationId : locationId // ignore: cast_nullable_to_non_nullable
as String?,responsibleId: freezed == responsibleId ? _self.responsibleId : responsibleId // ignore: cast_nullable_to_non_nullable
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
