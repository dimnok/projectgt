// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Profile {
  /// Уникальный идентификатор профиля.
  String get id;

  /// Email пользователя.
  String get email;

  /// Полное имя пользователя.
  String? get fullName;

  /// Краткое имя пользователя.
  String? get shortName;

  /// URL фотографии пользователя.
  String? get photoUrl;

  /// Телефон пользователя.
  String? get phone;

  /// Должность пользователя.
  String? get position;

  /// ID роли пользователя (связь с таблицей roles).
  String? get roleId;

  /// Статус профиля (активен/неактивен).
  bool get status;

  /// Связанный объект (например, организация или проект).
  Map<String, dynamic>? get object;

  /// Связанные объекты (uuid объектов, связанных с профилем).
  List<String>? get objectIds;

  /// Дата создания профиля.
  DateTime? get createdAt;

  /// Дата последнего обновления профиля.
  DateTime? get updatedAt;

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ProfileCopyWith<Profile> get copyWith =>
      _$ProfileCopyWithImpl<Profile>(this as Profile, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Profile &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.fullName, fullName) ||
                other.fullName == fullName) &&
            (identical(other.shortName, shortName) ||
                other.shortName == shortName) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.roleId, roleId) || other.roleId == roleId) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(other.object, object) &&
            const DeepCollectionEquality().equals(other.objectIds, objectIds) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      email,
      fullName,
      shortName,
      photoUrl,
      phone,
      position,
      roleId,
      status,
      const DeepCollectionEquality().hash(object),
      const DeepCollectionEquality().hash(objectIds),
      createdAt,
      updatedAt);

  @override
  String toString() {
    return 'Profile(id: $id, email: $email, fullName: $fullName, shortName: $shortName, photoUrl: $photoUrl, phone: $phone, position: $position, roleId: $roleId, status: $status, object: $object, objectIds: $objectIds, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class $ProfileCopyWith<$Res> {
  factory $ProfileCopyWith(Profile value, $Res Function(Profile) _then) =
      _$ProfileCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String email,
      String? fullName,
      String? shortName,
      String? photoUrl,
      String? phone,
      String? position,
      String? roleId,
      bool status,
      Map<String, dynamic>? object,
      List<String>? objectIds,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class _$ProfileCopyWithImpl<$Res> implements $ProfileCopyWith<$Res> {
  _$ProfileCopyWithImpl(this._self, this._then);

  final Profile _self;
  final $Res Function(Profile) _then;

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? fullName = freezed,
    Object? shortName = freezed,
    Object? photoUrl = freezed,
    Object? phone = freezed,
    Object? position = freezed,
    Object? roleId = freezed,
    Object? status = null,
    Object? object = freezed,
    Object? objectIds = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _self.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      fullName: freezed == fullName
          ? _self.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String?,
      shortName: freezed == shortName
          ? _self.shortName
          : shortName // ignore: cast_nullable_to_non_nullable
              as String?,
      photoUrl: freezed == photoUrl
          ? _self.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      phone: freezed == phone
          ? _self.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String?,
      position: freezed == position
          ? _self.position
          : position // ignore: cast_nullable_to_non_nullable
              as String?,
      roleId: freezed == roleId
          ? _self.roleId
          : roleId // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as bool,
      object: freezed == object
          ? _self.object
          : object // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      objectIds: freezed == objectIds
          ? _self.objectIds
          : objectIds // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc

class _Profile extends Profile {
  const _Profile(
      {required this.id,
      required this.email,
      this.fullName,
      this.shortName,
      this.photoUrl,
      this.phone,
      this.position,
      this.roleId,
      this.status = true,
      final Map<String, dynamic>? object,
      final List<String>? objectIds,
      this.createdAt,
      this.updatedAt})
      : _object = object,
        _objectIds = objectIds,
        super._();

  /// Уникальный идентификатор профиля.
  @override
  final String id;

  /// Email пользователя.
  @override
  final String email;

  /// Полное имя пользователя.
  @override
  final String? fullName;

  /// Краткое имя пользователя.
  @override
  final String? shortName;

  /// URL фотографии пользователя.
  @override
  final String? photoUrl;

  /// Телефон пользователя.
  @override
  final String? phone;

  /// Должность пользователя.
  @override
  final String? position;

  /// ID роли пользователя (связь с таблицей roles).
  @override
  final String? roleId;

  /// Статус профиля (активен/неактивен).
  @override
  @JsonKey()
  final bool status;

  /// Связанный объект (например, организация или проект).
  final Map<String, dynamic>? _object;

  /// Связанный объект (например, организация или проект).
  @override
  Map<String, dynamic>? get object {
    final value = _object;
    if (value == null) return null;
    if (_object is EqualUnmodifiableMapView) return _object;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  /// Связанные объекты (uuid объектов, связанных с профилем).
  final List<String>? _objectIds;

  /// Связанные объекты (uuid объектов, связанных с профилем).
  @override
  List<String>? get objectIds {
    final value = _objectIds;
    if (value == null) return null;
    if (_objectIds is EqualUnmodifiableListView) return _objectIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  /// Дата создания профиля.
  @override
  final DateTime? createdAt;

  /// Дата последнего обновления профиля.
  @override
  final DateTime? updatedAt;

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ProfileCopyWith<_Profile> get copyWith =>
      __$ProfileCopyWithImpl<_Profile>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Profile &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.fullName, fullName) ||
                other.fullName == fullName) &&
            (identical(other.shortName, shortName) ||
                other.shortName == shortName) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.roleId, roleId) || other.roleId == roleId) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(other._object, _object) &&
            const DeepCollectionEquality()
                .equals(other._objectIds, _objectIds) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      email,
      fullName,
      shortName,
      photoUrl,
      phone,
      position,
      roleId,
      status,
      const DeepCollectionEquality().hash(_object),
      const DeepCollectionEquality().hash(_objectIds),
      createdAt,
      updatedAt);

  @override
  String toString() {
    return 'Profile(id: $id, email: $email, fullName: $fullName, shortName: $shortName, photoUrl: $photoUrl, phone: $phone, position: $position, roleId: $roleId, status: $status, object: $object, objectIds: $objectIds, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$ProfileCopyWith<$Res> implements $ProfileCopyWith<$Res> {
  factory _$ProfileCopyWith(_Profile value, $Res Function(_Profile) _then) =
      __$ProfileCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String email,
      String? fullName,
      String? shortName,
      String? photoUrl,
      String? phone,
      String? position,
      String? roleId,
      bool status,
      Map<String, dynamic>? object,
      List<String>? objectIds,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class __$ProfileCopyWithImpl<$Res> implements _$ProfileCopyWith<$Res> {
  __$ProfileCopyWithImpl(this._self, this._then);

  final _Profile _self;
  final $Res Function(_Profile) _then;

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? fullName = freezed,
    Object? shortName = freezed,
    Object? photoUrl = freezed,
    Object? phone = freezed,
    Object? position = freezed,
    Object? roleId = freezed,
    Object? status = null,
    Object? object = freezed,
    Object? objectIds = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_Profile(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _self.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      fullName: freezed == fullName
          ? _self.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String?,
      shortName: freezed == shortName
          ? _self.shortName
          : shortName // ignore: cast_nullable_to_non_nullable
              as String?,
      photoUrl: freezed == photoUrl
          ? _self.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      phone: freezed == phone
          ? _self.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String?,
      position: freezed == position
          ? _self.position
          : position // ignore: cast_nullable_to_non_nullable
              as String?,
      roleId: freezed == roleId
          ? _self.roleId
          : roleId // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as bool,
      object: freezed == object
          ? _self._object
          : object // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      objectIds: freezed == objectIds
          ? _self._objectIds
          : objectIds // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

// dart format on
