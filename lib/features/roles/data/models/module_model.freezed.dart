// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'module_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ModuleModel {
  String get id;
  String get code;
  String get name;
  String? get description;
  String get iconKey;
  int get sortOrder;

  /// Create a copy of ModuleModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ModuleModelCopyWith<ModuleModel> get copyWith =>
      _$ModuleModelCopyWithImpl<ModuleModel>(this as ModuleModel, _$identity);

  /// Serializes this ModuleModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ModuleModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.iconKey, iconKey) || other.iconKey == iconKey) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, code, name, description, iconKey, sortOrder);

  @override
  String toString() {
    return 'ModuleModel(id: $id, code: $code, name: $name, description: $description, iconKey: $iconKey, sortOrder: $sortOrder)';
  }
}

/// @nodoc
abstract mixin class $ModuleModelCopyWith<$Res> {
  factory $ModuleModelCopyWith(
          ModuleModel value, $Res Function(ModuleModel) _then) =
      _$ModuleModelCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String code,
      String name,
      String? description,
      String iconKey,
      int sortOrder});
}

/// @nodoc
class _$ModuleModelCopyWithImpl<$Res> implements $ModuleModelCopyWith<$Res> {
  _$ModuleModelCopyWithImpl(this._self, this._then);

  final ModuleModel _self;
  final $Res Function(ModuleModel) _then;

  /// Create a copy of ModuleModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? code = null,
    Object? name = null,
    Object? description = freezed,
    Object? iconKey = null,
    Object? sortOrder = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      code: null == code
          ? _self.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      iconKey: null == iconKey
          ? _self.iconKey
          : iconKey // ignore: cast_nullable_to_non_nullable
              as String,
      sortOrder: null == sortOrder
          ? _self.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class _ModuleModel extends ModuleModel {
  const _ModuleModel(
      {required this.id,
      required this.code,
      required this.name,
      this.description,
      required this.iconKey,
      this.sortOrder = 0})
      : super._();
  factory _ModuleModel.fromJson(Map<String, dynamic> json) =>
      _$ModuleModelFromJson(json);

  @override
  final String id;
  @override
  final String code;
  @override
  final String name;
  @override
  final String? description;
  @override
  final String iconKey;
  @override
  @JsonKey()
  final int sortOrder;

  /// Create a copy of ModuleModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ModuleModelCopyWith<_ModuleModel> get copyWith =>
      __$ModuleModelCopyWithImpl<_ModuleModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ModuleModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ModuleModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.iconKey, iconKey) || other.iconKey == iconKey) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, code, name, description, iconKey, sortOrder);

  @override
  String toString() {
    return 'ModuleModel(id: $id, code: $code, name: $name, description: $description, iconKey: $iconKey, sortOrder: $sortOrder)';
  }
}

/// @nodoc
abstract mixin class _$ModuleModelCopyWith<$Res>
    implements $ModuleModelCopyWith<$Res> {
  factory _$ModuleModelCopyWith(
          _ModuleModel value, $Res Function(_ModuleModel) _then) =
      __$ModuleModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String code,
      String name,
      String? description,
      String iconKey,
      int sortOrder});
}

/// @nodoc
class __$ModuleModelCopyWithImpl<$Res> implements _$ModuleModelCopyWith<$Res> {
  __$ModuleModelCopyWithImpl(this._self, this._then);

  final _ModuleModel _self;
  final $Res Function(_ModuleModel) _then;

  /// Create a copy of ModuleModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? code = null,
    Object? name = null,
    Object? description = freezed,
    Object? iconKey = null,
    Object? sortOrder = null,
  }) {
    return _then(_ModuleModel(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      code: null == code
          ? _self.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      iconKey: null == iconKey
          ? _self.iconKey
          : iconKey // ignore: cast_nullable_to_non_nullable
              as String,
      sortOrder: null == sortOrder
          ? _self.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

// dart format on
