// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'object_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ObjectModel {

 String get id; String get companyId; String get name; String get address; String? get description;
/// Create a copy of ObjectModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ObjectModelCopyWith<ObjectModel> get copyWith => _$ObjectModelCopyWithImpl<ObjectModel>(this as ObjectModel, _$identity);

  /// Serializes this ObjectModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ObjectModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,name,address,description);

@override
String toString() {
  return 'ObjectModel(id: $id, companyId: $companyId, name: $name, address: $address, description: $description)';
}


}

/// @nodoc
abstract mixin class $ObjectModelCopyWith<$Res>  {
  factory $ObjectModelCopyWith(ObjectModel value, $Res Function(ObjectModel) _then) = _$ObjectModelCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String name, String address, String? description
});




}
/// @nodoc
class _$ObjectModelCopyWithImpl<$Res>
    implements $ObjectModelCopyWith<$Res> {
  _$ObjectModelCopyWithImpl(this._self, this._then);

  final ObjectModel _self;
  final $Res Function(ObjectModel) _then;

/// Create a copy of ObjectModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? name = null,Object? address = null,Object? description = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class _ObjectModel extends ObjectModel {
  const _ObjectModel({required this.id, required this.companyId, required this.name, required this.address, this.description}): super._();
  factory _ObjectModel.fromJson(Map<String, dynamic> json) => _$ObjectModelFromJson(json);

@override final  String id;
@override final  String companyId;
@override final  String name;
@override final  String address;
@override final  String? description;

/// Create a copy of ObjectModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ObjectModelCopyWith<_ObjectModel> get copyWith => __$ObjectModelCopyWithImpl<_ObjectModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ObjectModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ObjectModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,name,address,description);

@override
String toString() {
  return 'ObjectModel(id: $id, companyId: $companyId, name: $name, address: $address, description: $description)';
}


}

/// @nodoc
abstract mixin class _$ObjectModelCopyWith<$Res> implements $ObjectModelCopyWith<$Res> {
  factory _$ObjectModelCopyWith(_ObjectModel value, $Res Function(_ObjectModel) _then) = __$ObjectModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String name, String address, String? description
});




}
/// @nodoc
class __$ObjectModelCopyWithImpl<$Res>
    implements _$ObjectModelCopyWith<$Res> {
  __$ObjectModelCopyWithImpl(this._self, this._then);

  final _ObjectModel _self;
  final $Res Function(_ObjectModel) _then;

/// Create a copy of ObjectModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? name = null,Object? address = null,Object? description = freezed,}) {
  return _then(_ObjectModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
