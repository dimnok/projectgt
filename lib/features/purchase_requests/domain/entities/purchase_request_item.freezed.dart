// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'purchase_request_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PurchaseRequestItem {

 String get id; String get requestId; String get name; double get quantity; String get unit; String? get article; String? get comment; int get sortOrder; DateTime? get createdAt;
/// Create a copy of PurchaseRequestItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PurchaseRequestItemCopyWith<PurchaseRequestItem> get copyWith => _$PurchaseRequestItemCopyWithImpl<PurchaseRequestItem>(this as PurchaseRequestItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PurchaseRequestItem&&(identical(other.id, id) || other.id == id)&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.name, name) || other.name == name)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.article, article) || other.article == article)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,requestId,name,quantity,unit,article,comment,sortOrder,createdAt);

@override
String toString() {
  return 'PurchaseRequestItem(id: $id, requestId: $requestId, name: $name, quantity: $quantity, unit: $unit, article: $article, comment: $comment, sortOrder: $sortOrder, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $PurchaseRequestItemCopyWith<$Res>  {
  factory $PurchaseRequestItemCopyWith(PurchaseRequestItem value, $Res Function(PurchaseRequestItem) _then) = _$PurchaseRequestItemCopyWithImpl;
@useResult
$Res call({
 String id, String requestId, String name, double quantity, String unit, String? article, String? comment, int sortOrder, DateTime? createdAt
});




}
/// @nodoc
class _$PurchaseRequestItemCopyWithImpl<$Res>
    implements $PurchaseRequestItemCopyWith<$Res> {
  _$PurchaseRequestItemCopyWithImpl(this._self, this._then);

  final PurchaseRequestItem _self;
  final $Res Function(PurchaseRequestItem) _then;

/// Create a copy of PurchaseRequestItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? requestId = null,Object? name = null,Object? quantity = null,Object? unit = null,Object? article = freezed,Object? comment = freezed,Object? sortOrder = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,article: freezed == article ? _self.article : article // ignore: cast_nullable_to_non_nullable
as String?,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc


class _PurchaseRequestItem implements PurchaseRequestItem {
  const _PurchaseRequestItem({required this.id, required this.requestId, required this.name, required this.quantity, this.unit = 'шт', this.article, this.comment, this.sortOrder = 0, this.createdAt});
  

@override final  String id;
@override final  String requestId;
@override final  String name;
@override final  double quantity;
@override@JsonKey() final  String unit;
@override final  String? article;
@override final  String? comment;
@override@JsonKey() final  int sortOrder;
@override final  DateTime? createdAt;

/// Create a copy of PurchaseRequestItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PurchaseRequestItemCopyWith<_PurchaseRequestItem> get copyWith => __$PurchaseRequestItemCopyWithImpl<_PurchaseRequestItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PurchaseRequestItem&&(identical(other.id, id) || other.id == id)&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.name, name) || other.name == name)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.article, article) || other.article == article)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,requestId,name,quantity,unit,article,comment,sortOrder,createdAt);

@override
String toString() {
  return 'PurchaseRequestItem(id: $id, requestId: $requestId, name: $name, quantity: $quantity, unit: $unit, article: $article, comment: $comment, sortOrder: $sortOrder, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$PurchaseRequestItemCopyWith<$Res> implements $PurchaseRequestItemCopyWith<$Res> {
  factory _$PurchaseRequestItemCopyWith(_PurchaseRequestItem value, $Res Function(_PurchaseRequestItem) _then) = __$PurchaseRequestItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String requestId, String name, double quantity, String unit, String? article, String? comment, int sortOrder, DateTime? createdAt
});




}
/// @nodoc
class __$PurchaseRequestItemCopyWithImpl<$Res>
    implements _$PurchaseRequestItemCopyWith<$Res> {
  __$PurchaseRequestItemCopyWithImpl(this._self, this._then);

  final _PurchaseRequestItem _self;
  final $Res Function(_PurchaseRequestItem) _then;

/// Create a copy of PurchaseRequestItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? requestId = null,Object? name = null,Object? quantity = null,Object? unit = null,Object? article = freezed,Object? comment = freezed,Object? sortOrder = null,Object? createdAt = freezed,}) {
  return _then(_PurchaseRequestItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,article: freezed == article ? _self.article : article // ignore: cast_nullable_to_non_nullable
as String?,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
