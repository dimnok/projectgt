// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'contract_file_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ContractFileModel {

 String get id;@JsonKey(name: 'company_id') String get companyId;@JsonKey(name: 'contract_id') String get contractId; String get name;@JsonKey(name: 'file_path') String get filePath; int get size; String get type; String? get description;@JsonKey(name: 'display_order') int get displayOrder;@JsonKey(name: 'document_status') ContractDocumentStatus get documentStatus;@JsonKey(name: 'document_version') int get documentVersion;@JsonKey(name: 'is_amendment') bool get isAmendment;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'created_by') String get createdBy;
/// Create a copy of ContractFileModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContractFileModelCopyWith<ContractFileModel> get copyWith => _$ContractFileModelCopyWithImpl<ContractFileModel>(this as ContractFileModel, _$identity);

  /// Serializes this ContractFileModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContractFileModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.name, name) || other.name == name)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.size, size) || other.size == size)&&(identical(other.type, type) || other.type == type)&&(identical(other.description, description) || other.description == description)&&(identical(other.displayOrder, displayOrder) || other.displayOrder == displayOrder)&&(identical(other.documentStatus, documentStatus) || other.documentStatus == documentStatus)&&(identical(other.documentVersion, documentVersion) || other.documentVersion == documentVersion)&&(identical(other.isAmendment, isAmendment) || other.isAmendment == isAmendment)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,contractId,name,filePath,size,type,description,displayOrder,documentStatus,documentVersion,isAmendment,createdAt,createdBy);

@override
String toString() {
  return 'ContractFileModel(id: $id, companyId: $companyId, contractId: $contractId, name: $name, filePath: $filePath, size: $size, type: $type, description: $description, displayOrder: $displayOrder, documentStatus: $documentStatus, documentVersion: $documentVersion, isAmendment: $isAmendment, createdAt: $createdAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class $ContractFileModelCopyWith<$Res>  {
  factory $ContractFileModelCopyWith(ContractFileModel value, $Res Function(ContractFileModel) _then) = _$ContractFileModelCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'company_id') String companyId,@JsonKey(name: 'contract_id') String contractId, String name,@JsonKey(name: 'file_path') String filePath, int size, String type, String? description,@JsonKey(name: 'display_order') int displayOrder,@JsonKey(name: 'document_status') ContractDocumentStatus documentStatus,@JsonKey(name: 'document_version') int documentVersion,@JsonKey(name: 'is_amendment') bool isAmendment,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'created_by') String createdBy
});




}
/// @nodoc
class _$ContractFileModelCopyWithImpl<$Res>
    implements $ContractFileModelCopyWith<$Res> {
  _$ContractFileModelCopyWithImpl(this._self, this._then);

  final ContractFileModel _self;
  final $Res Function(ContractFileModel) _then;

/// Create a copy of ContractFileModel
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

class _ContractFileModel extends ContractFileModel {
  const _ContractFileModel({required this.id, @JsonKey(name: 'company_id') required this.companyId, @JsonKey(name: 'contract_id') required this.contractId, required this.name, @JsonKey(name: 'file_path') required this.filePath, required this.size, required this.type, this.description, @JsonKey(name: 'display_order') required this.displayOrder, @JsonKey(name: 'document_status') this.documentStatus = ContractDocumentStatus.draft, @JsonKey(name: 'document_version') this.documentVersion = 1, @JsonKey(name: 'is_amendment') this.isAmendment = false, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'created_by') required this.createdBy}): super._();
  factory _ContractFileModel.fromJson(Map<String, dynamic> json) => _$ContractFileModelFromJson(json);

@override final  String id;
@override@JsonKey(name: 'company_id') final  String companyId;
@override@JsonKey(name: 'contract_id') final  String contractId;
@override final  String name;
@override@JsonKey(name: 'file_path') final  String filePath;
@override final  int size;
@override final  String type;
@override final  String? description;
@override@JsonKey(name: 'display_order') final  int displayOrder;
@override@JsonKey(name: 'document_status') final  ContractDocumentStatus documentStatus;
@override@JsonKey(name: 'document_version') final  int documentVersion;
@override@JsonKey(name: 'is_amendment') final  bool isAmendment;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'created_by') final  String createdBy;

/// Create a copy of ContractFileModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContractFileModelCopyWith<_ContractFileModel> get copyWith => __$ContractFileModelCopyWithImpl<_ContractFileModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ContractFileModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ContractFileModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.name, name) || other.name == name)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.size, size) || other.size == size)&&(identical(other.type, type) || other.type == type)&&(identical(other.description, description) || other.description == description)&&(identical(other.displayOrder, displayOrder) || other.displayOrder == displayOrder)&&(identical(other.documentStatus, documentStatus) || other.documentStatus == documentStatus)&&(identical(other.documentVersion, documentVersion) || other.documentVersion == documentVersion)&&(identical(other.isAmendment, isAmendment) || other.isAmendment == isAmendment)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,contractId,name,filePath,size,type,description,displayOrder,documentStatus,documentVersion,isAmendment,createdAt,createdBy);

@override
String toString() {
  return 'ContractFileModel(id: $id, companyId: $companyId, contractId: $contractId, name: $name, filePath: $filePath, size: $size, type: $type, description: $description, displayOrder: $displayOrder, documentStatus: $documentStatus, documentVersion: $documentVersion, isAmendment: $isAmendment, createdAt: $createdAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class _$ContractFileModelCopyWith<$Res> implements $ContractFileModelCopyWith<$Res> {
  factory _$ContractFileModelCopyWith(_ContractFileModel value, $Res Function(_ContractFileModel) _then) = __$ContractFileModelCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'company_id') String companyId,@JsonKey(name: 'contract_id') String contractId, String name,@JsonKey(name: 'file_path') String filePath, int size, String type, String? description,@JsonKey(name: 'display_order') int displayOrder,@JsonKey(name: 'document_status') ContractDocumentStatus documentStatus,@JsonKey(name: 'document_version') int documentVersion,@JsonKey(name: 'is_amendment') bool isAmendment,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'created_by') String createdBy
});




}
/// @nodoc
class __$ContractFileModelCopyWithImpl<$Res>
    implements _$ContractFileModelCopyWith<$Res> {
  __$ContractFileModelCopyWithImpl(this._self, this._then);

  final _ContractFileModel _self;
  final $Res Function(_ContractFileModel) _then;

/// Create a copy of ContractFileModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? contractId = null,Object? name = null,Object? filePath = null,Object? size = null,Object? type = null,Object? description = freezed,Object? displayOrder = null,Object? documentStatus = null,Object? documentVersion = null,Object? isAmendment = null,Object? createdAt = null,Object? createdBy = null,}) {
  return _then(_ContractFileModel(
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
