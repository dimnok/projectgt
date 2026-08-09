// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settlement_file_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SettlementFileModel {

 String get id; String get companyId; String get settlementOperationId; String get name; String get filePath; int get size; String get type; String? get description; DateTime get createdAt; String? get createdBy;
/// Create a copy of SettlementFileModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettlementFileModelCopyWith<SettlementFileModel> get copyWith => _$SettlementFileModelCopyWithImpl<SettlementFileModel>(this as SettlementFileModel, _$identity);

  /// Serializes this SettlementFileModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettlementFileModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.settlementOperationId, settlementOperationId) || other.settlementOperationId == settlementOperationId)&&(identical(other.name, name) || other.name == name)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.size, size) || other.size == size)&&(identical(other.type, type) || other.type == type)&&(identical(other.description, description) || other.description == description)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,settlementOperationId,name,filePath,size,type,description,createdAt,createdBy);

@override
String toString() {
  return 'SettlementFileModel(id: $id, companyId: $companyId, settlementOperationId: $settlementOperationId, name: $name, filePath: $filePath, size: $size, type: $type, description: $description, createdAt: $createdAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class $SettlementFileModelCopyWith<$Res>  {
  factory $SettlementFileModelCopyWith(SettlementFileModel value, $Res Function(SettlementFileModel) _then) = _$SettlementFileModelCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String settlementOperationId, String name, String filePath, int size, String type, String? description, DateTime createdAt, String? createdBy
});




}
/// @nodoc
class _$SettlementFileModelCopyWithImpl<$Res>
    implements $SettlementFileModelCopyWith<$Res> {
  _$SettlementFileModelCopyWithImpl(this._self, this._then);

  final SettlementFileModel _self;
  final $Res Function(SettlementFileModel) _then;

/// Create a copy of SettlementFileModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? settlementOperationId = null,Object? name = null,Object? filePath = null,Object? size = null,Object? type = null,Object? description = freezed,Object? createdAt = null,Object? createdBy = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,settlementOperationId: null == settlementOperationId ? _self.settlementOperationId : settlementOperationId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,filePath: null == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _SettlementFileModel extends SettlementFileModel {
  const _SettlementFileModel({required this.id, required this.companyId, required this.settlementOperationId, required this.name, required this.filePath, required this.size, required this.type, this.description, required this.createdAt, this.createdBy}): super._();
  factory _SettlementFileModel.fromJson(Map<String, dynamic> json) => _$SettlementFileModelFromJson(json);

@override final  String id;
@override final  String companyId;
@override final  String settlementOperationId;
@override final  String name;
@override final  String filePath;
@override final  int size;
@override final  String type;
@override final  String? description;
@override final  DateTime createdAt;
@override final  String? createdBy;

/// Create a copy of SettlementFileModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SettlementFileModelCopyWith<_SettlementFileModel> get copyWith => __$SettlementFileModelCopyWithImpl<_SettlementFileModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SettlementFileModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SettlementFileModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.settlementOperationId, settlementOperationId) || other.settlementOperationId == settlementOperationId)&&(identical(other.name, name) || other.name == name)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.size, size) || other.size == size)&&(identical(other.type, type) || other.type == type)&&(identical(other.description, description) || other.description == description)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,settlementOperationId,name,filePath,size,type,description,createdAt,createdBy);

@override
String toString() {
  return 'SettlementFileModel(id: $id, companyId: $companyId, settlementOperationId: $settlementOperationId, name: $name, filePath: $filePath, size: $size, type: $type, description: $description, createdAt: $createdAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class _$SettlementFileModelCopyWith<$Res> implements $SettlementFileModelCopyWith<$Res> {
  factory _$SettlementFileModelCopyWith(_SettlementFileModel value, $Res Function(_SettlementFileModel) _then) = __$SettlementFileModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String settlementOperationId, String name, String filePath, int size, String type, String? description, DateTime createdAt, String? createdBy
});




}
/// @nodoc
class __$SettlementFileModelCopyWithImpl<$Res>
    implements _$SettlementFileModelCopyWith<$Res> {
  __$SettlementFileModelCopyWithImpl(this._self, this._then);

  final _SettlementFileModel _self;
  final $Res Function(_SettlementFileModel) _then;

/// Create a copy of SettlementFileModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? settlementOperationId = null,Object? name = null,Object? filePath = null,Object? size = null,Object? type = null,Object? description = freezed,Object? createdAt = null,Object? createdBy = freezed,}) {
  return _then(_SettlementFileModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,settlementOperationId: null == settlementOperationId ? _self.settlementOperationId : settlementOperationId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,filePath: null == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
