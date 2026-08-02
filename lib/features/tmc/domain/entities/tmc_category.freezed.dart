// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tmc_category.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TmcCategory {

/// Идентификатор записи.
 String get id;/// Компания-владелец.
 String get companyId;/// Родительская категория.
 String? get parentId;/// Наименование.
 String get name;/// Код категории.
 String? get code;/// Порядок сортировки.
 int get sortOrder;/// В архиве.
 bool get isArchived;/// Дата архивации.
 DateTime? get archivedAt;/// Дата создания.
 DateTime? get createdAt;/// Дата обновления.
 DateTime? get updatedAt;/// Автор создания.
 String? get createdBy;
/// Create a copy of TmcCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TmcCategoryCopyWith<TmcCategory> get copyWith => _$TmcCategoryCopyWithImpl<TmcCategory>(this as TmcCategory, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TmcCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.name, name) || other.name == name)&&(identical(other.code, code) || other.code == code)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,parentId,name,code,sortOrder,isArchived,archivedAt,createdAt,updatedAt,createdBy);

@override
String toString() {
  return 'TmcCategory(id: $id, companyId: $companyId, parentId: $parentId, name: $name, code: $code, sortOrder: $sortOrder, isArchived: $isArchived, archivedAt: $archivedAt, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class $TmcCategoryCopyWith<$Res>  {
  factory $TmcCategoryCopyWith(TmcCategory value, $Res Function(TmcCategory) _then) = _$TmcCategoryCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String? parentId, String name, String? code, int sortOrder, bool isArchived, DateTime? archivedAt, DateTime? createdAt, DateTime? updatedAt, String? createdBy
});




}
/// @nodoc
class _$TmcCategoryCopyWithImpl<$Res>
    implements $TmcCategoryCopyWith<$Res> {
  _$TmcCategoryCopyWithImpl(this._self, this._then);

  final TmcCategory _self;
  final $Res Function(TmcCategory) _then;

/// Create a copy of TmcCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? parentId = freezed,Object? name = null,Object? code = freezed,Object? sortOrder = null,Object? isArchived = null,Object? archivedAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc


class _TmcCategory implements TmcCategory {
  const _TmcCategory({required this.id, required this.companyId, this.parentId, required this.name, this.code, this.sortOrder = 0, this.isArchived = false, this.archivedAt, this.createdAt, this.updatedAt, this.createdBy});
  

/// Идентификатор записи.
@override final  String id;
/// Компания-владелец.
@override final  String companyId;
/// Родительская категория.
@override final  String? parentId;
/// Наименование.
@override final  String name;
/// Код категории.
@override final  String? code;
/// Порядок сортировки.
@override@JsonKey() final  int sortOrder;
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

/// Create a copy of TmcCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TmcCategoryCopyWith<_TmcCategory> get copyWith => __$TmcCategoryCopyWithImpl<_TmcCategory>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TmcCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.name, name) || other.name == name)&&(identical(other.code, code) || other.code == code)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,parentId,name,code,sortOrder,isArchived,archivedAt,createdAt,updatedAt,createdBy);

@override
String toString() {
  return 'TmcCategory(id: $id, companyId: $companyId, parentId: $parentId, name: $name, code: $code, sortOrder: $sortOrder, isArchived: $isArchived, archivedAt: $archivedAt, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class _$TmcCategoryCopyWith<$Res> implements $TmcCategoryCopyWith<$Res> {
  factory _$TmcCategoryCopyWith(_TmcCategory value, $Res Function(_TmcCategory) _then) = __$TmcCategoryCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String? parentId, String name, String? code, int sortOrder, bool isArchived, DateTime? archivedAt, DateTime? createdAt, DateTime? updatedAt, String? createdBy
});




}
/// @nodoc
class __$TmcCategoryCopyWithImpl<$Res>
    implements _$TmcCategoryCopyWith<$Res> {
  __$TmcCategoryCopyWithImpl(this._self, this._then);

  final _TmcCategory _self;
  final $Res Function(_TmcCategory) _then;

/// Create a copy of TmcCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? parentId = freezed,Object? name = null,Object? code = freezed,Object? sortOrder = null,Object? isArchived = null,Object? archivedAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,}) {
  return _then(_TmcCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
