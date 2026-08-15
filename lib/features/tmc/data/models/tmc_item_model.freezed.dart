// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tmc_item_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TmcItemModel {

 String get id; String get companyId; String get name; String? get categoryId; String? get subcategoryId; TmcAccountingType get accountingType; String? get sku; String? get manufacturer; String? get model; String get unitOfMeasure; String? get description; String? get photoUrl; TmcItemStatus get status;@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) DateTime? get deliveryDate;@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) DateTime? get acceptanceDate; String? get supplierId; String? get documentNumber; double get unitPrice; double get quantity; double get totalCost; double get vatAmount;@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) DateTime? get warrantyUntil; bool get isArchived; DateTime? get archivedAt; DateTime? get createdAt; DateTime? get updatedAt; String? get createdBy;@JsonKey(includeToJson: false) String? get categoryName;@JsonKey(includeToJson: false) String? get subcategoryName;@JsonKey(includeToJson: false) String? get supplierName;
/// Create a copy of TmcItemModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TmcItemModelCopyWith<TmcItemModel> get copyWith => _$TmcItemModelCopyWithImpl<TmcItemModel>(this as TmcItemModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TmcItemModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.name, name) || other.name == name)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.subcategoryId, subcategoryId) || other.subcategoryId == subcategoryId)&&(identical(other.accountingType, accountingType) || other.accountingType == accountingType)&&(identical(other.sku, sku) || other.sku == sku)&&(identical(other.manufacturer, manufacturer) || other.manufacturer == manufacturer)&&(identical(other.model, model) || other.model == model)&&(identical(other.unitOfMeasure, unitOfMeasure) || other.unitOfMeasure == unitOfMeasure)&&(identical(other.description, description) || other.description == description)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.status, status) || other.status == status)&&(identical(other.deliveryDate, deliveryDate) || other.deliveryDate == deliveryDate)&&(identical(other.acceptanceDate, acceptanceDate) || other.acceptanceDate == acceptanceDate)&&(identical(other.supplierId, supplierId) || other.supplierId == supplierId)&&(identical(other.documentNumber, documentNumber) || other.documentNumber == documentNumber)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.totalCost, totalCost) || other.totalCost == totalCost)&&(identical(other.vatAmount, vatAmount) || other.vatAmount == vatAmount)&&(identical(other.warrantyUntil, warrantyUntil) || other.warrantyUntil == warrantyUntil)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.subcategoryName, subcategoryName) || other.subcategoryName == subcategoryName)&&(identical(other.supplierName, supplierName) || other.supplierName == supplierName));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,name,categoryId,subcategoryId,accountingType,sku,manufacturer,model,unitOfMeasure,description,photoUrl,status,deliveryDate,acceptanceDate,supplierId,documentNumber,unitPrice,quantity,totalCost,vatAmount,warrantyUntil,isArchived,archivedAt,createdAt,updatedAt,createdBy,categoryName,subcategoryName,supplierName]);

@override
String toString() {
  return 'TmcItemModel(id: $id, companyId: $companyId, name: $name, categoryId: $categoryId, subcategoryId: $subcategoryId, accountingType: $accountingType, sku: $sku, manufacturer: $manufacturer, model: $model, unitOfMeasure: $unitOfMeasure, description: $description, photoUrl: $photoUrl, status: $status, deliveryDate: $deliveryDate, acceptanceDate: $acceptanceDate, supplierId: $supplierId, documentNumber: $documentNumber, unitPrice: $unitPrice, quantity: $quantity, totalCost: $totalCost, vatAmount: $vatAmount, warrantyUntil: $warrantyUntil, isArchived: $isArchived, archivedAt: $archivedAt, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, categoryName: $categoryName, subcategoryName: $subcategoryName, supplierName: $supplierName)';
}


}

/// @nodoc
abstract mixin class $TmcItemModelCopyWith<$Res>  {
  factory $TmcItemModelCopyWith(TmcItemModel value, $Res Function(TmcItemModel) _then) = _$TmcItemModelCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String name, String? categoryId, String? subcategoryId, TmcAccountingType accountingType, String? sku, String? manufacturer, String? model, String unitOfMeasure, String? description, String? photoUrl, TmcItemStatus status,@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) DateTime? deliveryDate,@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) DateTime? acceptanceDate, String? supplierId, String? documentNumber, double unitPrice, double quantity, double totalCost, double vatAmount,@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) DateTime? warrantyUntil, bool isArchived, DateTime? archivedAt, DateTime? createdAt, DateTime? updatedAt, String? createdBy,@JsonKey(includeToJson: false) String? categoryName,@JsonKey(includeToJson: false) String? subcategoryName,@JsonKey(includeToJson: false) String? supplierName
});




}
/// @nodoc
class _$TmcItemModelCopyWithImpl<$Res>
    implements $TmcItemModelCopyWith<$Res> {
  _$TmcItemModelCopyWithImpl(this._self, this._then);

  final TmcItemModel _self;
  final $Res Function(TmcItemModel) _then;

/// Create a copy of TmcItemModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? name = null,Object? categoryId = freezed,Object? subcategoryId = freezed,Object? accountingType = null,Object? sku = freezed,Object? manufacturer = freezed,Object? model = freezed,Object? unitOfMeasure = null,Object? description = freezed,Object? photoUrl = freezed,Object? status = null,Object? deliveryDate = freezed,Object? acceptanceDate = freezed,Object? supplierId = freezed,Object? documentNumber = freezed,Object? unitPrice = null,Object? quantity = null,Object? totalCost = null,Object? vatAmount = null,Object? warrantyUntil = freezed,Object? isArchived = null,Object? archivedAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,Object? categoryName = freezed,Object? subcategoryName = freezed,Object? supplierName = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,subcategoryId: freezed == subcategoryId ? _self.subcategoryId : subcategoryId // ignore: cast_nullable_to_non_nullable
as String?,accountingType: null == accountingType ? _self.accountingType : accountingType // ignore: cast_nullable_to_non_nullable
as TmcAccountingType,sku: freezed == sku ? _self.sku : sku // ignore: cast_nullable_to_non_nullable
as String?,manufacturer: freezed == manufacturer ? _self.manufacturer : manufacturer // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,unitOfMeasure: null == unitOfMeasure ? _self.unitOfMeasure : unitOfMeasure // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TmcItemStatus,deliveryDate: freezed == deliveryDate ? _self.deliveryDate : deliveryDate // ignore: cast_nullable_to_non_nullable
as DateTime?,acceptanceDate: freezed == acceptanceDate ? _self.acceptanceDate : acceptanceDate // ignore: cast_nullable_to_non_nullable
as DateTime?,supplierId: freezed == supplierId ? _self.supplierId : supplierId // ignore: cast_nullable_to_non_nullable
as String?,documentNumber: freezed == documentNumber ? _self.documentNumber : documentNumber // ignore: cast_nullable_to_non_nullable
as String?,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as double,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double,totalCost: null == totalCost ? _self.totalCost : totalCost // ignore: cast_nullable_to_non_nullable
as double,vatAmount: null == vatAmount ? _self.vatAmount : vatAmount // ignore: cast_nullable_to_non_nullable
as double,warrantyUntil: freezed == warrantyUntil ? _self.warrantyUntil : warrantyUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,subcategoryName: freezed == subcategoryName ? _self.subcategoryName : subcategoryName // ignore: cast_nullable_to_non_nullable
as String?,supplierName: freezed == supplierName ? _self.supplierName : supplierName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _TmcItemModel extends TmcItemModel {
  const _TmcItemModel({required this.id, required this.companyId, required this.name, this.categoryId, this.subcategoryId, this.accountingType = TmcAccountingType.individual, this.sku, this.manufacturer, this.model, this.unitOfMeasure = 'шт', this.description, this.photoUrl, this.status = TmcItemStatus.active, @JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) this.deliveryDate, @JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) this.acceptanceDate, this.supplierId, this.documentNumber, this.unitPrice = 0, this.quantity = 0, this.totalCost = 0, this.vatAmount = 0, @JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) this.warrantyUntil, this.isArchived = false, this.archivedAt, this.createdAt, this.updatedAt, this.createdBy, @JsonKey(includeToJson: false) this.categoryName, @JsonKey(includeToJson: false) this.subcategoryName, @JsonKey(includeToJson: false) this.supplierName}): super._();
  

@override final  String id;
@override final  String companyId;
@override final  String name;
@override final  String? categoryId;
@override final  String? subcategoryId;
@override@JsonKey() final  TmcAccountingType accountingType;
@override final  String? sku;
@override final  String? manufacturer;
@override final  String? model;
@override@JsonKey() final  String unitOfMeasure;
@override final  String? description;
@override final  String? photoUrl;
@override@JsonKey() final  TmcItemStatus status;
@override@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) final  DateTime? deliveryDate;
@override@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) final  DateTime? acceptanceDate;
@override final  String? supplierId;
@override final  String? documentNumber;
@override@JsonKey() final  double unitPrice;
@override@JsonKey() final  double quantity;
@override@JsonKey() final  double totalCost;
@override@JsonKey() final  double vatAmount;
@override@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) final  DateTime? warrantyUntil;
@override@JsonKey() final  bool isArchived;
@override final  DateTime? archivedAt;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;
@override final  String? createdBy;
@override@JsonKey(includeToJson: false) final  String? categoryName;
@override@JsonKey(includeToJson: false) final  String? subcategoryName;
@override@JsonKey(includeToJson: false) final  String? supplierName;

/// Create a copy of TmcItemModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TmcItemModelCopyWith<_TmcItemModel> get copyWith => __$TmcItemModelCopyWithImpl<_TmcItemModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TmcItemModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.name, name) || other.name == name)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.subcategoryId, subcategoryId) || other.subcategoryId == subcategoryId)&&(identical(other.accountingType, accountingType) || other.accountingType == accountingType)&&(identical(other.sku, sku) || other.sku == sku)&&(identical(other.manufacturer, manufacturer) || other.manufacturer == manufacturer)&&(identical(other.model, model) || other.model == model)&&(identical(other.unitOfMeasure, unitOfMeasure) || other.unitOfMeasure == unitOfMeasure)&&(identical(other.description, description) || other.description == description)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.status, status) || other.status == status)&&(identical(other.deliveryDate, deliveryDate) || other.deliveryDate == deliveryDate)&&(identical(other.acceptanceDate, acceptanceDate) || other.acceptanceDate == acceptanceDate)&&(identical(other.supplierId, supplierId) || other.supplierId == supplierId)&&(identical(other.documentNumber, documentNumber) || other.documentNumber == documentNumber)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.totalCost, totalCost) || other.totalCost == totalCost)&&(identical(other.vatAmount, vatAmount) || other.vatAmount == vatAmount)&&(identical(other.warrantyUntil, warrantyUntil) || other.warrantyUntil == warrantyUntil)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.subcategoryName, subcategoryName) || other.subcategoryName == subcategoryName)&&(identical(other.supplierName, supplierName) || other.supplierName == supplierName));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,name,categoryId,subcategoryId,accountingType,sku,manufacturer,model,unitOfMeasure,description,photoUrl,status,deliveryDate,acceptanceDate,supplierId,documentNumber,unitPrice,quantity,totalCost,vatAmount,warrantyUntil,isArchived,archivedAt,createdAt,updatedAt,createdBy,categoryName,subcategoryName,supplierName]);

@override
String toString() {
  return 'TmcItemModel(id: $id, companyId: $companyId, name: $name, categoryId: $categoryId, subcategoryId: $subcategoryId, accountingType: $accountingType, sku: $sku, manufacturer: $manufacturer, model: $model, unitOfMeasure: $unitOfMeasure, description: $description, photoUrl: $photoUrl, status: $status, deliveryDate: $deliveryDate, acceptanceDate: $acceptanceDate, supplierId: $supplierId, documentNumber: $documentNumber, unitPrice: $unitPrice, quantity: $quantity, totalCost: $totalCost, vatAmount: $vatAmount, warrantyUntil: $warrantyUntil, isArchived: $isArchived, archivedAt: $archivedAt, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, categoryName: $categoryName, subcategoryName: $subcategoryName, supplierName: $supplierName)';
}


}

/// @nodoc
abstract mixin class _$TmcItemModelCopyWith<$Res> implements $TmcItemModelCopyWith<$Res> {
  factory _$TmcItemModelCopyWith(_TmcItemModel value, $Res Function(_TmcItemModel) _then) = __$TmcItemModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String name, String? categoryId, String? subcategoryId, TmcAccountingType accountingType, String? sku, String? manufacturer, String? model, String unitOfMeasure, String? description, String? photoUrl, TmcItemStatus status,@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) DateTime? deliveryDate,@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) DateTime? acceptanceDate, String? supplierId, String? documentNumber, double unitPrice, double quantity, double totalCost, double vatAmount,@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) DateTime? warrantyUntil, bool isArchived, DateTime? archivedAt, DateTime? createdAt, DateTime? updatedAt, String? createdBy,@JsonKey(includeToJson: false) String? categoryName,@JsonKey(includeToJson: false) String? subcategoryName,@JsonKey(includeToJson: false) String? supplierName
});




}
/// @nodoc
class __$TmcItemModelCopyWithImpl<$Res>
    implements _$TmcItemModelCopyWith<$Res> {
  __$TmcItemModelCopyWithImpl(this._self, this._then);

  final _TmcItemModel _self;
  final $Res Function(_TmcItemModel) _then;

/// Create a copy of TmcItemModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? name = null,Object? categoryId = freezed,Object? subcategoryId = freezed,Object? accountingType = null,Object? sku = freezed,Object? manufacturer = freezed,Object? model = freezed,Object? unitOfMeasure = null,Object? description = freezed,Object? photoUrl = freezed,Object? status = null,Object? deliveryDate = freezed,Object? acceptanceDate = freezed,Object? supplierId = freezed,Object? documentNumber = freezed,Object? unitPrice = null,Object? quantity = null,Object? totalCost = null,Object? vatAmount = null,Object? warrantyUntil = freezed,Object? isArchived = null,Object? archivedAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,Object? categoryName = freezed,Object? subcategoryName = freezed,Object? supplierName = freezed,}) {
  return _then(_TmcItemModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,subcategoryId: freezed == subcategoryId ? _self.subcategoryId : subcategoryId // ignore: cast_nullable_to_non_nullable
as String?,accountingType: null == accountingType ? _self.accountingType : accountingType // ignore: cast_nullable_to_non_nullable
as TmcAccountingType,sku: freezed == sku ? _self.sku : sku // ignore: cast_nullable_to_non_nullable
as String?,manufacturer: freezed == manufacturer ? _self.manufacturer : manufacturer // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,unitOfMeasure: null == unitOfMeasure ? _self.unitOfMeasure : unitOfMeasure // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TmcItemStatus,deliveryDate: freezed == deliveryDate ? _self.deliveryDate : deliveryDate // ignore: cast_nullable_to_non_nullable
as DateTime?,acceptanceDate: freezed == acceptanceDate ? _self.acceptanceDate : acceptanceDate // ignore: cast_nullable_to_non_nullable
as DateTime?,supplierId: freezed == supplierId ? _self.supplierId : supplierId // ignore: cast_nullable_to_non_nullable
as String?,documentNumber: freezed == documentNumber ? _self.documentNumber : documentNumber // ignore: cast_nullable_to_non_nullable
as String?,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as double,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double,totalCost: null == totalCost ? _self.totalCost : totalCost // ignore: cast_nullable_to_non_nullable
as double,vatAmount: null == vatAmount ? _self.vatAmount : vatAmount // ignore: cast_nullable_to_non_nullable
as double,warrantyUntil: freezed == warrantyUntil ? _self.warrantyUntil : warrantyUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,subcategoryName: freezed == subcategoryName ? _self.subcategoryName : subcategoryName // ignore: cast_nullable_to_non_nullable
as String?,supplierName: freezed == supplierName ? _self.supplierName : supplierName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
