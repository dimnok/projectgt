// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'contract_file.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ContractFile {

 String get id; String get companyId; String get contractId; String get name; String get filePath; int get size; String get type; DateTime get createdAt; String get createdBy;
/// Create a copy of ContractFile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContractFileCopyWith<ContractFile> get copyWith => _$ContractFileCopyWithImpl<ContractFile>(this as ContractFile, _$identity);

  /// Serializes this ContractFile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContractFile&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.name, name) || other.name == name)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.size, size) || other.size == size)&&(identical(other.type, type) || other.type == type)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,contractId,name,filePath,size,type,createdAt,createdBy);

@override
String toString() {
  return 'ContractFile(id: $id, companyId: $companyId, contractId: $contractId, name: $name, filePath: $filePath, size: $size, type: $type, createdAt: $createdAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class $ContractFileCopyWith<$Res>  {
  factory $ContractFileCopyWith(ContractFile value, $Res Function(ContractFile) _then) = _$ContractFileCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String contractId, String name, String filePath, int size, String type, DateTime createdAt, String createdBy
});




}
/// @nodoc
class _$ContractFileCopyWithImpl<$Res>
    implements $ContractFileCopyWith<$Res> {
  _$ContractFileCopyWithImpl(this._self, this._then);

  final ContractFile _self;
  final $Res Function(ContractFile) _then;

/// Create a copy of ContractFile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? contractId = null,Object? name = null,Object? filePath = null,Object? size = null,Object? type = null,Object? createdAt = null,Object? createdBy = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,contractId: null == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,filePath: null == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _ContractFile implements ContractFile {
  const _ContractFile({required this.id, required this.companyId, required this.contractId, required this.name, required this.filePath, required this.size, required this.type, required this.createdAt, required this.createdBy});
  factory _ContractFile.fromJson(Map<String, dynamic> json) => _$ContractFileFromJson(json);

@override final  String id;
@override final  String companyId;
@override final  String contractId;
@override final  String name;
@override final  String filePath;
@override final  int size;
@override final  String type;
@override final  DateTime createdAt;
@override final  String createdBy;

/// Create a copy of ContractFile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContractFileCopyWith<_ContractFile> get copyWith => __$ContractFileCopyWithImpl<_ContractFile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ContractFileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ContractFile&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.name, name) || other.name == name)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.size, size) || other.size == size)&&(identical(other.type, type) || other.type == type)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,contractId,name,filePath,size,type,createdAt,createdBy);

@override
String toString() {
  return 'ContractFile(id: $id, companyId: $companyId, contractId: $contractId, name: $name, filePath: $filePath, size: $size, type: $type, createdAt: $createdAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class _$ContractFileCopyWith<$Res> implements $ContractFileCopyWith<$Res> {
  factory _$ContractFileCopyWith(_ContractFile value, $Res Function(_ContractFile) _then) = __$ContractFileCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String contractId, String name, String filePath, int size, String type, DateTime createdAt, String createdBy
});




}
/// @nodoc
class __$ContractFileCopyWithImpl<$Res>
    implements _$ContractFileCopyWith<$Res> {
  __$ContractFileCopyWithImpl(this._self, this._then);

  final _ContractFile _self;
  final $Res Function(_ContractFile) _then;

/// Create a copy of ContractFile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? contractId = null,Object? name = null,Object? filePath = null,Object? size = null,Object? type = null,Object? createdAt = null,Object? createdBy = null,}) {
  return _then(_ContractFile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,contractId: null == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,filePath: null == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
