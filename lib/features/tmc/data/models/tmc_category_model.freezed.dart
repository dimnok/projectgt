// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tmc_category_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TmcCategoryModel {

 String get id; String get companyId; String? get parentId; String get name; String? get code; int get sortOrder; bool get isArchived; DateTime? get archivedAt; DateTime? get createdAt; DateTime? get updatedAt; String? get createdBy;
/// Create a copy of TmcCategoryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TmcCategoryModelCopyWith<TmcCategoryModel> get copyWith => _$TmcCategoryModelCopyWithImpl<TmcCategoryModel>(this as TmcCategoryModel, _$identity);

  /// Serializes this TmcCategoryModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TmcCategoryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.name, name) || other.name == name)&&(identical(other.code, code) || other.code == code)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,parentId,name,code,sortOrder,isArchived,archivedAt,createdAt,updatedAt,createdBy);

@override
String toString() {
  return 'TmcCategoryModel(id: $id, companyId: $companyId, parentId: $parentId, name: $name, code: $code, sortOrder: $sortOrder, isArchived: $isArchived, archivedAt: $archivedAt, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class $TmcCategoryModelCopyWith<$Res>  {
  factory $TmcCategoryModelCopyWith(TmcCategoryModel value, $Res Function(TmcCategoryModel) _then) = _$TmcCategoryModelCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String? parentId, String name, String? code, int sortOrder, bool isArchived, DateTime? archivedAt, DateTime? createdAt, DateTime? updatedAt, String? createdBy
});




}
/// @nodoc
class _$TmcCategoryModelCopyWithImpl<$Res>
    implements $TmcCategoryModelCopyWith<$Res> {
  _$TmcCategoryModelCopyWithImpl(this._self, this._then);

  final TmcCategoryModel _self;
  final $Res Function(TmcCategoryModel) _then;

/// Create a copy of TmcCategoryModel
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

@JsonSerializable(fieldRename: FieldRename.snake)
class _TmcCategoryModel extends TmcCategoryModel {
  const _TmcCategoryModel({required this.id, required this.companyId, this.parentId, required this.name, this.code, this.sortOrder = 0, this.isArchived = false, this.archivedAt, this.createdAt, this.updatedAt, this.createdBy}): super._();
  factory _TmcCategoryModel.fromJson(Map<String, dynamic> json) => _$TmcCategoryModelFromJson(json);

@override final  String id;
@override final  String companyId;
@override final  String? parentId;
@override final  String name;
@override final  String? code;
@override@JsonKey() final  int sortOrder;
@override@JsonKey() final  bool isArchived;
@override final  DateTime? archivedAt;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;
@override final  String? createdBy;

/// Create a copy of TmcCategoryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TmcCategoryModelCopyWith<_TmcCategoryModel> get copyWith => __$TmcCategoryModelCopyWithImpl<_TmcCategoryModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TmcCategoryModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TmcCategoryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.name, name) || other.name == name)&&(identical(other.code, code) || other.code == code)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,parentId,name,code,sortOrder,isArchived,archivedAt,createdAt,updatedAt,createdBy);

@override
String toString() {
  return 'TmcCategoryModel(id: $id, companyId: $companyId, parentId: $parentId, name: $name, code: $code, sortOrder: $sortOrder, isArchived: $isArchived, archivedAt: $archivedAt, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class _$TmcCategoryModelCopyWith<$Res> implements $TmcCategoryModelCopyWith<$Res> {
  factory _$TmcCategoryModelCopyWith(_TmcCategoryModel value, $Res Function(_TmcCategoryModel) _then) = __$TmcCategoryModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String? parentId, String name, String? code, int sortOrder, bool isArchived, DateTime? archivedAt, DateTime? createdAt, DateTime? updatedAt, String? createdBy
});




}
/// @nodoc
class __$TmcCategoryModelCopyWithImpl<$Res>
    implements _$TmcCategoryModelCopyWith<$Res> {
  __$TmcCategoryModelCopyWithImpl(this._self, this._then);

  final _TmcCategoryModel _self;
  final $Res Function(_TmcCategoryModel) _then;

/// Create a copy of TmcCategoryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? parentId = freezed,Object? name = null,Object? code = freezed,Object? sortOrder = null,Object? isArchived = null,Object? archivedAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,}) {
  return _then(_TmcCategoryModel(
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
