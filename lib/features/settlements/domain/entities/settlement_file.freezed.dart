// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settlement_file.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SettlementFile {

/// Идентификатор записи.
 String get id;/// Компания-владелец.
 String get companyId;/// Счёт, к которому прикреплён файл.
 String get settlementOperationId;/// Отображаемое имя (может содержать кириллицу).
 String get name;/// Путь к объекту в Storage.
 String get filePath;/// Размер в байтах.
 int get size;/// MIME-тип.
 String get type;/// Необязательное описание.
 String? get description;/// Дата загрузки.
 DateTime get createdAt;/// Автор загрузки.
 String? get createdBy;
/// Create a copy of SettlementFile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettlementFileCopyWith<SettlementFile> get copyWith => _$SettlementFileCopyWithImpl<SettlementFile>(this as SettlementFile, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettlementFile&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.settlementOperationId, settlementOperationId) || other.settlementOperationId == settlementOperationId)&&(identical(other.name, name) || other.name == name)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.size, size) || other.size == size)&&(identical(other.type, type) || other.type == type)&&(identical(other.description, description) || other.description == description)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,settlementOperationId,name,filePath,size,type,description,createdAt,createdBy);

@override
String toString() {
  return 'SettlementFile(id: $id, companyId: $companyId, settlementOperationId: $settlementOperationId, name: $name, filePath: $filePath, size: $size, type: $type, description: $description, createdAt: $createdAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class $SettlementFileCopyWith<$Res>  {
  factory $SettlementFileCopyWith(SettlementFile value, $Res Function(SettlementFile) _then) = _$SettlementFileCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String settlementOperationId, String name, String filePath, int size, String type, String? description, DateTime createdAt, String? createdBy
});




}
/// @nodoc
class _$SettlementFileCopyWithImpl<$Res>
    implements $SettlementFileCopyWith<$Res> {
  _$SettlementFileCopyWithImpl(this._self, this._then);

  final SettlementFile _self;
  final $Res Function(SettlementFile) _then;

/// Create a copy of SettlementFile
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


class _SettlementFile implements SettlementFile {
  const _SettlementFile({required this.id, required this.companyId, required this.settlementOperationId, required this.name, required this.filePath, required this.size, required this.type, this.description, required this.createdAt, this.createdBy});
  

/// Идентификатор записи.
@override final  String id;
/// Компания-владелец.
@override final  String companyId;
/// Счёт, к которому прикреплён файл.
@override final  String settlementOperationId;
/// Отображаемое имя (может содержать кириллицу).
@override final  String name;
/// Путь к объекту в Storage.
@override final  String filePath;
/// Размер в байтах.
@override final  int size;
/// MIME-тип.
@override final  String type;
/// Необязательное описание.
@override final  String? description;
/// Дата загрузки.
@override final  DateTime createdAt;
/// Автор загрузки.
@override final  String? createdBy;

/// Create a copy of SettlementFile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SettlementFileCopyWith<_SettlementFile> get copyWith => __$SettlementFileCopyWithImpl<_SettlementFile>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SettlementFile&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.settlementOperationId, settlementOperationId) || other.settlementOperationId == settlementOperationId)&&(identical(other.name, name) || other.name == name)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.size, size) || other.size == size)&&(identical(other.type, type) || other.type == type)&&(identical(other.description, description) || other.description == description)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,settlementOperationId,name,filePath,size,type,description,createdAt,createdBy);

@override
String toString() {
  return 'SettlementFile(id: $id, companyId: $companyId, settlementOperationId: $settlementOperationId, name: $name, filePath: $filePath, size: $size, type: $type, description: $description, createdAt: $createdAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class _$SettlementFileCopyWith<$Res> implements $SettlementFileCopyWith<$Res> {
  factory _$SettlementFileCopyWith(_SettlementFile value, $Res Function(_SettlementFile) _then) = __$SettlementFileCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String settlementOperationId, String name, String filePath, int size, String type, String? description, DateTime createdAt, String? createdBy
});




}
/// @nodoc
class __$SettlementFileCopyWithImpl<$Res>
    implements _$SettlementFileCopyWith<$Res> {
  __$SettlementFileCopyWithImpl(this._self, this._then);

  final _SettlementFile _self;
  final $Res Function(_SettlementFile) _then;

/// Create a copy of SettlementFile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? settlementOperationId = null,Object? name = null,Object? filePath = null,Object? size = null,Object? type = null,Object? description = freezed,Object? createdAt = null,Object? createdBy = freezed,}) {
  return _then(_SettlementFile(
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
