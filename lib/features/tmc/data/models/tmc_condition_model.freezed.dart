// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tmc_condition_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TmcConditionModel {

 String get id; String get companyId; String get code; String get name; int get sortOrder; bool get isSystem; bool get isArchived; DateTime? get archivedAt; DateTime? get createdAt; DateTime? get updatedAt; String? get createdBy;
/// Create a copy of TmcConditionModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TmcConditionModelCopyWith<TmcConditionModel> get copyWith => _$TmcConditionModelCopyWithImpl<TmcConditionModel>(this as TmcConditionModel, _$identity);

  /// Serializes this TmcConditionModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TmcConditionModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.isSystem, isSystem) || other.isSystem == isSystem)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,code,name,sortOrder,isSystem,isArchived,archivedAt,createdAt,updatedAt,createdBy);

@override
String toString() {
  return 'TmcConditionModel(id: $id, companyId: $companyId, code: $code, name: $name, sortOrder: $sortOrder, isSystem: $isSystem, isArchived: $isArchived, archivedAt: $archivedAt, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class $TmcConditionModelCopyWith<$Res>  {
  factory $TmcConditionModelCopyWith(TmcConditionModel value, $Res Function(TmcConditionModel) _then) = _$TmcConditionModelCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String code, String name, int sortOrder, bool isSystem, bool isArchived, DateTime? archivedAt, DateTime? createdAt, DateTime? updatedAt, String? createdBy
});




}
/// @nodoc
class _$TmcConditionModelCopyWithImpl<$Res>
    implements $TmcConditionModelCopyWith<$Res> {
  _$TmcConditionModelCopyWithImpl(this._self, this._then);

  final TmcConditionModel _self;
  final $Res Function(TmcConditionModel) _then;

/// Create a copy of TmcConditionModel
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

@JsonSerializable(fieldRename: FieldRename.snake)
class _TmcConditionModel extends TmcConditionModel {
  const _TmcConditionModel({required this.id, required this.companyId, required this.code, required this.name, this.sortOrder = 0, this.isSystem = false, this.isArchived = false, this.archivedAt, this.createdAt, this.updatedAt, this.createdBy}): super._();
  factory _TmcConditionModel.fromJson(Map<String, dynamic> json) => _$TmcConditionModelFromJson(json);

@override final  String id;
@override final  String companyId;
@override final  String code;
@override final  String name;
@override@JsonKey() final  int sortOrder;
@override@JsonKey() final  bool isSystem;
@override@JsonKey() final  bool isArchived;
@override final  DateTime? archivedAt;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;
@override final  String? createdBy;

/// Create a copy of TmcConditionModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TmcConditionModelCopyWith<_TmcConditionModel> get copyWith => __$TmcConditionModelCopyWithImpl<_TmcConditionModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TmcConditionModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TmcConditionModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.isSystem, isSystem) || other.isSystem == isSystem)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,code,name,sortOrder,isSystem,isArchived,archivedAt,createdAt,updatedAt,createdBy);

@override
String toString() {
  return 'TmcConditionModel(id: $id, companyId: $companyId, code: $code, name: $name, sortOrder: $sortOrder, isSystem: $isSystem, isArchived: $isArchived, archivedAt: $archivedAt, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class _$TmcConditionModelCopyWith<$Res> implements $TmcConditionModelCopyWith<$Res> {
  factory _$TmcConditionModelCopyWith(_TmcConditionModel value, $Res Function(_TmcConditionModel) _then) = __$TmcConditionModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String code, String name, int sortOrder, bool isSystem, bool isArchived, DateTime? archivedAt, DateTime? createdAt, DateTime? updatedAt, String? createdBy
});




}
/// @nodoc
class __$TmcConditionModelCopyWithImpl<$Res>
    implements _$TmcConditionModelCopyWith<$Res> {
  __$TmcConditionModelCopyWithImpl(this._self, this._then);

  final _TmcConditionModel _self;
  final $Res Function(_TmcConditionModel) _then;

/// Create a copy of TmcConditionModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? code = null,Object? name = null,Object? sortOrder = null,Object? isSystem = null,Object? isArchived = null,Object? archivedAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,}) {
  return _then(_TmcConditionModel(
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
