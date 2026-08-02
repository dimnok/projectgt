// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tmc_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TmcItem {

/// Идентификатор записи.
 String get id;/// Компания-владелец.
 String get companyId;/// Наименование.
 String get name;/// Категория.
 String? get categoryId;/// Подкатегория.
 String? get subcategoryId;/// Тип учёта.
 TmcAccountingType get accountingType;/// Артикул / SKU.
 String? get sku;/// Производитель.
 String? get manufacturer;/// Модель.
 String? get model;/// Единица измерения.
 String get unitOfMeasure;/// Описание.
 String? get description;/// URL фото.
 String? get photoUrl;/// Статус позиции.
 TmcItemStatus get status;/// Дата поставки.
 DateTime? get deliveryDate;/// Дата приёмки.
 DateTime? get acceptanceDate;/// Поставщик (контрагент).
 String? get supplierId;/// Номер документа поступления.
 String? get documentNumber;/// Цена за единицу.
 double get unitPrice;/// Общее количество (на складе + выдано + на объекте).
 double get quantity;/// Количество на складе / в офисе.
 double get qtyInStock;/// Количество у сотрудников.
 double get qtyIssued;/// Количество на объектах.
 double get qtyOnObject;/// Краткое описание мест хранения (склады).
 String? get locationSummary;/// Общая стоимость (вычисляемое поле БД).
 double get totalCost;/// Сумма НДС.
 double get vatAmount;/// Гарантия до.
 DateTime? get warrantyUntil;/// В архиве.
 bool get isArchived;/// Дата архивации.
 DateTime? get archivedAt;/// Дата создания.
 DateTime? get createdAt;/// Дата обновления.
 DateTime? get updatedAt;/// Автор создания.
 String? get createdBy;/// Название категории (join).
 String? get categoryName;/// Название подкатегории (join).
 String? get subcategoryName;/// Название поставщика (join).
 String? get supplierName;
/// Create a copy of TmcItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TmcItemCopyWith<TmcItem> get copyWith => _$TmcItemCopyWithImpl<TmcItem>(this as TmcItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TmcItem&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.name, name) || other.name == name)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.subcategoryId, subcategoryId) || other.subcategoryId == subcategoryId)&&(identical(other.accountingType, accountingType) || other.accountingType == accountingType)&&(identical(other.sku, sku) || other.sku == sku)&&(identical(other.manufacturer, manufacturer) || other.manufacturer == manufacturer)&&(identical(other.model, model) || other.model == model)&&(identical(other.unitOfMeasure, unitOfMeasure) || other.unitOfMeasure == unitOfMeasure)&&(identical(other.description, description) || other.description == description)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.status, status) || other.status == status)&&(identical(other.deliveryDate, deliveryDate) || other.deliveryDate == deliveryDate)&&(identical(other.acceptanceDate, acceptanceDate) || other.acceptanceDate == acceptanceDate)&&(identical(other.supplierId, supplierId) || other.supplierId == supplierId)&&(identical(other.documentNumber, documentNumber) || other.documentNumber == documentNumber)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.qtyInStock, qtyInStock) || other.qtyInStock == qtyInStock)&&(identical(other.qtyIssued, qtyIssued) || other.qtyIssued == qtyIssued)&&(identical(other.qtyOnObject, qtyOnObject) || other.qtyOnObject == qtyOnObject)&&(identical(other.locationSummary, locationSummary) || other.locationSummary == locationSummary)&&(identical(other.totalCost, totalCost) || other.totalCost == totalCost)&&(identical(other.vatAmount, vatAmount) || other.vatAmount == vatAmount)&&(identical(other.warrantyUntil, warrantyUntil) || other.warrantyUntil == warrantyUntil)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.subcategoryName, subcategoryName) || other.subcategoryName == subcategoryName)&&(identical(other.supplierName, supplierName) || other.supplierName == supplierName));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,name,categoryId,subcategoryId,accountingType,sku,manufacturer,model,unitOfMeasure,description,photoUrl,status,deliveryDate,acceptanceDate,supplierId,documentNumber,unitPrice,quantity,qtyInStock,qtyIssued,qtyOnObject,locationSummary,totalCost,vatAmount,warrantyUntil,isArchived,archivedAt,createdAt,updatedAt,createdBy,categoryName,subcategoryName,supplierName]);

@override
String toString() {
  return 'TmcItem(id: $id, companyId: $companyId, name: $name, categoryId: $categoryId, subcategoryId: $subcategoryId, accountingType: $accountingType, sku: $sku, manufacturer: $manufacturer, model: $model, unitOfMeasure: $unitOfMeasure, description: $description, photoUrl: $photoUrl, status: $status, deliveryDate: $deliveryDate, acceptanceDate: $acceptanceDate, supplierId: $supplierId, documentNumber: $documentNumber, unitPrice: $unitPrice, quantity: $quantity, qtyInStock: $qtyInStock, qtyIssued: $qtyIssued, qtyOnObject: $qtyOnObject, locationSummary: $locationSummary, totalCost: $totalCost, vatAmount: $vatAmount, warrantyUntil: $warrantyUntil, isArchived: $isArchived, archivedAt: $archivedAt, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, categoryName: $categoryName, subcategoryName: $subcategoryName, supplierName: $supplierName)';
}


}

/// @nodoc
abstract mixin class $TmcItemCopyWith<$Res>  {
  factory $TmcItemCopyWith(TmcItem value, $Res Function(TmcItem) _then) = _$TmcItemCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String name, String? categoryId, String? subcategoryId, TmcAccountingType accountingType, String? sku, String? manufacturer, String? model, String unitOfMeasure, String? description, String? photoUrl, TmcItemStatus status, DateTime? deliveryDate, DateTime? acceptanceDate, String? supplierId, String? documentNumber, double unitPrice, double quantity, double qtyInStock, double qtyIssued, double qtyOnObject, String? locationSummary, double totalCost, double vatAmount, DateTime? warrantyUntil, bool isArchived, DateTime? archivedAt, DateTime? createdAt, DateTime? updatedAt, String? createdBy, String? categoryName, String? subcategoryName, String? supplierName
});




}
/// @nodoc
class _$TmcItemCopyWithImpl<$Res>
    implements $TmcItemCopyWith<$Res> {
  _$TmcItemCopyWithImpl(this._self, this._then);

  final TmcItem _self;
  final $Res Function(TmcItem) _then;

/// Create a copy of TmcItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? name = null,Object? categoryId = freezed,Object? subcategoryId = freezed,Object? accountingType = null,Object? sku = freezed,Object? manufacturer = freezed,Object? model = freezed,Object? unitOfMeasure = null,Object? description = freezed,Object? photoUrl = freezed,Object? status = null,Object? deliveryDate = freezed,Object? acceptanceDate = freezed,Object? supplierId = freezed,Object? documentNumber = freezed,Object? unitPrice = null,Object? quantity = null,Object? qtyInStock = null,Object? qtyIssued = null,Object? qtyOnObject = null,Object? locationSummary = freezed,Object? totalCost = null,Object? vatAmount = null,Object? warrantyUntil = freezed,Object? isArchived = null,Object? archivedAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,Object? categoryName = freezed,Object? subcategoryName = freezed,Object? supplierName = freezed,}) {
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
as double,qtyInStock: null == qtyInStock ? _self.qtyInStock : qtyInStock // ignore: cast_nullable_to_non_nullable
as double,qtyIssued: null == qtyIssued ? _self.qtyIssued : qtyIssued // ignore: cast_nullable_to_non_nullable
as double,qtyOnObject: null == qtyOnObject ? _self.qtyOnObject : qtyOnObject // ignore: cast_nullable_to_non_nullable
as double,locationSummary: freezed == locationSummary ? _self.locationSummary : locationSummary // ignore: cast_nullable_to_non_nullable
as String?,totalCost: null == totalCost ? _self.totalCost : totalCost // ignore: cast_nullable_to_non_nullable
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


class _TmcItem implements TmcItem {
  const _TmcItem({required this.id, required this.companyId, required this.name, this.categoryId, this.subcategoryId, this.accountingType = TmcAccountingType.individual, this.sku, this.manufacturer, this.model, this.unitOfMeasure = 'шт', this.description, this.photoUrl, this.status = TmcItemStatus.active, this.deliveryDate, this.acceptanceDate, this.supplierId, this.documentNumber, this.unitPrice = 0, this.quantity = 0, this.qtyInStock = 0, this.qtyIssued = 0, this.qtyOnObject = 0, this.locationSummary, this.totalCost = 0, this.vatAmount = 0, this.warrantyUntil, this.isArchived = false, this.archivedAt, this.createdAt, this.updatedAt, this.createdBy, this.categoryName, this.subcategoryName, this.supplierName});
  

/// Идентификатор записи.
@override final  String id;
/// Компания-владелец.
@override final  String companyId;
/// Наименование.
@override final  String name;
/// Категория.
@override final  String? categoryId;
/// Подкатегория.
@override final  String? subcategoryId;
/// Тип учёта.
@override@JsonKey() final  TmcAccountingType accountingType;
/// Артикул / SKU.
@override final  String? sku;
/// Производитель.
@override final  String? manufacturer;
/// Модель.
@override final  String? model;
/// Единица измерения.
@override@JsonKey() final  String unitOfMeasure;
/// Описание.
@override final  String? description;
/// URL фото.
@override final  String? photoUrl;
/// Статус позиции.
@override@JsonKey() final  TmcItemStatus status;
/// Дата поставки.
@override final  DateTime? deliveryDate;
/// Дата приёмки.
@override final  DateTime? acceptanceDate;
/// Поставщик (контрагент).
@override final  String? supplierId;
/// Номер документа поступления.
@override final  String? documentNumber;
/// Цена за единицу.
@override@JsonKey() final  double unitPrice;
/// Общее количество (на складе + выдано + на объекте).
@override@JsonKey() final  double quantity;
/// Количество на складе / в офисе.
@override@JsonKey() final  double qtyInStock;
/// Количество у сотрудников.
@override@JsonKey() final  double qtyIssued;
/// Количество на объектах.
@override@JsonKey() final  double qtyOnObject;
/// Краткое описание мест хранения (склады).
@override final  String? locationSummary;
/// Общая стоимость (вычисляемое поле БД).
@override@JsonKey() final  double totalCost;
/// Сумма НДС.
@override@JsonKey() final  double vatAmount;
/// Гарантия до.
@override final  DateTime? warrantyUntil;
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
/// Название категории (join).
@override final  String? categoryName;
/// Название подкатегории (join).
@override final  String? subcategoryName;
/// Название поставщика (join).
@override final  String? supplierName;

/// Create a copy of TmcItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TmcItemCopyWith<_TmcItem> get copyWith => __$TmcItemCopyWithImpl<_TmcItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TmcItem&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.name, name) || other.name == name)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.subcategoryId, subcategoryId) || other.subcategoryId == subcategoryId)&&(identical(other.accountingType, accountingType) || other.accountingType == accountingType)&&(identical(other.sku, sku) || other.sku == sku)&&(identical(other.manufacturer, manufacturer) || other.manufacturer == manufacturer)&&(identical(other.model, model) || other.model == model)&&(identical(other.unitOfMeasure, unitOfMeasure) || other.unitOfMeasure == unitOfMeasure)&&(identical(other.description, description) || other.description == description)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.status, status) || other.status == status)&&(identical(other.deliveryDate, deliveryDate) || other.deliveryDate == deliveryDate)&&(identical(other.acceptanceDate, acceptanceDate) || other.acceptanceDate == acceptanceDate)&&(identical(other.supplierId, supplierId) || other.supplierId == supplierId)&&(identical(other.documentNumber, documentNumber) || other.documentNumber == documentNumber)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.qtyInStock, qtyInStock) || other.qtyInStock == qtyInStock)&&(identical(other.qtyIssued, qtyIssued) || other.qtyIssued == qtyIssued)&&(identical(other.qtyOnObject, qtyOnObject) || other.qtyOnObject == qtyOnObject)&&(identical(other.locationSummary, locationSummary) || other.locationSummary == locationSummary)&&(identical(other.totalCost, totalCost) || other.totalCost == totalCost)&&(identical(other.vatAmount, vatAmount) || other.vatAmount == vatAmount)&&(identical(other.warrantyUntil, warrantyUntil) || other.warrantyUntil == warrantyUntil)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.subcategoryName, subcategoryName) || other.subcategoryName == subcategoryName)&&(identical(other.supplierName, supplierName) || other.supplierName == supplierName));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,name,categoryId,subcategoryId,accountingType,sku,manufacturer,model,unitOfMeasure,description,photoUrl,status,deliveryDate,acceptanceDate,supplierId,documentNumber,unitPrice,quantity,qtyInStock,qtyIssued,qtyOnObject,locationSummary,totalCost,vatAmount,warrantyUntil,isArchived,archivedAt,createdAt,updatedAt,createdBy,categoryName,subcategoryName,supplierName]);

@override
String toString() {
  return 'TmcItem(id: $id, companyId: $companyId, name: $name, categoryId: $categoryId, subcategoryId: $subcategoryId, accountingType: $accountingType, sku: $sku, manufacturer: $manufacturer, model: $model, unitOfMeasure: $unitOfMeasure, description: $description, photoUrl: $photoUrl, status: $status, deliveryDate: $deliveryDate, acceptanceDate: $acceptanceDate, supplierId: $supplierId, documentNumber: $documentNumber, unitPrice: $unitPrice, quantity: $quantity, qtyInStock: $qtyInStock, qtyIssued: $qtyIssued, qtyOnObject: $qtyOnObject, locationSummary: $locationSummary, totalCost: $totalCost, vatAmount: $vatAmount, warrantyUntil: $warrantyUntil, isArchived: $isArchived, archivedAt: $archivedAt, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, categoryName: $categoryName, subcategoryName: $subcategoryName, supplierName: $supplierName)';
}


}

/// @nodoc
abstract mixin class _$TmcItemCopyWith<$Res> implements $TmcItemCopyWith<$Res> {
  factory _$TmcItemCopyWith(_TmcItem value, $Res Function(_TmcItem) _then) = __$TmcItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String name, String? categoryId, String? subcategoryId, TmcAccountingType accountingType, String? sku, String? manufacturer, String? model, String unitOfMeasure, String? description, String? photoUrl, TmcItemStatus status, DateTime? deliveryDate, DateTime? acceptanceDate, String? supplierId, String? documentNumber, double unitPrice, double quantity, double qtyInStock, double qtyIssued, double qtyOnObject, String? locationSummary, double totalCost, double vatAmount, DateTime? warrantyUntil, bool isArchived, DateTime? archivedAt, DateTime? createdAt, DateTime? updatedAt, String? createdBy, String? categoryName, String? subcategoryName, String? supplierName
});




}
/// @nodoc
class __$TmcItemCopyWithImpl<$Res>
    implements _$TmcItemCopyWith<$Res> {
  __$TmcItemCopyWithImpl(this._self, this._then);

  final _TmcItem _self;
  final $Res Function(_TmcItem) _then;

/// Create a copy of TmcItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? name = null,Object? categoryId = freezed,Object? subcategoryId = freezed,Object? accountingType = null,Object? sku = freezed,Object? manufacturer = freezed,Object? model = freezed,Object? unitOfMeasure = null,Object? description = freezed,Object? photoUrl = freezed,Object? status = null,Object? deliveryDate = freezed,Object? acceptanceDate = freezed,Object? supplierId = freezed,Object? documentNumber = freezed,Object? unitPrice = null,Object? quantity = null,Object? qtyInStock = null,Object? qtyIssued = null,Object? qtyOnObject = null,Object? locationSummary = freezed,Object? totalCost = null,Object? vatAmount = null,Object? warrantyUntil = freezed,Object? isArchived = null,Object? archivedAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,Object? categoryName = freezed,Object? subcategoryName = freezed,Object? supplierName = freezed,}) {
  return _then(_TmcItem(
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
as double,qtyInStock: null == qtyInStock ? _self.qtyInStock : qtyInStock // ignore: cast_nullable_to_non_nullable
as double,qtyIssued: null == qtyIssued ? _self.qtyIssued : qtyIssued // ignore: cast_nullable_to_non_nullable
as double,qtyOnObject: null == qtyOnObject ? _self.qtyOnObject : qtyOnObject // ignore: cast_nullable_to_non_nullable
as double,locationSummary: freezed == locationSummary ? _self.locationSummary : locationSummary // ignore: cast_nullable_to_non_nullable
as String?,totalCost: null == totalCost ? _self.totalCost : totalCost // ignore: cast_nullable_to_non_nullable
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
