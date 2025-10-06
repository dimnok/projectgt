// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_version_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppVersionModel {
  String get id;
  @JsonKey(name: 'current_version')
  String get currentVersion;
  @JsonKey(name: 'minimum_version')
  String get minimumVersion;
  @JsonKey(name: 'force_update')
  bool get forceUpdate;
  @JsonKey(name: 'update_message')
  String? get updateMessage;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of AppVersionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AppVersionModelCopyWith<AppVersionModel> get copyWith =>
      _$AppVersionModelCopyWithImpl<AppVersionModel>(
          this as AppVersionModel, _$identity);

  /// Serializes this AppVersionModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AppVersionModel &&
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

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, currentVersion,
      minimumVersion, forceUpdate, updateMessage, createdAt, updatedAt);

  @override
  String toString() {
    return 'AppVersionModel(id: $id, currentVersion: $currentVersion, minimumVersion: $minimumVersion, forceUpdate: $forceUpdate, updateMessage: $updateMessage, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class $AppVersionModelCopyWith<$Res> {
  factory $AppVersionModelCopyWith(
          AppVersionModel value, $Res Function(AppVersionModel) _then) =
      _$AppVersionModelCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'current_version') String currentVersion,
      @JsonKey(name: 'minimum_version') String minimumVersion,
      @JsonKey(name: 'force_update') bool forceUpdate,
      @JsonKey(name: 'update_message') String? updateMessage,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class _$AppVersionModelCopyWithImpl<$Res>
    implements $AppVersionModelCopyWith<$Res> {
  _$AppVersionModelCopyWithImpl(this._self, this._then);

  final AppVersionModel _self;
  final $Res Function(AppVersionModel) _then;

  /// Create a copy of AppVersionModel
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
@JsonSerializable()
class _AppVersionModel implements AppVersionModel {
  const _AppVersionModel(
      {required this.id,
      @JsonKey(name: 'current_version') required this.currentVersion,
      @JsonKey(name: 'minimum_version') required this.minimumVersion,
      @JsonKey(name: 'force_update') required this.forceUpdate,
      @JsonKey(name: 'update_message') this.updateMessage,
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'updated_at') this.updatedAt});
  factory _AppVersionModel.fromJson(Map<String, dynamic> json) =>
      _$AppVersionModelFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'current_version')
  final String currentVersion;
  @override
  @JsonKey(name: 'minimum_version')
  final String minimumVersion;
  @override
  @JsonKey(name: 'force_update')
  final bool forceUpdate;
  @override
  @JsonKey(name: 'update_message')
  final String? updateMessage;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  /// Create a copy of AppVersionModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AppVersionModelCopyWith<_AppVersionModel> get copyWith =>
      __$AppVersionModelCopyWithImpl<_AppVersionModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$AppVersionModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AppVersionModel &&
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

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, currentVersion,
      minimumVersion, forceUpdate, updateMessage, createdAt, updatedAt);

  @override
  String toString() {
    return 'AppVersionModel(id: $id, currentVersion: $currentVersion, minimumVersion: $minimumVersion, forceUpdate: $forceUpdate, updateMessage: $updateMessage, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$AppVersionModelCopyWith<$Res>
    implements $AppVersionModelCopyWith<$Res> {
  factory _$AppVersionModelCopyWith(
          _AppVersionModel value, $Res Function(_AppVersionModel) _then) =
      __$AppVersionModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'current_version') String currentVersion,
      @JsonKey(name: 'minimum_version') String minimumVersion,
      @JsonKey(name: 'force_update') bool forceUpdate,
      @JsonKey(name: 'update_message') String? updateMessage,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class __$AppVersionModelCopyWithImpl<$Res>
    implements _$AppVersionModelCopyWith<$Res> {
  __$AppVersionModelCopyWithImpl(this._self, this._then);

  final _AppVersionModel _self;
  final $Res Function(_AppVersionModel) _then;

  /// Create a copy of AppVersionModel
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
    return _then(_AppVersionModel(
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
