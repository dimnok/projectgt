// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'work_item_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WorkItemModel {
  /// Идентификатор работы.
  String get id;

  /// Идентификатор смены.
  @JsonKey(name: 'work_id')
  String get workId;

  /// Секция.
  String get section;

  /// Этаж.
  String get floor;

  /// Идентификатор сметы.
  @JsonKey(name: 'estimate_id')
  String get estimateId;

  /// Наименование работы.
  String get name;

  /// Система.
  String get system;

  /// Подсистема.
  String get subsystem;

  /// Единица измерения.
  String get unit;

  /// Объём/количество.
  num get quantity;

  /// Цена за единицу.
  double? get price;

  /// Итоговая сумма.
  double? get total;

  /// Дата создания записи.
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;

  /// Дата последнего обновления.
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of WorkItemModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WorkItemModelCopyWith<WorkItemModel> get copyWith =>
      _$WorkItemModelCopyWithImpl<WorkItemModel>(
          this as WorkItemModel, _$identity);

  /// Serializes this WorkItemModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WorkItemModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.workId, workId) || other.workId == workId) &&
            (identical(other.section, section) || other.section == section) &&
            (identical(other.floor, floor) || other.floor == floor) &&
            (identical(other.estimateId, estimateId) ||
                other.estimateId == estimateId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.system, system) || other.system == system) &&
            (identical(other.subsystem, subsystem) ||
                other.subsystem == subsystem) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      workId,
      section,
      floor,
      estimateId,
      name,
      system,
      subsystem,
      unit,
      quantity,
      price,
      total,
      createdAt,
      updatedAt);

  @override
  String toString() {
    return 'WorkItemModel(id: $id, workId: $workId, section: $section, floor: $floor, estimateId: $estimateId, name: $name, system: $system, subsystem: $subsystem, unit: $unit, quantity: $quantity, price: $price, total: $total, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class $WorkItemModelCopyWith<$Res> {
  factory $WorkItemModelCopyWith(
          WorkItemModel value, $Res Function(WorkItemModel) _then) =
      _$WorkItemModelCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'work_id') String workId,
      String section,
      String floor,
      @JsonKey(name: 'estimate_id') String estimateId,
      String name,
      String system,
      String subsystem,
      String unit,
      num quantity,
      double? price,
      double? total,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class _$WorkItemModelCopyWithImpl<$Res>
    implements $WorkItemModelCopyWith<$Res> {
  _$WorkItemModelCopyWithImpl(this._self, this._then);

  final WorkItemModel _self;
  final $Res Function(WorkItemModel) _then;

  /// Create a copy of WorkItemModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? workId = null,
    Object? section = null,
    Object? floor = null,
    Object? estimateId = null,
    Object? name = null,
    Object? system = null,
    Object? subsystem = null,
    Object? unit = null,
    Object? quantity = null,
    Object? price = freezed,
    Object? total = freezed,
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
      section: null == section
          ? _self.section
          : section // ignore: cast_nullable_to_non_nullable
              as String,
      floor: null == floor
          ? _self.floor
          : floor // ignore: cast_nullable_to_non_nullable
              as String,
      estimateId: null == estimateId
          ? _self.estimateId
          : estimateId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      system: null == system
          ? _self.system
          : system // ignore: cast_nullable_to_non_nullable
              as String,
      subsystem: null == subsystem
          ? _self.subsystem
          : subsystem // ignore: cast_nullable_to_non_nullable
              as String,
      unit: null == unit
          ? _self.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _self.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as num,
      price: freezed == price
          ? _self.price
          : price // ignore: cast_nullable_to_non_nullable
              as double?,
      total: freezed == total
          ? _self.total
          : total // ignore: cast_nullable_to_non_nullable
              as double?,
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
class _WorkItemModel implements WorkItemModel {
  const _WorkItemModel(
      {required this.id,
      @JsonKey(name: 'work_id') required this.workId,
      required this.section,
      required this.floor,
      @JsonKey(name: 'estimate_id') required this.estimateId,
      required this.name,
      required this.system,
      required this.subsystem,
      required this.unit,
      required this.quantity,
      this.price,
      this.total,
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'updated_at') this.updatedAt});
  factory _WorkItemModel.fromJson(Map<String, dynamic> json) =>
      _$WorkItemModelFromJson(json);

  /// Идентификатор работы.
  @override
  final String id;

  /// Идентификатор смены.
  @override
  @JsonKey(name: 'work_id')
  final String workId;

  /// Секция.
  @override
  final String section;

  /// Этаж.
  @override
  final String floor;

  /// Идентификатор сметы.
  @override
  @JsonKey(name: 'estimate_id')
  final String estimateId;

  /// Наименование работы.
  @override
  final String name;

  /// Система.
  @override
  final String system;

  /// Подсистема.
  @override
  final String subsystem;

  /// Единица измерения.
  @override
  final String unit;

  /// Объём/количество.
  @override
  final num quantity;

  /// Цена за единицу.
  @override
  final double? price;

  /// Итоговая сумма.
  @override
  final double? total;

  /// Дата создания записи.
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  /// Дата последнего обновления.
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  /// Create a copy of WorkItemModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$WorkItemModelCopyWith<_WorkItemModel> get copyWith =>
      __$WorkItemModelCopyWithImpl<_WorkItemModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$WorkItemModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _WorkItemModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.workId, workId) || other.workId == workId) &&
            (identical(other.section, section) || other.section == section) &&
            (identical(other.floor, floor) || other.floor == floor) &&
            (identical(other.estimateId, estimateId) ||
                other.estimateId == estimateId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.system, system) || other.system == system) &&
            (identical(other.subsystem, subsystem) ||
                other.subsystem == subsystem) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      workId,
      section,
      floor,
      estimateId,
      name,
      system,
      subsystem,
      unit,
      quantity,
      price,
      total,
      createdAt,
      updatedAt);

  @override
  String toString() {
    return 'WorkItemModel(id: $id, workId: $workId, section: $section, floor: $floor, estimateId: $estimateId, name: $name, system: $system, subsystem: $subsystem, unit: $unit, quantity: $quantity, price: $price, total: $total, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$WorkItemModelCopyWith<$Res>
    implements $WorkItemModelCopyWith<$Res> {
  factory _$WorkItemModelCopyWith(
          _WorkItemModel value, $Res Function(_WorkItemModel) _then) =
      __$WorkItemModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'work_id') String workId,
      String section,
      String floor,
      @JsonKey(name: 'estimate_id') String estimateId,
      String name,
      String system,
      String subsystem,
      String unit,
      num quantity,
      double? price,
      double? total,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class __$WorkItemModelCopyWithImpl<$Res>
    implements _$WorkItemModelCopyWith<$Res> {
  __$WorkItemModelCopyWithImpl(this._self, this._then);

  final _WorkItemModel _self;
  final $Res Function(_WorkItemModel) _then;

  /// Create a copy of WorkItemModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? workId = null,
    Object? section = null,
    Object? floor = null,
    Object? estimateId = null,
    Object? name = null,
    Object? system = null,
    Object? subsystem = null,
    Object? unit = null,
    Object? quantity = null,
    Object? price = freezed,
    Object? total = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_WorkItemModel(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      workId: null == workId
          ? _self.workId
          : workId // ignore: cast_nullable_to_non_nullable
              as String,
      section: null == section
          ? _self.section
          : section // ignore: cast_nullable_to_non_nullable
              as String,
      floor: null == floor
          ? _self.floor
          : floor // ignore: cast_nullable_to_non_nullable
              as String,
      estimateId: null == estimateId
          ? _self.estimateId
          : estimateId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      system: null == system
          ? _self.system
          : system // ignore: cast_nullable_to_non_nullable
              as String,
      subsystem: null == subsystem
          ? _self.subsystem
          : subsystem // ignore: cast_nullable_to_non_nullable
              as String,
      unit: null == unit
          ? _self.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _self.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as num,
      price: freezed == price
          ? _self.price
          : price // ignore: cast_nullable_to_non_nullable
              as double?,
      total: freezed == total
          ? _self.total
          : total // ignore: cast_nullable_to_non_nullable
              as double?,
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
