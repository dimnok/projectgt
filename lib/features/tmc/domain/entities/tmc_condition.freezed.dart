// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tmc_condition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TmcCondition {

/// Идентификатор записи.
 String get id;/// Компания-владелец.
 String get companyId;/// Код состояния.
 String get code;/// Наименование.
 String get name;/// Порядок сортировки.
 int get sortOrder;/// Системное (предустановленное) состояние.
 bool get isSystem;/// В архиве.
 bool get isArchived;/// Дата архивации.
 DateTime? get archivedAt;/// Дата создания.
 DateTime? get createdAt;/// Дата обновления.
 DateTime? get updatedAt;/// Автор создания.
 String? get createdBy;
/// Create a copy of TmcCondition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TmcConditionCopyWith<TmcCondition> get copyWith => _$TmcConditionCopyWithImpl<TmcCondition>(this as TmcCondition, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TmcCondition&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.isSystem, isSystem) || other.isSystem == isSystem)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,code,name,sortOrder,isSystem,isArchived,archivedAt,createdAt,updatedAt,createdBy);

@override
String toString() {
  return 'TmcCondition(id: $id, companyId: $companyId, code: $code, name: $name, sortOrder: $sortOrder, isSystem: $isSystem, isArchived: $isArchived, archivedAt: $archivedAt, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class $TmcConditionCopyWith<$Res>  {
  factory $TmcConditionCopyWith(TmcCondition value, $Res Function(TmcCondition) _then) = _$TmcConditionCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String code, String name, int sortOrder, bool isSystem, bool isArchived, DateTime? archivedAt, DateTime? createdAt, DateTime? updatedAt, String? createdBy
});




}
/// @nodoc
class _$TmcConditionCopyWithImpl<$Res>
    implements $TmcConditionCopyWith<$Res> {
  _$TmcConditionCopyWithImpl(this._self, this._then);

  final TmcCondition _self;
  final $Res Function(TmcCondition) _then;

/// Create a copy of TmcCondition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? code = null,Object? name = null,Object? sortOrder = null,Object? isSystem = null,Object? isArchived = null,Object? archivedAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,isSystem: null == isSystem ? _self.isSystem : isSystem // ignore: cast_nullable_to_non_nullable
as bool,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc


class _TmcCondition implements TmcCondition {
  const _TmcCondition({required this.id, required this.companyId, required this.code, required this.name, this.sortOrder = 0, this.isSystem = false, this.isArchived = false, this.archivedAt, this.createdAt, this.updatedAt, this.createdBy});
  

/// Идентификатор записи.
@override final  String id;
/// Компания-владелец.
@override final  String companyId;
/// Код состояния.
@override final  String code;
/// Наименование.
@override final  String name;
/// Порядок сортировки.
@override@JsonKey() final  int sortOrder;
/// Системное (предустановленное) состояние.
@override@JsonKey() final  bool isSystem;
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

/// Create a copy of TmcCondition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TmcConditionCopyWith<_TmcCondition> get copyWith => __$TmcConditionCopyWithImpl<_TmcCondition>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TmcCondition&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.isSystem, isSystem) || other.isSystem == isSystem)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,code,name,sortOrder,isSystem,isArchived,archivedAt,createdAt,updatedAt,createdBy);

@override
String toString() {
  return 'TmcCondition(id: $id, companyId: $companyId, code: $code, name: $name, sortOrder: $sortOrder, isSystem: $isSystem, isArchived: $isArchived, archivedAt: $archivedAt, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class _$TmcConditionCopyWith<$Res> implements $TmcConditionCopyWith<$Res> {
  factory _$TmcConditionCopyWith(_TmcCondition value, $Res Function(_TmcCondition) _then) = __$TmcConditionCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String code, String name, int sortOrder, bool isSystem, bool isArchived, DateTime? archivedAt, DateTime? createdAt, DateTime? updatedAt, String? createdBy
});




}
/// @nodoc
class __$TmcConditionCopyWithImpl<$Res>
    implements _$TmcConditionCopyWith<$Res> {
  __$TmcConditionCopyWithImpl(this._self, this._then);

  final _TmcCondition _self;
  final $Res Function(_TmcCondition) _then;

/// Create a copy of TmcCondition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? code = null,Object? name = null,Object? sortOrder = null,Object? isSystem = null,Object? isArchived = null,Object? archivedAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,}) {
  return _then(_TmcCondition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,isSystem: null == isSystem ? _self.isSystem : isSystem // ignore: cast_nullable_to_non_nullable
as bool,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
