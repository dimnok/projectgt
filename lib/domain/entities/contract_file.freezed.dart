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

 String get id; String get companyId; String get contractId; String get name; String get filePath; int get size; String get type; String? get description;/// Порядок отображения в UI (0 — первый в списке).
@JsonKey(name: 'display_order') int get displayOrder;/// Статус в цикле согласования.
@JsonKey(name: 'document_status') ContractDocumentStatus get documentStatus;/// Номер версии для отображения (v1, v2, …), не меньше 1.
@JsonKey(name: 'document_version') int get documentVersion;/// Признак новой редакции (пометка «изм.» в списке).
@JsonKey(name: 'is_amendment') bool get isAmendment;/// Дата и время загрузки файла на сервер.
 DateTime get createdAt; String get createdBy;
/// Create a copy of ContractFile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContractFileCopyWith<ContractFile> get copyWith => _$ContractFileCopyWithImpl<ContractFile>(this as ContractFile, _$identity);

  /// Serializes this ContractFile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContractFile&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.name, name) || other.name == name)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.size, size) || other.size == size)&&(identical(other.type, type) || other.type == type)&&(identical(other.description, description) || other.description == description)&&(identical(other.displayOrder, displayOrder) || other.displayOrder == displayOrder)&&(identical(other.documentStatus, documentStatus) || other.documentStatus == documentStatus)&&(identical(other.documentVersion, documentVersion) || other.documentVersion == documentVersion)&&(identical(other.isAmendment, isAmendment) || other.isAmendment == isAmendment)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,contractId,name,filePath,size,type,description,displayOrder,documentStatus,documentVersion,isAmendment,createdAt,createdBy);

@override
String toString() {
  return 'ContractFile(id: $id, companyId: $companyId, contractId: $contractId, name: $name, filePath: $filePath, size: $size, type: $type, description: $description, displayOrder: $displayOrder, documentStatus: $documentStatus, documentVersion: $documentVersion, isAmendment: $isAmendment, createdAt: $createdAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class $ContractFileCopyWith<$Res>  {
  factory $ContractFileCopyWith(ContractFile value, $Res Function(ContractFile) _then) = _$ContractFileCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String contractId, String name, String filePath, int size, String type, String? description,@JsonKey(name: 'display_order') int displayOrder,@JsonKey(name: 'document_status') ContractDocumentStatus documentStatus,@JsonKey(name: 'document_version') int documentVersion,@JsonKey(name: 'is_amendment') bool isAmendment, DateTime createdAt, String createdBy
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? contractId = null,Object? name = null,Object? filePath = null,Object? size = null,Object? type = null,Object? description = freezed,Object? displayOrder = null,Object? documentStatus = null,Object? documentVersion = null,Object? isAmendment = null,Object? createdAt = null,Object? createdBy = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,contractId: null == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,filePath: null == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,displayOrder: null == displayOrder ? _self.displayOrder : displayOrder // ignore: cast_nullable_to_non_nullable
as int,documentStatus: null == documentStatus ? _self.documentStatus : documentStatus // ignore: cast_nullable_to_non_nullable
as ContractDocumentStatus,documentVersion: null == documentVersion ? _self.documentVersion : documentVersion // ignore: cast_nullable_to_non_nullable
as int,isAmendment: null == isAmendment ? _self.isAmendment : isAmendment // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _ContractFile implements ContractFile {
  const _ContractFile({required this.id, required this.companyId, required this.contractId, required this.name, required this.filePath, required this.size, required this.type, this.description, @JsonKey(name: 'display_order') required this.displayOrder, @JsonKey(name: 'document_status') this.documentStatus = ContractDocumentStatus.draft, @JsonKey(name: 'document_version') this.documentVersion = 1, @JsonKey(name: 'is_amendment') this.isAmendment = false, required this.createdAt, required this.createdBy});
  factory _ContractFile.fromJson(Map<String, dynamic> json) => _$ContractFileFromJson(json);

@override final  String id;
@override final  String companyId;
@override final  String contractId;
@override final  String name;
@override final  String filePath;
@override final  int size;
@override final  String type;
@override final  String? description;
/// Порядок отображения в UI (0 — первый в списке).
@override@JsonKey(name: 'display_order') final  int displayOrder;
/// Статус в цикле согласования.
@override@JsonKey(name: 'document_status') final  ContractDocumentStatus documentStatus;
/// Номер версии для отображения (v1, v2, …), не меньше 1.
@override@JsonKey(name: 'document_version') final  int documentVersion;
/// Признак новой редакции (пометка «изм.» в списке).
@override@JsonKey(name: 'is_amendment') final  bool isAmendment;
/// Дата и время загрузки файла на сервер.
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ContractFile&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.name, name) || other.name == name)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.size, size) || other.size == size)&&(identical(other.type, type) || other.type == type)&&(identical(other.description, description) || other.description == description)&&(identical(other.displayOrder, displayOrder) || other.displayOrder == displayOrder)&&(identical(other.documentStatus, documentStatus) || other.documentStatus == documentStatus)&&(identical(other.documentVersion, documentVersion) || other.documentVersion == documentVersion)&&(identical(other.isAmendment, isAmendment) || other.isAmendment == isAmendment)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,contractId,name,filePath,size,type,description,displayOrder,documentStatus,documentVersion,isAmendment,createdAt,createdBy);

@override
String toString() {
  return 'ContractFile(id: $id, companyId: $companyId, contractId: $contractId, name: $name, filePath: $filePath, size: $size, type: $type, description: $description, displayOrder: $displayOrder, documentStatus: $documentStatus, documentVersion: $documentVersion, isAmendment: $isAmendment, createdAt: $createdAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class _$ContractFileCopyWith<$Res> implements $ContractFileCopyWith<$Res> {
  factory _$ContractFileCopyWith(_ContractFile value, $Res Function(_ContractFile) _then) = __$ContractFileCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String contractId, String name, String filePath, int size, String type, String? description,@JsonKey(name: 'display_order') int displayOrder,@JsonKey(name: 'document_status') ContractDocumentStatus documentStatus,@JsonKey(name: 'document_version') int documentVersion,@JsonKey(name: 'is_amendment') bool isAmendment, DateTime createdAt, String createdBy
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? contractId = null,Object? name = null,Object? filePath = null,Object? size = null,Object? type = null,Object? description = freezed,Object? displayOrder = null,Object? documentStatus = null,Object? documentVersion = null,Object? isAmendment = null,Object? createdAt = null,Object? createdBy = null,}) {
  return _then(_ContractFile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,contractId: null == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,filePath: null == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,displayOrder: null == displayOrder ? _self.displayOrder : displayOrder // ignore: cast_nullable_to_non_nullable
as int,documentStatus: null == documentStatus ? _self.documentStatus : documentStatus // ignore: cast_nullable_to_non_nullable
as ContractDocumentStatus,documentVersion: null == documentVersion ? _self.documentVersion : documentVersion // ignore: cast_nullable_to_non_nullable
as int,isAmendment: null == isAmendment ? _self.isAmendment : isAmendment // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
