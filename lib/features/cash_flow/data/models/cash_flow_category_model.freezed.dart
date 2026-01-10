// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cash_flow_category_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CashFlowCategoryModel {

 String get id; String get companyId; String get name; CashFlowOperationType get type; DateTime? get createdAt;
/// Create a copy of CashFlowCategoryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CashFlowCategoryModelCopyWith<CashFlowCategoryModel> get copyWith => _$CashFlowCategoryModelCopyWithImpl<CashFlowCategoryModel>(this as CashFlowCategoryModel, _$identity);

  /// Serializes this CashFlowCategoryModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CashFlowCategoryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,name,type,createdAt);

@override
String toString() {
  return 'CashFlowCategoryModel(id: $id, companyId: $companyId, name: $name, type: $type, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $CashFlowCategoryModelCopyWith<$Res>  {
  factory $CashFlowCategoryModelCopyWith(CashFlowCategoryModel value, $Res Function(CashFlowCategoryModel) _then) = _$CashFlowCategoryModelCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String name, CashFlowOperationType type, DateTime? createdAt
});




}
/// @nodoc
class _$CashFlowCategoryModelCopyWithImpl<$Res>
    implements $CashFlowCategoryModelCopyWith<$Res> {
  _$CashFlowCategoryModelCopyWithImpl(this._self, this._then);

  final CashFlowCategoryModel _self;
  final $Res Function(CashFlowCategoryModel) _then;

/// Create a copy of CashFlowCategoryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? name = null,Object? type = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CashFlowOperationType,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _CashFlowCategoryModel extends CashFlowCategoryModel {
  const _CashFlowCategoryModel({required this.id, required this.companyId, required this.name, required this.type, this.createdAt}): super._();
  factory _CashFlowCategoryModel.fromJson(Map<String, dynamic> json) => _$CashFlowCategoryModelFromJson(json);

@override final  String id;
@override final  String companyId;
@override final  String name;
@override final  CashFlowOperationType type;
@override final  DateTime? createdAt;

/// Create a copy of CashFlowCategoryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CashFlowCategoryModelCopyWith<_CashFlowCategoryModel> get copyWith => __$CashFlowCategoryModelCopyWithImpl<_CashFlowCategoryModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CashFlowCategoryModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CashFlowCategoryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,name,type,createdAt);

@override
String toString() {
  return 'CashFlowCategoryModel(id: $id, companyId: $companyId, name: $name, type: $type, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$CashFlowCategoryModelCopyWith<$Res> implements $CashFlowCategoryModelCopyWith<$Res> {
  factory _$CashFlowCategoryModelCopyWith(_CashFlowCategoryModel value, $Res Function(_CashFlowCategoryModel) _then) = __$CashFlowCategoryModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String name, CashFlowOperationType type, DateTime? createdAt
});




}
/// @nodoc
class __$CashFlowCategoryModelCopyWithImpl<$Res>
    implements _$CashFlowCategoryModelCopyWith<$Res> {
  __$CashFlowCategoryModelCopyWithImpl(this._self, this._then);

  final _CashFlowCategoryModel _self;
  final $Res Function(_CashFlowCategoryModel) _then;

/// Create a copy of CashFlowCategoryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? name = null,Object? type = null,Object? createdAt = freezed,}) {
  return _then(_CashFlowCategoryModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CashFlowOperationType,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
