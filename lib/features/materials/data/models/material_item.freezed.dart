// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'material_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MaterialItem {

/// Идентификатор записи (UUID)
 String get id;/// Наименование материала
 String get name;/// ID компании (Multi-tenancy)
 String get companyId;/// Единица измерения, например: шт, м, т, м³
 String? get unit;/// Количество
 double? get quantity;/// Цена за единицу
 double? get price;/// Итоговая стоимость (computed в БД)
 double? get total;/// Номер расходной накладной
 String? get receiptNumber;/// Дата расходной накладной
 DateTime? get receiptDate;/// Использовано
 double? get used;/// Остаток
 double? get remaining;/// URL файла (накладная/скан)
 String? get fileUrl;/// Список ID сметных позиций, к которым привязан материал
 List<String> get estimateIds;
/// Create a copy of MaterialItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MaterialItemCopyWith<MaterialItem> get copyWith => _$MaterialItemCopyWithImpl<MaterialItem>(this as MaterialItem, _$identity);

  /// Serializes this MaterialItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MaterialItem&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.price, price) || other.price == price)&&(identical(other.total, total) || other.total == total)&&(identical(other.receiptNumber, receiptNumber) || other.receiptNumber == receiptNumber)&&(identical(other.receiptDate, receiptDate) || other.receiptDate == receiptDate)&&(identical(other.used, used) || other.used == used)&&(identical(other.remaining, remaining) || other.remaining == remaining)&&(identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl)&&const DeepCollectionEquality().equals(other.estimateIds, estimateIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,companyId,unit,quantity,price,total,receiptNumber,receiptDate,used,remaining,fileUrl,const DeepCollectionEquality().hash(estimateIds));

@override
String toString() {
  return 'MaterialItem(id: $id, name: $name, companyId: $companyId, unit: $unit, quantity: $quantity, price: $price, total: $total, receiptNumber: $receiptNumber, receiptDate: $receiptDate, used: $used, remaining: $remaining, fileUrl: $fileUrl, estimateIds: $estimateIds)';
}


}

/// @nodoc
abstract mixin class $MaterialItemCopyWith<$Res>  {
  factory $MaterialItemCopyWith(MaterialItem value, $Res Function(MaterialItem) _then) = _$MaterialItemCopyWithImpl;
@useResult
$Res call({
 String id, String name, String companyId, String? unit, double? quantity, double? price, double? total, String? receiptNumber, DateTime? receiptDate, double? used, double? remaining, String? fileUrl, List<String> estimateIds
});




}
/// @nodoc
class _$MaterialItemCopyWithImpl<$Res>
    implements $MaterialItemCopyWith<$Res> {
  _$MaterialItemCopyWithImpl(this._self, this._then);

  final MaterialItem _self;
  final $Res Function(MaterialItem) _then;

/// Create a copy of MaterialItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? companyId = null,Object? unit = freezed,Object? quantity = freezed,Object? price = freezed,Object? total = freezed,Object? receiptNumber = freezed,Object? receiptDate = freezed,Object? used = freezed,Object? remaining = freezed,Object? fileUrl = freezed,Object? estimateIds = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double?,price: freezed == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double?,total: freezed == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as double?,receiptNumber: freezed == receiptNumber ? _self.receiptNumber : receiptNumber // ignore: cast_nullable_to_non_nullable
as String?,receiptDate: freezed == receiptDate ? _self.receiptDate : receiptDate // ignore: cast_nullable_to_non_nullable
as DateTime?,used: freezed == used ? _self.used : used // ignore: cast_nullable_to_non_nullable
as double?,remaining: freezed == remaining ? _self.remaining : remaining // ignore: cast_nullable_to_non_nullable
as double?,fileUrl: freezed == fileUrl ? _self.fileUrl : fileUrl // ignore: cast_nullable_to_non_nullable
as String?,estimateIds: null == estimateIds ? _self.estimateIds : estimateIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _MaterialItem implements MaterialItem {
  const _MaterialItem({required this.id, required this.name, required this.companyId, this.unit, this.quantity, this.price, this.total, this.receiptNumber, this.receiptDate, this.used, this.remaining, this.fileUrl, final  List<String> estimateIds = const []}): _estimateIds = estimateIds;
  factory _MaterialItem.fromJson(Map<String, dynamic> json) => _$MaterialItemFromJson(json);

/// Идентификатор записи (UUID)
@override final  String id;
/// Наименование материала
@override final  String name;
/// ID компании (Multi-tenancy)
@override final  String companyId;
/// Единица измерения, например: шт, м, т, м³
@override final  String? unit;
/// Количество
@override final  double? quantity;
/// Цена за единицу
@override final  double? price;
/// Итоговая стоимость (computed в БД)
@override final  double? total;
/// Номер расходной накладной
@override final  String? receiptNumber;
/// Дата расходной накладной
@override final  DateTime? receiptDate;
/// Использовано
@override final  double? used;
/// Остаток
@override final  double? remaining;
/// URL файла (накладная/скан)
@override final  String? fileUrl;
/// Список ID сметных позиций, к которым привязан материал
 final  List<String> _estimateIds;
/// Список ID сметных позиций, к которым привязан материал
@override@JsonKey() List<String> get estimateIds {
  if (_estimateIds is EqualUnmodifiableListView) return _estimateIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_estimateIds);
}


/// Create a copy of MaterialItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MaterialItemCopyWith<_MaterialItem> get copyWith => __$MaterialItemCopyWithImpl<_MaterialItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MaterialItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MaterialItem&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.price, price) || other.price == price)&&(identical(other.total, total) || other.total == total)&&(identical(other.receiptNumber, receiptNumber) || other.receiptNumber == receiptNumber)&&(identical(other.receiptDate, receiptDate) || other.receiptDate == receiptDate)&&(identical(other.used, used) || other.used == used)&&(identical(other.remaining, remaining) || other.remaining == remaining)&&(identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl)&&const DeepCollectionEquality().equals(other._estimateIds, _estimateIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,companyId,unit,quantity,price,total,receiptNumber,receiptDate,used,remaining,fileUrl,const DeepCollectionEquality().hash(_estimateIds));

@override
String toString() {
  return 'MaterialItem(id: $id, name: $name, companyId: $companyId, unit: $unit, quantity: $quantity, price: $price, total: $total, receiptNumber: $receiptNumber, receiptDate: $receiptDate, used: $used, remaining: $remaining, fileUrl: $fileUrl, estimateIds: $estimateIds)';
}


}

/// @nodoc
abstract mixin class _$MaterialItemCopyWith<$Res> implements $MaterialItemCopyWith<$Res> {
  factory _$MaterialItemCopyWith(_MaterialItem value, $Res Function(_MaterialItem) _then) = __$MaterialItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String companyId, String? unit, double? quantity, double? price, double? total, String? receiptNumber, DateTime? receiptDate, double? used, double? remaining, String? fileUrl, List<String> estimateIds
});




}
/// @nodoc
class __$MaterialItemCopyWithImpl<$Res>
    implements _$MaterialItemCopyWith<$Res> {
  __$MaterialItemCopyWithImpl(this._self, this._then);

  final _MaterialItem _self;
  final $Res Function(_MaterialItem) _then;

/// Create a copy of MaterialItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? companyId = null,Object? unit = freezed,Object? quantity = freezed,Object? price = freezed,Object? total = freezed,Object? receiptNumber = freezed,Object? receiptDate = freezed,Object? used = freezed,Object? remaining = freezed,Object? fileUrl = freezed,Object? estimateIds = null,}) {
  return _then(_MaterialItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double?,price: freezed == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double?,total: freezed == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as double?,receiptNumber: freezed == receiptNumber ? _self.receiptNumber : receiptNumber // ignore: cast_nullable_to_non_nullable
as String?,receiptDate: freezed == receiptDate ? _self.receiptDate : receiptDate // ignore: cast_nullable_to_non_nullable
as DateTime?,used: freezed == used ? _self.used : used // ignore: cast_nullable_to_non_nullable
as double?,remaining: freezed == remaining ? _self.remaining : remaining // ignore: cast_nullable_to_non_nullable
as double?,fileUrl: freezed == fileUrl ? _self.fileUrl : fileUrl // ignore: cast_nullable_to_non_nullable
as String?,estimateIds: null == estimateIds ? _self._estimateIds : estimateIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
