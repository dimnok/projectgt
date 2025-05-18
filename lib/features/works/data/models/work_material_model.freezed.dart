// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'work_material_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WorkMaterialModel {
  /// Идентификатор материала.
  String get id;

  /// Идентификатор смены.
  @JsonKey(name: 'work_id')
  String get workId;

  /// Наименование материала.
  String get name;

  /// Единица измерения.
  String get unit;

  /// Количество.
  num get quantity;

  /// Комментарий к материалу.
  String? get comment;

  /// Дата создания записи.
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;

  /// Дата последнего обновления.
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of WorkMaterialModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WorkMaterialModelCopyWith<WorkMaterialModel> get copyWith =>
      _$WorkMaterialModelCopyWithImpl<WorkMaterialModel>(
          this as WorkMaterialModel, _$identity);

  /// Serializes this WorkMaterialModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WorkMaterialModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.workId, workId) || other.workId == workId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.comment, comment) || other.comment == comment) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, workId, name, unit, quantity,
      comment, createdAt, updatedAt);

  @override
  String toString() {
    return 'WorkMaterialModel(id: $id, workId: $workId, name: $name, unit: $unit, quantity: $quantity, comment: $comment, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class $WorkMaterialModelCopyWith<$Res> {
  factory $WorkMaterialModelCopyWith(
          WorkMaterialModel value, $Res Function(WorkMaterialModel) _then) =
      _$WorkMaterialModelCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'work_id') String workId,
      String name,
      String unit,
      num quantity,
      String? comment,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class _$WorkMaterialModelCopyWithImpl<$Res>
    implements $WorkMaterialModelCopyWith<$Res> {
  _$WorkMaterialModelCopyWithImpl(this._self, this._then);

  final WorkMaterialModel _self;
  final $Res Function(WorkMaterialModel) _then;

  /// Create a copy of WorkMaterialModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? workId = null,
    Object? name = null,
    Object? unit = null,
    Object? quantity = null,
    Object? comment = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      workId: null == workId
          ? _self.workId
          : workId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      unit: null == unit
          ? _self.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _self.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as num,
      comment: freezed == comment
          ? _self.comment
          : comment // ignore: cast_nullable_to_non_nullable
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
class _WorkMaterialModel implements WorkMaterialModel {
  const _WorkMaterialModel(
      {required this.id,
      @JsonKey(name: 'work_id') required this.workId,
      required this.name,
      required this.unit,
      required this.quantity,
      this.comment,
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'updated_at') this.updatedAt});
  factory _WorkMaterialModel.fromJson(Map<String, dynamic> json) =>
      _$WorkMaterialModelFromJson(json);

  /// Идентификатор материала.
  @override
  final String id;

  /// Идентификатор смены.
  @override
  @JsonKey(name: 'work_id')
  final String workId;

  /// Наименование материала.
  @override
  final String name;

  /// Единица измерения.
  @override
  final String unit;

  /// Количество.
  @override
  final num quantity;

  /// Комментарий к материалу.
  @override
  final String? comment;

  /// Дата создания записи.
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  /// Дата последнего обновления.
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  /// Create a copy of WorkMaterialModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$WorkMaterialModelCopyWith<_WorkMaterialModel> get copyWith =>
      __$WorkMaterialModelCopyWithImpl<_WorkMaterialModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$WorkMaterialModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _WorkMaterialModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.workId, workId) || other.workId == workId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.comment, comment) || other.comment == comment) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, workId, name, unit, quantity,
      comment, createdAt, updatedAt);

  @override
  String toString() {
    return 'WorkMaterialModel(id: $id, workId: $workId, name: $name, unit: $unit, quantity: $quantity, comment: $comment, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$WorkMaterialModelCopyWith<$Res>
    implements $WorkMaterialModelCopyWith<$Res> {
  factory _$WorkMaterialModelCopyWith(
          _WorkMaterialModel value, $Res Function(_WorkMaterialModel) _then) =
      __$WorkMaterialModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'work_id') String workId,
      String name,
      String unit,
      num quantity,
      String? comment,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class __$WorkMaterialModelCopyWithImpl<$Res>
    implements _$WorkMaterialModelCopyWith<$Res> {
  __$WorkMaterialModelCopyWithImpl(this._self, this._then);

  final _WorkMaterialModel _self;
  final $Res Function(_WorkMaterialModel) _then;

  /// Create a copy of WorkMaterialModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? workId = null,
    Object? name = null,
    Object? unit = null,
    Object? quantity = null,
    Object? comment = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_WorkMaterialModel(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      workId: null == workId
          ? _self.workId
          : workId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      unit: null == unit
          ? _self.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _self.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as num,
      comment: freezed == comment
          ? _self.comment
          : comment // ignore: cast_nullable_to_non_nullable
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
