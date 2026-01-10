// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProfileModel {

 String get id; String get email;@JsonKey(name: 'full_name') String? get fullName;@JsonKey(name: 'short_name') String? get shortName;@JsonKey(name: 'photo_url') String? get photoUrl; String? get phone; String? get position; String? get roleId; String? get systemRole; bool get status; Map<String, dynamic>? get object;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;@JsonKey(name: 'object_ids') List<String>? get objectIds;@JsonKey(name: 'last_company_id') String? get lastCompanyId;
/// Create a copy of ProfileModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileModelCopyWith<ProfileModel> get copyWith => _$ProfileModelCopyWithImpl<ProfileModel>(this as ProfileModel, _$identity);

  /// Serializes this ProfileModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileModel&&(identical(other.id, id) || other.id == id)&&(identical(other.email, email) || other.email == email)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.shortName, shortName) || other.shortName == shortName)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.position, position) || other.position == position)&&(identical(other.roleId, roleId) || other.roleId == roleId)&&(identical(other.systemRole, systemRole) || other.systemRole == systemRole)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.object, object)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other.objectIds, objectIds)&&(identical(other.lastCompanyId, lastCompanyId) || other.lastCompanyId == lastCompanyId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,email,fullName,shortName,photoUrl,phone,position,roleId,systemRole,status,const DeepCollectionEquality().hash(object),createdAt,updatedAt,const DeepCollectionEquality().hash(objectIds),lastCompanyId);

@override
String toString() {
  return 'ProfileModel(id: $id, email: $email, fullName: $fullName, shortName: $shortName, photoUrl: $photoUrl, phone: $phone, position: $position, roleId: $roleId, systemRole: $systemRole, status: $status, object: $object, createdAt: $createdAt, updatedAt: $updatedAt, objectIds: $objectIds, lastCompanyId: $lastCompanyId)';
}


}

/// @nodoc
abstract mixin class $ProfileModelCopyWith<$Res>  {
  factory $ProfileModelCopyWith(ProfileModel value, $Res Function(ProfileModel) _then) = _$ProfileModelCopyWithImpl;
@useResult
$Res call({
 String id, String email,@JsonKey(name: 'full_name') String? fullName,@JsonKey(name: 'short_name') String? shortName,@JsonKey(name: 'photo_url') String? photoUrl, String? phone, String? position, String? roleId, String? systemRole, bool status, Map<String, dynamic>? object,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt,@JsonKey(name: 'object_ids') List<String>? objectIds,@JsonKey(name: 'last_company_id') String? lastCompanyId
});




}
/// @nodoc
class _$ProfileModelCopyWithImpl<$Res>
    implements $ProfileModelCopyWith<$Res> {
  _$ProfileModelCopyWithImpl(this._self, this._then);

  final ProfileModel _self;
  final $Res Function(ProfileModel) _then;

/// Create a copy of ProfileModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? email = null,Object? fullName = freezed,Object? shortName = freezed,Object? photoUrl = freezed,Object? phone = freezed,Object? position = freezed,Object? roleId = freezed,Object? systemRole = freezed,Object? status = null,Object? object = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? objectIds = freezed,Object? lastCompanyId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,fullName: freezed == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String?,shortName: freezed == shortName ? _self.shortName : shortName // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as String?,roleId: freezed == roleId ? _self.roleId : roleId // ignore: cast_nullable_to_non_nullable
as String?,systemRole: freezed == systemRole ? _self.systemRole : systemRole // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as bool,object: freezed == object ? _self.object : object // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,objectIds: freezed == objectIds ? _self.objectIds : objectIds // ignore: cast_nullable_to_non_nullable
as List<String>?,lastCompanyId: freezed == lastCompanyId ? _self.lastCompanyId : lastCompanyId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class _ProfileModel extends ProfileModel {
  const _ProfileModel({required this.id, required this.email, @JsonKey(name: 'full_name') this.fullName, @JsonKey(name: 'short_name') this.shortName, @JsonKey(name: 'photo_url') this.photoUrl, this.phone, this.position, this.roleId, this.systemRole, this.status = true, final  Map<String, dynamic>? object, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt, @JsonKey(name: 'object_ids') final  List<String>? objectIds, @JsonKey(name: 'last_company_id') this.lastCompanyId}): _object = object,_objectIds = objectIds,super._();
  factory _ProfileModel.fromJson(Map<String, dynamic> json) => _$ProfileModelFromJson(json);

@override final  String id;
@override final  String email;
@override@JsonKey(name: 'full_name') final  String? fullName;
@override@JsonKey(name: 'short_name') final  String? shortName;
@override@JsonKey(name: 'photo_url') final  String? photoUrl;
@override final  String? phone;
@override final  String? position;
@override final  String? roleId;
@override final  String? systemRole;
@override@JsonKey() final  bool status;
 final  Map<String, dynamic>? _object;
@override Map<String, dynamic>? get object {
  final value = _object;
  if (value == null) return null;
  if (_object is EqualUnmodifiableMapView) return _object;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;
 final  List<String>? _objectIds;
@override@JsonKey(name: 'object_ids') List<String>? get objectIds {
  final value = _objectIds;
  if (value == null) return null;
  if (_objectIds is EqualUnmodifiableListView) return _objectIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey(name: 'last_company_id') final  String? lastCompanyId;

/// Create a copy of ProfileModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileModelCopyWith<_ProfileModel> get copyWith => __$ProfileModelCopyWithImpl<_ProfileModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfileModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileModel&&(identical(other.id, id) || other.id == id)&&(identical(other.email, email) || other.email == email)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.shortName, shortName) || other.shortName == shortName)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.position, position) || other.position == position)&&(identical(other.roleId, roleId) || other.roleId == roleId)&&(identical(other.systemRole, systemRole) || other.systemRole == systemRole)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._object, _object)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other._objectIds, _objectIds)&&(identical(other.lastCompanyId, lastCompanyId) || other.lastCompanyId == lastCompanyId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,email,fullName,shortName,photoUrl,phone,position,roleId,systemRole,status,const DeepCollectionEquality().hash(_object),createdAt,updatedAt,const DeepCollectionEquality().hash(_objectIds),lastCompanyId);

@override
String toString() {
  return 'ProfileModel(id: $id, email: $email, fullName: $fullName, shortName: $shortName, photoUrl: $photoUrl, phone: $phone, position: $position, roleId: $roleId, systemRole: $systemRole, status: $status, object: $object, createdAt: $createdAt, updatedAt: $updatedAt, objectIds: $objectIds, lastCompanyId: $lastCompanyId)';
}


}

/// @nodoc
abstract mixin class _$ProfileModelCopyWith<$Res> implements $ProfileModelCopyWith<$Res> {
  factory _$ProfileModelCopyWith(_ProfileModel value, $Res Function(_ProfileModel) _then) = __$ProfileModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String email,@JsonKey(name: 'full_name') String? fullName,@JsonKey(name: 'short_name') String? shortName,@JsonKey(name: 'photo_url') String? photoUrl, String? phone, String? position, String? roleId, String? systemRole, bool status, Map<String, dynamic>? object,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt,@JsonKey(name: 'object_ids') List<String>? objectIds,@JsonKey(name: 'last_company_id') String? lastCompanyId
});




}
/// @nodoc
class __$ProfileModelCopyWithImpl<$Res>
    implements _$ProfileModelCopyWith<$Res> {
  __$ProfileModelCopyWithImpl(this._self, this._then);

  final _ProfileModel _self;
  final $Res Function(_ProfileModel) _then;

/// Create a copy of ProfileModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? email = null,Object? fullName = freezed,Object? shortName = freezed,Object? photoUrl = freezed,Object? phone = freezed,Object? position = freezed,Object? roleId = freezed,Object? systemRole = freezed,Object? status = null,Object? object = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? objectIds = freezed,Object? lastCompanyId = freezed,}) {
  return _then(_ProfileModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,fullName: freezed == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String?,shortName: freezed == shortName ? _self.shortName : shortName // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as String?,roleId: freezed == roleId ? _self.roleId : roleId // ignore: cast_nullable_to_non_nullable
as String?,systemRole: freezed == systemRole ? _self.systemRole : systemRole // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as bool,object: freezed == object ? _self._object : object // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,objectIds: freezed == objectIds ? _self._objectIds : objectIds // ignore: cast_nullable_to_non_nullable
as List<String>?,lastCompanyId: freezed == lastCompanyId ? _self.lastCompanyId : lastCompanyId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
