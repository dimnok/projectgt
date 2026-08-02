// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tmc_dashboard_stats_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TmcDashboardStatsModel {

 int get totalItems; num get totalUnits; num get inStock; num get onObject; num get issued; int get inRepair; int get needsRepair; int get lost; int get writtenOff; double? get totalCost;
/// Create a copy of TmcDashboardStatsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TmcDashboardStatsModelCopyWith<TmcDashboardStatsModel> get copyWith => _$TmcDashboardStatsModelCopyWithImpl<TmcDashboardStatsModel>(this as TmcDashboardStatsModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TmcDashboardStatsModel&&(identical(other.totalItems, totalItems) || other.totalItems == totalItems)&&(identical(other.totalUnits, totalUnits) || other.totalUnits == totalUnits)&&(identical(other.inStock, inStock) || other.inStock == inStock)&&(identical(other.onObject, onObject) || other.onObject == onObject)&&(identical(other.issued, issued) || other.issued == issued)&&(identical(other.inRepair, inRepair) || other.inRepair == inRepair)&&(identical(other.needsRepair, needsRepair) || other.needsRepair == needsRepair)&&(identical(other.lost, lost) || other.lost == lost)&&(identical(other.writtenOff, writtenOff) || other.writtenOff == writtenOff)&&(identical(other.totalCost, totalCost) || other.totalCost == totalCost));
}


@override
int get hashCode => Object.hash(runtimeType,totalItems,totalUnits,inStock,onObject,issued,inRepair,needsRepair,lost,writtenOff,totalCost);

@override
String toString() {
  return 'TmcDashboardStatsModel(totalItems: $totalItems, totalUnits: $totalUnits, inStock: $inStock, onObject: $onObject, issued: $issued, inRepair: $inRepair, needsRepair: $needsRepair, lost: $lost, writtenOff: $writtenOff, totalCost: $totalCost)';
}


}

/// @nodoc
abstract mixin class $TmcDashboardStatsModelCopyWith<$Res>  {
  factory $TmcDashboardStatsModelCopyWith(TmcDashboardStatsModel value, $Res Function(TmcDashboardStatsModel) _then) = _$TmcDashboardStatsModelCopyWithImpl;
@useResult
$Res call({
 int totalItems, num totalUnits, num inStock, num onObject, num issued, int inRepair, int needsRepair, int lost, int writtenOff, double? totalCost
});




}
/// @nodoc
class _$TmcDashboardStatsModelCopyWithImpl<$Res>
    implements $TmcDashboardStatsModelCopyWith<$Res> {
  _$TmcDashboardStatsModelCopyWithImpl(this._self, this._then);

  final TmcDashboardStatsModel _self;
  final $Res Function(TmcDashboardStatsModel) _then;

/// Create a copy of TmcDashboardStatsModel
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


class _TmcDashboardStatsModel extends TmcDashboardStatsModel {
  const _TmcDashboardStatsModel({this.totalItems = 0, this.totalUnits = 0, this.inStock = 0, this.onObject = 0, this.issued = 0, this.inRepair = 0, this.needsRepair = 0, this.lost = 0, this.writtenOff = 0, this.totalCost}): super._();
  

@override@JsonKey() final  int totalItems;
@override@JsonKey() final  num totalUnits;
@override@JsonKey() final  num inStock;
@override@JsonKey() final  num onObject;
@override@JsonKey() final  num issued;
@override@JsonKey() final  int inRepair;
@override@JsonKey() final  int needsRepair;
@override@JsonKey() final  int lost;
@override@JsonKey() final  int writtenOff;
@override final  double? totalCost;

/// Create a copy of TmcDashboardStatsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TmcDashboardStatsModelCopyWith<_TmcDashboardStatsModel> get copyWith => __$TmcDashboardStatsModelCopyWithImpl<_TmcDashboardStatsModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TmcDashboardStatsModel&&(identical(other.totalItems, totalItems) || other.totalItems == totalItems)&&(identical(other.totalUnits, totalUnits) || other.totalUnits == totalUnits)&&(identical(other.inStock, inStock) || other.inStock == inStock)&&(identical(other.onObject, onObject) || other.onObject == onObject)&&(identical(other.issued, issued) || other.issued == issued)&&(identical(other.inRepair, inRepair) || other.inRepair == inRepair)&&(identical(other.needsRepair, needsRepair) || other.needsRepair == needsRepair)&&(identical(other.lost, lost) || other.lost == lost)&&(identical(other.writtenOff, writtenOff) || other.writtenOff == writtenOff)&&(identical(other.totalCost, totalCost) || other.totalCost == totalCost));
}


@override
int get hashCode => Object.hash(runtimeType,totalItems,totalUnits,inStock,onObject,issued,inRepair,needsRepair,lost,writtenOff,totalCost);

@override
String toString() {
  return 'TmcDashboardStatsModel(totalItems: $totalItems, totalUnits: $totalUnits, inStock: $inStock, onObject: $onObject, issued: $issued, inRepair: $inRepair, needsRepair: $needsRepair, lost: $lost, writtenOff: $writtenOff, totalCost: $totalCost)';
}


}

/// @nodoc
abstract mixin class _$TmcDashboardStatsModelCopyWith<$Res> implements $TmcDashboardStatsModelCopyWith<$Res> {
  factory _$TmcDashboardStatsModelCopyWith(_TmcDashboardStatsModel value, $Res Function(_TmcDashboardStatsModel) _then) = __$TmcDashboardStatsModelCopyWithImpl;
@override @useResult
$Res call({
 int totalItems, num totalUnits, num inStock, num onObject, num issued, int inRepair, int needsRepair, int lost, int writtenOff, double? totalCost
});




}
/// @nodoc
class __$TmcDashboardStatsModelCopyWithImpl<$Res>
    implements _$TmcDashboardStatsModelCopyWith<$Res> {
  __$TmcDashboardStatsModelCopyWithImpl(this._self, this._then);

  final _TmcDashboardStatsModel _self;
  final $Res Function(_TmcDashboardStatsModel) _then;

/// Create a copy of TmcDashboardStatsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalItems = null,Object? totalUnits = null,Object? inStock = null,Object? onObject = null,Object? issued = null,Object? inRepair = null,Object? needsRepair = null,Object? lost = null,Object? writtenOff = null,Object? totalCost = freezed,}) {
  return _then(_TmcDashboardStatsModel(
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
