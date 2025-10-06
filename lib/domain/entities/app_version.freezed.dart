// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_version.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppVersion {
  /// Идентификатор версии.
  String get id;

  /// Текущая последняя версия приложения.
  String get currentVersion;

  /// Минимальная поддерживаемая версия.
  String get minimumVersion;

  /// Флаг принудительного обновления.
  bool get forceUpdate;

  /// Сообщение для пользователя об обновлении.
  String? get updateMessage;

  /// Дата создания записи.
  DateTime? get createdAt;

  /// Дата последнего обновления записи.
  DateTime? get updatedAt;

  /// Create a copy of AppVersion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AppVersionCopyWith<AppVersion> get copyWith =>
      _$AppVersionCopyWithImpl<AppVersion>(this as AppVersion, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AppVersion &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.currentVersion, currentVersion) ||
                other.currentVersion == currentVersion) &&
            (identical(other.minimumVersion, minimumVersion) ||
                other.minimumVersion == minimumVersion) &&
            (identical(other.forceUpdate, forceUpdate) ||
                other.forceUpdate == forceUpdate) &&
            (identical(other.updateMessage, updateMessage) ||
                other.updateMessage == updateMessage) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, currentVersion,
      minimumVersion, forceUpdate, updateMessage, createdAt, updatedAt);

  @override
  String toString() {
    return 'AppVersion(id: $id, currentVersion: $currentVersion, minimumVersion: $minimumVersion, forceUpdate: $forceUpdate, updateMessage: $updateMessage, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class $AppVersionCopyWith<$Res> {
  factory $AppVersionCopyWith(
          AppVersion value, $Res Function(AppVersion) _then) =
      _$AppVersionCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String currentVersion,
      String minimumVersion,
      bool forceUpdate,
      String? updateMessage,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class _$AppVersionCopyWithImpl<$Res> implements $AppVersionCopyWith<$Res> {
  _$AppVersionCopyWithImpl(this._self, this._then);

  final AppVersion _self;
  final $Res Function(AppVersion) _then;

  /// Create a copy of AppVersion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? currentVersion = null,
    Object? minimumVersion = null,
    Object? forceUpdate = null,
    Object? updateMessage = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      currentVersion: null == currentVersion
          ? _self.currentVersion
          : currentVersion // ignore: cast_nullable_to_non_nullable
              as String,
      minimumVersion: null == minimumVersion
          ? _self.minimumVersion
          : minimumVersion // ignore: cast_nullable_to_non_nullable
              as String,
      forceUpdate: null == forceUpdate
          ? _self.forceUpdate
          : forceUpdate // ignore: cast_nullable_to_non_nullable
              as bool,
      updateMessage: freezed == updateMessage
          ? _self.updateMessage
          : updateMessage // ignore: cast_nullable_to_non_nullable
              as String?,
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

class _AppVersion implements AppVersion {
  const _AppVersion(
      {required this.id,
      required this.currentVersion,
      required this.minimumVersion,
      required this.forceUpdate,
      this.updateMessage,
      this.createdAt,
      this.updatedAt});

  /// Идентификатор версии.
  @override
  final String id;

  /// Текущая последняя версия приложения.
  @override
  final String currentVersion;

  /// Минимальная поддерживаемая версия.
  @override
  final String minimumVersion;

  /// Флаг принудительного обновления.
  @override
  final bool forceUpdate;

  /// Сообщение для пользователя об обновлении.
  @override
  final String? updateMessage;

  /// Дата создания записи.
  @override
  final DateTime? createdAt;

  /// Дата последнего обновления записи.
  @override
  final DateTime? updatedAt;

  /// Create a copy of AppVersion
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AppVersionCopyWith<_AppVersion> get copyWith =>
      __$AppVersionCopyWithImpl<_AppVersion>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AppVersion &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.currentVersion, currentVersion) ||
                other.currentVersion == currentVersion) &&
            (identical(other.minimumVersion, minimumVersion) ||
                other.minimumVersion == minimumVersion) &&
            (identical(other.forceUpdate, forceUpdate) ||
                other.forceUpdate == forceUpdate) &&
            (identical(other.updateMessage, updateMessage) ||
                other.updateMessage == updateMessage) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, currentVersion,
      minimumVersion, forceUpdate, updateMessage, createdAt, updatedAt);

  @override
  String toString() {
    return 'AppVersion(id: $id, currentVersion: $currentVersion, minimumVersion: $minimumVersion, forceUpdate: $forceUpdate, updateMessage: $updateMessage, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$AppVersionCopyWith<$Res>
    implements $AppVersionCopyWith<$Res> {
  factory _$AppVersionCopyWith(
          _AppVersion value, $Res Function(_AppVersion) _then) =
      __$AppVersionCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String currentVersion,
      String minimumVersion,
      bool forceUpdate,
      String? updateMessage,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class __$AppVersionCopyWithImpl<$Res> implements _$AppVersionCopyWith<$Res> {
  __$AppVersionCopyWithImpl(this._self, this._then);

  final _AppVersion _self;
  final $Res Function(_AppVersion) _then;

  /// Create a copy of AppVersion
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? currentVersion = null,
    Object? minimumVersion = null,
    Object? forceUpdate = null,
    Object? updateMessage = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_AppVersion(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      currentVersion: null == currentVersion
          ? _self.currentVersion
          : currentVersion // ignore: cast_nullable_to_non_nullable
              as String,
      minimumVersion: null == minimumVersion
          ? _self.minimumVersion
          : minimumVersion // ignore: cast_nullable_to_non_nullable
              as String,
      forceUpdate: null == forceUpdate
          ? _self.forceUpdate
          : forceUpdate // ignore: cast_nullable_to_non_nullable
              as bool,
      updateMessage: freezed == updateMessage
          ? _self.updateMessage
          : updateMessage // ignore: cast_nullable_to_non_nullable
              as String?,
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
