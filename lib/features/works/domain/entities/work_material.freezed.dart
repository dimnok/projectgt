// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'work_material.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WorkMaterial {

/// Идентификатор материала.
 String get id;/// Идентификатор компании.
 String get companyId;/// Идентификатор смены.
 String get workId;/// Наименование материала.
 String get name;/// Единица измерения.
 String get unit;/// Количество.
 num get quantity;/// Комментарий к материалу.
 String? get comment;/// Дата создания записи.
 DateTime? get createdAt;/// Дата последнего обновления.
 DateTime? get updatedAt;
/// Create a copy of WorkMaterial
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkMaterialCopyWith<WorkMaterial> get copyWith => _$WorkMaterialCopyWithImpl<WorkMaterial>(this as WorkMaterial, _$identity);

  /// Serializes this WorkMaterial to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkMaterial&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.workId, workId) || other.workId == workId)&&(identical(other.name, name) || other.name == name)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,workId,name,unit,quantity,comment,createdAt,updatedAt);

@override
String toString() {
  return 'WorkMaterial(id: $id, companyId: $companyId, workId: $workId, name: $name, unit: $unit, quantity: $quantity, comment: $comment, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $WorkMaterialCopyWith<$Res>  {
  factory $WorkMaterialCopyWith(WorkMaterial value, $Res Function(WorkMaterial) _then) = _$WorkMaterialCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String workId, String name, String unit, num quantity, String? comment, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$WorkMaterialCopyWithImpl<$Res>
    implements $WorkMaterialCopyWith<$Res> {
  _$WorkMaterialCopyWithImpl(this._self, this._then);

  final WorkMaterial _self;
  final $Res Function(WorkMaterial) _then;

/// Create a copy of WorkMaterial
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? workId = null,Object? name = null,Object? unit = null,Object? quantity = null,Object? comment = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,workId: null == workId ? _self.workId : workId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as num,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _WorkMaterial implements WorkMaterial {
  const _WorkMaterial({required this.id, required this.companyId, required this.workId, required this.name, required this.unit, required this.quantity, this.comment, this.createdAt, this.updatedAt});
  factory _WorkMaterial.fromJson(Map<String, dynamic> json) => _$WorkMaterialFromJson(json);

/// Идентификатор материала.
@override final  String id;
/// Идентификатор компании.
@override final  String companyId;
/// Идентификатор смены.
@override final  String workId;
/// Наименование материала.
@override final  String name;
/// Единица измерения.
@override final  String unit;
/// Количество.
@override final  num quantity;
/// Комментарий к материалу.
@override final  String? comment;
/// Дата создания записи.
@override final  DateTime? createdAt;
/// Дата последнего обновления.
@override final  DateTime? updatedAt;

/// Create a copy of WorkMaterial
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkMaterialCopyWith<_WorkMaterial> get copyWith => __$WorkMaterialCopyWithImpl<_WorkMaterial>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkMaterialToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkMaterial&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.workId, workId) || other.workId == workId)&&(identical(other.name, name) || other.name == name)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,workId,name,unit,quantity,comment,createdAt,updatedAt);

@override
String toString() {
  return 'WorkMaterial(id: $id, companyId: $companyId, workId: $workId, name: $name, unit: $unit, quantity: $quantity, comment: $comment, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$WorkMaterialCopyWith<$Res> implements $WorkMaterialCopyWith<$Res> {
  factory _$WorkMaterialCopyWith(_WorkMaterial value, $Res Function(_WorkMaterial) _then) = __$WorkMaterialCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String workId, String name, String unit, num quantity, String? comment, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$WorkMaterialCopyWithImpl<$Res>
    implements _$WorkMaterialCopyWith<$Res> {
  __$WorkMaterialCopyWithImpl(this._self, this._then);

  final _WorkMaterial _self;
  final $Res Function(_WorkMaterial) _then;

/// Create a copy of WorkMaterial
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? workId = null,Object? name = null,Object? unit = null,Object? quantity = null,Object? comment = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_WorkMaterial(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,workId: null == workId ? _self.workId : workId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as num,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
