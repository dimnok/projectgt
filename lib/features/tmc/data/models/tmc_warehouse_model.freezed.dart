// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tmc_warehouse_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TmcWarehouseModel {

 String get id; String get companyId; String get name; String? get address; String? get description; bool get isArchived; DateTime? get archivedAt; bool get isMain; bool get isSystem; DateTime? get createdAt; DateTime? get updatedAt; String? get createdBy;
/// Create a copy of TmcWarehouseModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TmcWarehouseModelCopyWith<TmcWarehouseModel> get copyWith => _$TmcWarehouseModelCopyWithImpl<TmcWarehouseModel>(this as TmcWarehouseModel, _$identity);

  /// Serializes this TmcWarehouseModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TmcWarehouseModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address)&&(identical(other.description, description) || other.description == description)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.isMain, isMain) || other.isMain == isMain)&&(identical(other.isSystem, isSystem) || other.isSystem == isSystem)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,name,address,description,isArchived,archivedAt,isMain,isSystem,createdAt,updatedAt,createdBy);

@override
String toString() {
  return 'TmcWarehouseModel(id: $id, companyId: $companyId, name: $name, address: $address, description: $description, isArchived: $isArchived, archivedAt: $archivedAt, isMain: $isMain, isSystem: $isSystem, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class $TmcWarehouseModelCopyWith<$Res>  {
  factory $TmcWarehouseModelCopyWith(TmcWarehouseModel value, $Res Function(TmcWarehouseModel) _then) = _$TmcWarehouseModelCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String name, String? address, String? description, bool isArchived, DateTime? archivedAt, bool isMain, bool isSystem, DateTime? createdAt, DateTime? updatedAt, String? createdBy
});




}
/// @nodoc
class _$TmcWarehouseModelCopyWithImpl<$Res>
    implements $TmcWarehouseModelCopyWith<$Res> {
  _$TmcWarehouseModelCopyWithImpl(this._self, this._then);

  final TmcWarehouseModel _self;
  final $Res Function(TmcWarehouseModel) _then;

/// Create a copy of TmcWarehouseModel
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

@JsonSerializable(fieldRename: FieldRename.snake)
class _TmcWarehouseModel extends TmcWarehouseModel {
  const _TmcWarehouseModel({required this.id, required this.companyId, required this.name, this.address, this.description, this.isArchived = false, this.archivedAt, this.isMain = false, this.isSystem = false, this.createdAt, this.updatedAt, this.createdBy}): super._();
  factory _TmcWarehouseModel.fromJson(Map<String, dynamic> json) => _$TmcWarehouseModelFromJson(json);

@override final  String id;
@override final  String companyId;
@override final  String name;
@override final  String? address;
@override final  String? description;
@override@JsonKey() final  bool isArchived;
@override final  DateTime? archivedAt;
@override@JsonKey() final  bool isMain;
@override@JsonKey() final  bool isSystem;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;
@override final  String? createdBy;

/// Create a copy of TmcWarehouseModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TmcWarehouseModelCopyWith<_TmcWarehouseModel> get copyWith => __$TmcWarehouseModelCopyWithImpl<_TmcWarehouseModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TmcWarehouseModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TmcWarehouseModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address)&&(identical(other.description, description) || other.description == description)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.isMain, isMain) || other.isMain == isMain)&&(identical(other.isSystem, isSystem) || other.isSystem == isSystem)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,name,address,description,isArchived,archivedAt,isMain,isSystem,createdAt,updatedAt,createdBy);

@override
String toString() {
  return 'TmcWarehouseModel(id: $id, companyId: $companyId, name: $name, address: $address, description: $description, isArchived: $isArchived, archivedAt: $archivedAt, isMain: $isMain, isSystem: $isSystem, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class _$TmcWarehouseModelCopyWith<$Res> implements $TmcWarehouseModelCopyWith<$Res> {
  factory _$TmcWarehouseModelCopyWith(_TmcWarehouseModel value, $Res Function(_TmcWarehouseModel) _then) = __$TmcWarehouseModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String name, String? address, String? description, bool isArchived, DateTime? archivedAt, bool isMain, bool isSystem, DateTime? createdAt, DateTime? updatedAt, String? createdBy
});




}
/// @nodoc
class __$TmcWarehouseModelCopyWithImpl<$Res>
    implements _$TmcWarehouseModelCopyWith<$Res> {
  __$TmcWarehouseModelCopyWithImpl(this._self, this._then);

  final _TmcWarehouseModel _self;
  final $Res Function(_TmcWarehouseModel) _then;

/// Create a copy of TmcWarehouseModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? name = null,Object? address = freezed,Object? description = freezed,Object? isArchived = null,Object? archivedAt = freezed,Object? isMain = null,Object? isSystem = null,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,}) {
  return _then(_TmcWarehouseModel(
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
