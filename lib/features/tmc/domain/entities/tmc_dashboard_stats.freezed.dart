// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tmc_dashboard_stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TmcDashboardStats {

/// Всего позиций каталога.
 int get totalItems;/// Всего единиц (без списанных).
 num get totalUnits;/// На складе.
 num get inStock;/// На объекте.
 num get onObject;/// Выдано.
 num get issued;/// В ремонте.
 int get inRepair;/// Требует ремонта.
 int get needsRepair;/// Утеряно.
 int get lost;/// Списано за текущий месяц.
 int get writtenOff;/// Общая стоимость (null, если нет права view_cost).
 double? get totalCost;
/// Create a copy of TmcDashboardStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TmcDashboardStatsCopyWith<TmcDashboardStats> get copyWith => _$TmcDashboardStatsCopyWithImpl<TmcDashboardStats>(this as TmcDashboardStats, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TmcDashboardStats&&(identical(other.totalItems, totalItems) || other.totalItems == totalItems)&&(identical(other.totalUnits, totalUnits) || other.totalUnits == totalUnits)&&(identical(other.inStock, inStock) || other.inStock == inStock)&&(identical(other.onObject, onObject) || other.onObject == onObject)&&(identical(other.issued, issued) || other.issued == issued)&&(identical(other.inRepair, inRepair) || other.inRepair == inRepair)&&(identical(other.needsRepair, needsRepair) || other.needsRepair == needsRepair)&&(identical(other.lost, lost) || other.lost == lost)&&(identical(other.writtenOff, writtenOff) || other.writtenOff == writtenOff)&&(identical(other.totalCost, totalCost) || other.totalCost == totalCost));
}


@override
int get hashCode => Object.hash(runtimeType,totalItems,totalUnits,inStock,onObject,issued,inRepair,needsRepair,lost,writtenOff,totalCost);

@override
String toString() {
  return 'TmcDashboardStats(totalItems: $totalItems, totalUnits: $totalUnits, inStock: $inStock, onObject: $onObject, issued: $issued, inRepair: $inRepair, needsRepair: $needsRepair, lost: $lost, writtenOff: $writtenOff, totalCost: $totalCost)';
}


}

/// @nodoc
abstract mixin class $TmcDashboardStatsCopyWith<$Res>  {
  factory $TmcDashboardStatsCopyWith(TmcDashboardStats value, $Res Function(TmcDashboardStats) _then) = _$TmcDashboardStatsCopyWithImpl;
@useResult
$Res call({
 int totalItems, num totalUnits, num inStock, num onObject, num issued, int inRepair, int needsRepair, int lost, int writtenOff, double? totalCost
});




}
/// @nodoc
class _$TmcDashboardStatsCopyWithImpl<$Res>
    implements $TmcDashboardStatsCopyWith<$Res> {
  _$TmcDashboardStatsCopyWithImpl(this._self, this._then);

  final TmcDashboardStats _self;
  final $Res Function(TmcDashboardStats) _then;

/// Create a copy of TmcDashboardStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalItems = null,Object? totalUnits = null,Object? inStock = null,Object? onObject = null,Object? issued = null,Object? inRepair = null,Object? needsRepair = null,Object? lost = null,Object? writtenOff = null,Object? totalCost = freezed,}) {
  return _then(_self.copyWith(
totalItems: null == totalItems ? _self.totalItems : totalItems // ignore: cast_nullable_to_non_nullable
as int,totalUnits: null == totalUnits ? _self.totalUnits : totalUnits // ignore: cast_nullable_to_non_nullable
as num,inStock: null == inStock ? _self.inStock : inStock // ignore: cast_nullable_to_non_nullable
as num,onObject: null == onObject ? _self.onObject : onObject // ignore: cast_nullable_to_non_nullable
as num,issued: null == issued ? _self.issued : issued // ignore: cast_nullable_to_non_nullable
as num,inRepair: null == inRepair ? _self.inRepair : inRepair // ignore: cast_nullable_to_non_nullable
as int,needsRepair: null == needsRepair ? _self.needsRepair : needsRepair // ignore: cast_nullable_to_non_nullable
as int,lost: null == lost ? _self.lost : lost // ignore: cast_nullable_to_non_nullable
as int,writtenOff: null == writtenOff ? _self.writtenOff : writtenOff // ignore: cast_nullable_to_non_nullable
as int,totalCost: freezed == totalCost ? _self.totalCost : totalCost // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// @nodoc


class _TmcDashboardStats implements TmcDashboardStats {
  const _TmcDashboardStats({this.totalItems = 0, this.totalUnits = 0, this.inStock = 0, this.onObject = 0, this.issued = 0, this.inRepair = 0, this.needsRepair = 0, this.lost = 0, this.writtenOff = 0, this.totalCost});
  

/// Всего позиций каталога.
@override@JsonKey() final  int totalItems;
/// Всего единиц (без списанных).
@override@JsonKey() final  num totalUnits;
/// На складе.
@override@JsonKey() final  num inStock;
/// На объекте.
@override@JsonKey() final  num onObject;
/// Выдано.
@override@JsonKey() final  num issued;
/// В ремонте.
@override@JsonKey() final  int inRepair;
/// Требует ремонта.
@override@JsonKey() final  int needsRepair;
/// Утеряно.
@override@JsonKey() final  int lost;
/// Списано за текущий месяц.
@override@JsonKey() final  int writtenOff;
/// Общая стоимость (null, если нет права view_cost).
@override final  double? totalCost;

/// Create a copy of TmcDashboardStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TmcDashboardStatsCopyWith<_TmcDashboardStats> get copyWith => __$TmcDashboardStatsCopyWithImpl<_TmcDashboardStats>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TmcDashboardStats&&(identical(other.totalItems, totalItems) || other.totalItems == totalItems)&&(identical(other.totalUnits, totalUnits) || other.totalUnits == totalUnits)&&(identical(other.inStock, inStock) || other.inStock == inStock)&&(identical(other.onObject, onObject) || other.onObject == onObject)&&(identical(other.issued, issued) || other.issued == issued)&&(identical(other.inRepair, inRepair) || other.inRepair == inRepair)&&(identical(other.needsRepair, needsRepair) || other.needsRepair == needsRepair)&&(identical(other.lost, lost) || other.lost == lost)&&(identical(other.writtenOff, writtenOff) || other.writtenOff == writtenOff)&&(identical(other.totalCost, totalCost) || other.totalCost == totalCost));
}


@override
int get hashCode => Object.hash(runtimeType,totalItems,totalUnits,inStock,onObject,issued,inRepair,needsRepair,lost,writtenOff,totalCost);

@override
String toString() {
  return 'TmcDashboardStats(totalItems: $totalItems, totalUnits: $totalUnits, inStock: $inStock, onObject: $onObject, issued: $issued, inRepair: $inRepair, needsRepair: $needsRepair, lost: $lost, writtenOff: $writtenOff, totalCost: $totalCost)';
}


}

/// @nodoc
abstract mixin class _$TmcDashboardStatsCopyWith<$Res> implements $TmcDashboardStatsCopyWith<$Res> {
  factory _$TmcDashboardStatsCopyWith(_TmcDashboardStats value, $Res Function(_TmcDashboardStats) _then) = __$TmcDashboardStatsCopyWithImpl;
@override @useResult
$Res call({
 int totalItems, num totalUnits, num inStock, num onObject, num issued, int inRepair, int needsRepair, int lost, int writtenOff, double? totalCost
});




}
/// @nodoc
class __$TmcDashboardStatsCopyWithImpl<$Res>
    implements _$TmcDashboardStatsCopyWith<$Res> {
  __$TmcDashboardStatsCopyWithImpl(this._self, this._then);

  final _TmcDashboardStats _self;
  final $Res Function(_TmcDashboardStats) _then;

/// Create a copy of TmcDashboardStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalItems = null,Object? totalUnits = null,Object? inStock = null,Object? onObject = null,Object? issued = null,Object? inRepair = null,Object? needsRepair = null,Object? lost = null,Object? writtenOff = null,Object? totalCost = freezed,}) {
  return _then(_TmcDashboardStats(
totalItems: null == totalItems ? _self.totalItems : totalItems // ignore: cast_nullable_to_non_nullable
as int,totalUnits: null == totalUnits ? _self.totalUnits : totalUnits // ignore: cast_nullable_to_non_nullable
as num,inStock: null == inStock ? _self.inStock : inStock // ignore: cast_nullable_to_non_nullable
as num,onObject: null == onObject ? _self.onObject : onObject // ignore: cast_nullable_to_non_nullable
as num,issued: null == issued ? _self.issued : issued // ignore: cast_nullable_to_non_nullable
as num,inRepair: null == inRepair ? _self.inRepair : inRepair // ignore: cast_nullable_to_non_nullable
as int,needsRepair: null == needsRepair ? _self.needsRepair : needsRepair // ignore: cast_nullable_to_non_nullable
as int,lost: null == lost ? _self.lost : lost // ignore: cast_nullable_to_non_nullable
as int,writtenOff: null == writtenOff ? _self.writtenOff : writtenOff // ignore: cast_nullable_to_non_nullable
as int,totalCost: freezed == totalCost ? _self.totalCost : totalCost // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
