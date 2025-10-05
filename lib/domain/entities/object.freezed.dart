// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'object.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ObjectEntity {
  /// Уникальный идентификатор объекта.
  String get id;

  /// Название объекта.
  String get name;

  /// Адрес объекта.
  String get address;

  /// Описание объекта.
  String? get description;

  /// Create a copy of ObjectEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ObjectEntityCopyWith<ObjectEntity> get copyWith =>
      _$ObjectEntityCopyWithImpl<ObjectEntity>(
          this as ObjectEntity, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ObjectEntity &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, name, address, description);

  @override
  String toString() {
    return 'ObjectEntity(id: $id, name: $name, address: $address, description: $description)';
  }
}

/// @nodoc
abstract mixin class $ObjectEntityCopyWith<$Res> {
  factory $ObjectEntityCopyWith(
          ObjectEntity value, $Res Function(ObjectEntity) _then) =
      _$ObjectEntityCopyWithImpl;
  @useResult
  $Res call({String id, String name, String address, String? description});
}

/// @nodoc
class _$ObjectEntityCopyWithImpl<$Res> implements $ObjectEntityCopyWith<$Res> {
  _$ObjectEntityCopyWithImpl(this._self, this._then);

  final ObjectEntity _self;
  final $Res Function(ObjectEntity) _then;

  /// Create a copy of ObjectEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? address = null,
    Object? description = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      address: null == address
          ? _self.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _ObjectEntity extends ObjectEntity {
  const _ObjectEntity(
      {required this.id,
      required this.name,
      required this.address,
      this.description})
      : super._();

  /// Уникальный идентификатор объекта.
  @override
  final String id;

  /// Название объекта.
  @override
  final String name;

  /// Адрес объекта.
  @override
  final String address;

  /// Описание объекта.
  @override
  final String? description;

  /// Create a copy of ObjectEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ObjectEntityCopyWith<_ObjectEntity> get copyWith =>
      __$ObjectEntityCopyWithImpl<_ObjectEntity>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ObjectEntity &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, name, address, description);

  @override
  String toString() {
    return 'ObjectEntity(id: $id, name: $name, address: $address, description: $description)';
  }
}

/// @nodoc
abstract mixin class _$ObjectEntityCopyWith<$Res>
    implements $ObjectEntityCopyWith<$Res> {
  factory _$ObjectEntityCopyWith(
          _ObjectEntity value, $Res Function(_ObjectEntity) _then) =
      __$ObjectEntityCopyWithImpl;
  @override
  @useResult
  $Res call({String id, String name, String address, String? description});
}

/// @nodoc
class __$ObjectEntityCopyWithImpl<$Res>
    implements _$ObjectEntityCopyWith<$Res> {
  __$ObjectEntityCopyWithImpl(this._self, this._then);

  final _ObjectEntity _self;
  final $Res Function(_ObjectEntity) _then;

  /// Create a copy of ObjectEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? address = null,
    Object? description = freezed,
  }) {
    return _then(_ObjectEntity(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      address: null == address
          ? _self.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
