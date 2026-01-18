// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'grouped_material_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GroupedMaterialItem {

/// ID сметной позиции
 String get estimateId;/// Каноническое наименование из сметы
 String get estimateName;/// Единица измерения из сметы
 String get estimateUnit;/// Система (ЭО1, СС и т.д.)
 String get system;/// Номер договора
 String get contractNumber;/// ID компании
 String get companyId;/// Общий приход (в единицах сметы)
 double get totalIncoming;/// Общий расход (в единицах сметы)
 double get totalUsed;/// Общий остаток (в единицах сметы)
 double get totalRemaining;/// Количество партий (накладных)
 int get batchCount;
/// Create a copy of GroupedMaterialItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupedMaterialItemCopyWith<GroupedMaterialItem> get copyWith => _$GroupedMaterialItemCopyWithImpl<GroupedMaterialItem>(this as GroupedMaterialItem, _$identity);

  /// Serializes this GroupedMaterialItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupedMaterialItem&&(identical(other.estimateId, estimateId) || other.estimateId == estimateId)&&(identical(other.estimateName, estimateName) || other.estimateName == estimateName)&&(identical(other.estimateUnit, estimateUnit) || other.estimateUnit == estimateUnit)&&(identical(other.system, system) || other.system == system)&&(identical(other.contractNumber, contractNumber) || other.contractNumber == contractNumber)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.totalIncoming, totalIncoming) || other.totalIncoming == totalIncoming)&&(identical(other.totalUsed, totalUsed) || other.totalUsed == totalUsed)&&(identical(other.totalRemaining, totalRemaining) || other.totalRemaining == totalRemaining)&&(identical(other.batchCount, batchCount) || other.batchCount == batchCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,estimateId,estimateName,estimateUnit,system,contractNumber,companyId,totalIncoming,totalUsed,totalRemaining,batchCount);

@override
String toString() {
  return 'GroupedMaterialItem(estimateId: $estimateId, estimateName: $estimateName, estimateUnit: $estimateUnit, system: $system, contractNumber: $contractNumber, companyId: $companyId, totalIncoming: $totalIncoming, totalUsed: $totalUsed, totalRemaining: $totalRemaining, batchCount: $batchCount)';
}


}

/// @nodoc
abstract mixin class $GroupedMaterialItemCopyWith<$Res>  {
  factory $GroupedMaterialItemCopyWith(GroupedMaterialItem value, $Res Function(GroupedMaterialItem) _then) = _$GroupedMaterialItemCopyWithImpl;
@useResult
$Res call({
 String estimateId, String estimateName, String estimateUnit, String system, String contractNumber, String companyId, double totalIncoming, double totalUsed, double totalRemaining, int batchCount
});




}
/// @nodoc
class _$GroupedMaterialItemCopyWithImpl<$Res>
    implements $GroupedMaterialItemCopyWith<$Res> {
  _$GroupedMaterialItemCopyWithImpl(this._self, this._then);

  final GroupedMaterialItem _self;
  final $Res Function(GroupedMaterialItem) _then;

/// Create a copy of GroupedMaterialItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? estimateId = null,Object? estimateName = null,Object? estimateUnit = null,Object? system = null,Object? contractNumber = null,Object? companyId = null,Object? totalIncoming = null,Object? totalUsed = null,Object? totalRemaining = null,Object? batchCount = null,}) {
  return _then(_self.copyWith(
estimateId: null == estimateId ? _self.estimateId : estimateId // ignore: cast_nullable_to_non_nullable
as String,estimateName: null == estimateName ? _self.estimateName : estimateName // ignore: cast_nullable_to_non_nullable
as String,estimateUnit: null == estimateUnit ? _self.estimateUnit : estimateUnit // ignore: cast_nullable_to_non_nullable
as String,system: null == system ? _self.system : system // ignore: cast_nullable_to_non_nullable
as String,contractNumber: null == contractNumber ? _self.contractNumber : contractNumber // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,totalIncoming: null == totalIncoming ? _self.totalIncoming : totalIncoming // ignore: cast_nullable_to_non_nullable
as double,totalUsed: null == totalUsed ? _self.totalUsed : totalUsed // ignore: cast_nullable_to_non_nullable
as double,totalRemaining: null == totalRemaining ? _self.totalRemaining : totalRemaining // ignore: cast_nullable_to_non_nullable
as double,batchCount: null == batchCount ? _self.batchCount : batchCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _GroupedMaterialItem implements GroupedMaterialItem {
  const _GroupedMaterialItem({required this.estimateId, required this.estimateName, required this.estimateUnit, required this.system, required this.contractNumber, required this.companyId, required this.totalIncoming, required this.totalUsed, required this.totalRemaining, required this.batchCount});
  factory _GroupedMaterialItem.fromJson(Map<String, dynamic> json) => _$GroupedMaterialItemFromJson(json);

/// ID сметной позиции
@override final  String estimateId;
/// Каноническое наименование из сметы
@override final  String estimateName;
/// Единица измерения из сметы
@override final  String estimateUnit;
/// Система (ЭО1, СС и т.д.)
@override final  String system;
/// Номер договора
@override final  String contractNumber;
/// ID компании
@override final  String companyId;
/// Общий приход (в единицах сметы)
@override final  double totalIncoming;
/// Общий расход (в единицах сметы)
@override final  double totalUsed;
/// Общий остаток (в единицах сметы)
@override final  double totalRemaining;
/// Количество партий (накладных)
@override final  int batchCount;

/// Create a copy of GroupedMaterialItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupedMaterialItemCopyWith<_GroupedMaterialItem> get copyWith => __$GroupedMaterialItemCopyWithImpl<_GroupedMaterialItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroupedMaterialItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupedMaterialItem&&(identical(other.estimateId, estimateId) || other.estimateId == estimateId)&&(identical(other.estimateName, estimateName) || other.estimateName == estimateName)&&(identical(other.estimateUnit, estimateUnit) || other.estimateUnit == estimateUnit)&&(identical(other.system, system) || other.system == system)&&(identical(other.contractNumber, contractNumber) || other.contractNumber == contractNumber)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.totalIncoming, totalIncoming) || other.totalIncoming == totalIncoming)&&(identical(other.totalUsed, totalUsed) || other.totalUsed == totalUsed)&&(identical(other.totalRemaining, totalRemaining) || other.totalRemaining == totalRemaining)&&(identical(other.batchCount, batchCount) || other.batchCount == batchCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,estimateId,estimateName,estimateUnit,system,contractNumber,companyId,totalIncoming,totalUsed,totalRemaining,batchCount);

@override
String toString() {
  return 'GroupedMaterialItem(estimateId: $estimateId, estimateName: $estimateName, estimateUnit: $estimateUnit, system: $system, contractNumber: $contractNumber, companyId: $companyId, totalIncoming: $totalIncoming, totalUsed: $totalUsed, totalRemaining: $totalRemaining, batchCount: $batchCount)';
}


}

/// @nodoc
abstract mixin class _$GroupedMaterialItemCopyWith<$Res> implements $GroupedMaterialItemCopyWith<$Res> {
  factory _$GroupedMaterialItemCopyWith(_GroupedMaterialItem value, $Res Function(_GroupedMaterialItem) _then) = __$GroupedMaterialItemCopyWithImpl;
@override @useResult
$Res call({
 String estimateId, String estimateName, String estimateUnit, String system, String contractNumber, String companyId, double totalIncoming, double totalUsed, double totalRemaining, int batchCount
});




}
/// @nodoc
class __$GroupedMaterialItemCopyWithImpl<$Res>
    implements _$GroupedMaterialItemCopyWith<$Res> {
  __$GroupedMaterialItemCopyWithImpl(this._self, this._then);

  final _GroupedMaterialItem _self;
  final $Res Function(_GroupedMaterialItem) _then;

/// Create a copy of GroupedMaterialItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? estimateId = null,Object? estimateName = null,Object? estimateUnit = null,Object? system = null,Object? contractNumber = null,Object? companyId = null,Object? totalIncoming = null,Object? totalUsed = null,Object? totalRemaining = null,Object? batchCount = null,}) {
  return _then(_GroupedMaterialItem(
estimateId: null == estimateId ? _self.estimateId : estimateId // ignore: cast_nullable_to_non_nullable
as String,estimateName: null == estimateName ? _self.estimateName : estimateName // ignore: cast_nullable_to_non_nullable
as String,estimateUnit: null == estimateUnit ? _self.estimateUnit : estimateUnit // ignore: cast_nullable_to_non_nullable
as String,system: null == system ? _self.system : system // ignore: cast_nullable_to_non_nullable
as String,contractNumber: null == contractNumber ? _self.contractNumber : contractNumber // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,totalIncoming: null == totalIncoming ? _self.totalIncoming : totalIncoming // ignore: cast_nullable_to_non_nullable
as double,totalUsed: null == totalUsed ? _self.totalUsed : totalUsed // ignore: cast_nullable_to_non_nullable
as double,totalRemaining: null == totalRemaining ? _self.totalRemaining : totalRemaining // ignore: cast_nullable_to_non_nullable
as double,batchCount: null == batchCount ? _self.batchCount : batchCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
