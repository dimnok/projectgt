// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tmc_warehouse.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TmcWarehouse {

/// Идентификатор записи.
 String get id;/// Компания-владелец.
 String get companyId;/// Наименование склада.
 String get name;/// Адрес.
 String? get address;/// Описание.
 String? get description;/// В архиве.
 bool get isArchived;/// Дата архивации.
 DateTime? get archivedAt;/// Основной склад компании.
 bool get isMain;/// Системный склад (нельзя удалить/переименовать).
 bool get isSystem;/// Дата создания.
 DateTime? get createdAt;/// Дата обновления.
 DateTime? get updatedAt;/// Автор создания.
 String? get createdBy;
/// Create a copy of TmcWarehouse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TmcWarehouseCopyWith<TmcWarehouse> get copyWith => _$TmcWarehouseCopyWithImpl<TmcWarehouse>(this as TmcWarehouse, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TmcWarehouse&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address)&&(identical(other.description, description) || other.description == description)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.isMain, isMain) || other.isMain == isMain)&&(identical(other.isSystem, isSystem) || other.isSystem == isSystem)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,name,address,description,isArchived,archivedAt,isMain,isSystem,createdAt,updatedAt,createdBy);

@override
String toString() {
  return 'TmcWarehouse(id: $id, companyId: $companyId, name: $name, address: $address, description: $description, isArchived: $isArchived, archivedAt: $archivedAt, isMain: $isMain, isSystem: $isSystem, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class $TmcWarehouseCopyWith<$Res>  {
  factory $TmcWarehouseCopyWith(TmcWarehouse value, $Res Function(TmcWarehouse) _then) = _$TmcWarehouseCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String name, String? address, String? description, bool isArchived, DateTime? archivedAt, bool isMain, bool isSystem, DateTime? createdAt, DateTime? updatedAt, String? createdBy
});




}
/// @nodoc
class _$TmcWarehouseCopyWithImpl<$Res>
    implements $TmcWarehouseCopyWith<$Res> {
  _$TmcWarehouseCopyWithImpl(this._self, this._then);

  final TmcWarehouse _self;
  final $Res Function(TmcWarehouse) _then;

/// Create a copy of TmcWarehouse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? name = null,Object? address = freezed,Object? description = freezed,Object? isArchived = null,Object? archivedAt = freezed,Object? isMain = null,Object? isSystem = null,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isMain: null == isMain ? _self.isMain : isMain // ignore: cast_nullable_to_non_nullable
as bool,isSystem: null == isSystem ? _self.isSystem : isSystem // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc


class _TmcWarehouse implements TmcWarehouse {
  const _TmcWarehouse({required this.id, required this.companyId, required this.name, this.address, this.description, this.isArchived = false, this.archivedAt, this.isMain = false, this.isSystem = false, this.createdAt, this.updatedAt, this.createdBy});
  

/// Идентификатор записи.
@override final  String id;
/// Компания-владелец.
@override final  String companyId;
/// Наименование склада.
@override final  String name;
/// Адрес.
@override final  String? address;
/// Описание.
@override final  String? description;
/// В архиве.
@override@JsonKey() final  bool isArchived;
/// Дата архивации.
@override final  DateTime? archivedAt;
/// Основной склад компании.
@override@JsonKey() final  bool isMain;
/// Системный склад (нельзя удалить/переименовать).
@override@JsonKey() final  bool isSystem;
/// Дата создания.
@override final  DateTime? createdAt;
/// Дата обновления.
@override final  DateTime? updatedAt;
/// Автор создания.
@override final  String? createdBy;

/// Create a copy of TmcWarehouse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TmcWarehouseCopyWith<_TmcWarehouse> get copyWith => __$TmcWarehouseCopyWithImpl<_TmcWarehouse>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TmcWarehouse&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address)&&(identical(other.description, description) || other.description == description)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.isMain, isMain) || other.isMain == isMain)&&(identical(other.isSystem, isSystem) || other.isSystem == isSystem)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,name,address,description,isArchived,archivedAt,isMain,isSystem,createdAt,updatedAt,createdBy);

@override
String toString() {
  return 'TmcWarehouse(id: $id, companyId: $companyId, name: $name, address: $address, description: $description, isArchived: $isArchived, archivedAt: $archivedAt, isMain: $isMain, isSystem: $isSystem, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class _$TmcWarehouseCopyWith<$Res> implements $TmcWarehouseCopyWith<$Res> {
  factory _$TmcWarehouseCopyWith(_TmcWarehouse value, $Res Function(_TmcWarehouse) _then) = __$TmcWarehouseCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String name, String? address, String? description, bool isArchived, DateTime? archivedAt, bool isMain, bool isSystem, DateTime? createdAt, DateTime? updatedAt, String? createdBy
});




}
/// @nodoc
class __$TmcWarehouseCopyWithImpl<$Res>
    implements _$TmcWarehouseCopyWith<$Res> {
  __$TmcWarehouseCopyWithImpl(this._self, this._then);

  final _TmcWarehouse _self;
  final $Res Function(_TmcWarehouse) _then;

/// Create a copy of TmcWarehouse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? name = null,Object? address = freezed,Object? description = freezed,Object? isArchived = null,Object? archivedAt = freezed,Object? isMain = null,Object? isSystem = null,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,}) {
  return _then(_TmcWarehouse(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isMain: null == isMain ? _self.isMain : isMain // ignore: cast_nullable_to_non_nullable
as bool,isSystem: null == isSystem ? _self.isSystem : isSystem // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
