// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'role_permission_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RolePermissionModel {
  String get id;
  String get roleId;
  String get moduleCode;
  String get permissionCode;
  bool get isEnabled;

  /// Create a copy of RolePermissionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RolePermissionModelCopyWith<RolePermissionModel> get copyWith =>
      _$RolePermissionModelCopyWithImpl<RolePermissionModel>(
          this as RolePermissionModel, _$identity);

  /// Serializes this RolePermissionModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RolePermissionModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.roleId, roleId) || other.roleId == roleId) &&
            (identical(other.moduleCode, moduleCode) ||
                other.moduleCode == moduleCode) &&
            (identical(other.permissionCode, permissionCode) ||
                other.permissionCode == permissionCode) &&
            (identical(other.isEnabled, isEnabled) ||
                other.isEnabled == isEnabled));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, roleId, moduleCode, permissionCode, isEnabled);

  @override
  String toString() {
    return 'RolePermissionModel(id: $id, roleId: $roleId, moduleCode: $moduleCode, permissionCode: $permissionCode, isEnabled: $isEnabled)';
  }
}

/// @nodoc
abstract mixin class $RolePermissionModelCopyWith<$Res> {
  factory $RolePermissionModelCopyWith(
          RolePermissionModel value, $Res Function(RolePermissionModel) _then) =
      _$RolePermissionModelCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String roleId,
      String moduleCode,
      String permissionCode,
      bool isEnabled});
}

/// @nodoc
class _$RolePermissionModelCopyWithImpl<$Res>
    implements $RolePermissionModelCopyWith<$Res> {
  _$RolePermissionModelCopyWithImpl(this._self, this._then);

  final RolePermissionModel _self;
  final $Res Function(RolePermissionModel) _then;

  /// Create a copy of RolePermissionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? roleId = null,
    Object? moduleCode = null,
    Object? permissionCode = null,
    Object? isEnabled = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      roleId: null == roleId
          ? _self.roleId
          : roleId // ignore: cast_nullable_to_non_nullable
              as String,
      moduleCode: null == moduleCode
          ? _self.moduleCode
          : moduleCode // ignore: cast_nullable_to_non_nullable
              as String,
      permissionCode: null == permissionCode
          ? _self.permissionCode
          : permissionCode // ignore: cast_nullable_to_non_nullable
              as String,
      isEnabled: null == isEnabled
          ? _self.isEnabled
          : isEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class _RolePermissionModel implements RolePermissionModel {
  const _RolePermissionModel(
      {required this.id,
      required this.roleId,
      required this.moduleCode,
      required this.permissionCode,
      this.isEnabled = true});
  factory _RolePermissionModel.fromJson(Map<String, dynamic> json) =>
      _$RolePermissionModelFromJson(json);

  @override
  final String id;
  @override
  final String roleId;
  @override
  final String moduleCode;
  @override
  final String permissionCode;
  @override
  @JsonKey()
  final bool isEnabled;

  /// Create a copy of RolePermissionModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RolePermissionModelCopyWith<_RolePermissionModel> get copyWith =>
      __$RolePermissionModelCopyWithImpl<_RolePermissionModel>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$RolePermissionModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _RolePermissionModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.roleId, roleId) || other.roleId == roleId) &&
            (identical(other.moduleCode, moduleCode) ||
                other.moduleCode == moduleCode) &&
            (identical(other.permissionCode, permissionCode) ||
                other.permissionCode == permissionCode) &&
            (identical(other.isEnabled, isEnabled) ||
                other.isEnabled == isEnabled));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, roleId, moduleCode, permissionCode, isEnabled);

  @override
  String toString() {
    return 'RolePermissionModel(id: $id, roleId: $roleId, moduleCode: $moduleCode, permissionCode: $permissionCode, isEnabled: $isEnabled)';
  }
}

/// @nodoc
abstract mixin class _$RolePermissionModelCopyWith<$Res>
    implements $RolePermissionModelCopyWith<$Res> {
  factory _$RolePermissionModelCopyWith(_RolePermissionModel value,
          $Res Function(_RolePermissionModel) _then) =
      __$RolePermissionModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String roleId,
      String moduleCode,
      String permissionCode,
      bool isEnabled});
}

/// @nodoc
class __$RolePermissionModelCopyWithImpl<$Res>
    implements _$RolePermissionModelCopyWith<$Res> {
  __$RolePermissionModelCopyWithImpl(this._self, this._then);

  final _RolePermissionModel _self;
  final $Res Function(_RolePermissionModel) _then;

  /// Create a copy of RolePermissionModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? roleId = null,
    Object? moduleCode = null,
    Object? permissionCode = null,
    Object? isEnabled = null,
  }) {
    return _then(_RolePermissionModel(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      roleId: null == roleId
          ? _self.roleId
          : roleId // ignore: cast_nullable_to_non_nullable
              as String,
      moduleCode: null == moduleCode
          ? _self.moduleCode
          : moduleCode // ignore: cast_nullable_to_non_nullable
              as String,
      permissionCode: null == permissionCode
          ? _self.permissionCode
          : permissionCode // ignore: cast_nullable_to_non_nullable
              as String,
      isEnabled: null == isEnabled
          ? _self.isEnabled
          : isEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on
