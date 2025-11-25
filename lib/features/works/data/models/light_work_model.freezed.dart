// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'light_work_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LightWorkModel {
  /// Идентификатор смены.
  String get id;

  /// Дата смены.
  DateTime get date;

  /// Общая сумма выработки.
  @JsonKey(name: 'total_amount')
  double get totalAmount;

  /// Количество сотрудников.
  @JsonKey(name: 'employees_count')
  int get employeesCount;

  /// Create a copy of LightWorkModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $LightWorkModelCopyWith<LightWorkModel> get copyWith =>
      _$LightWorkModelCopyWithImpl<LightWorkModel>(
          this as LightWorkModel, _$identity);

  /// Serializes this LightWorkModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is LightWorkModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.totalAmount, totalAmount) ||
                other.totalAmount == totalAmount) &&
            (identical(other.employeesCount, employeesCount) ||
                other.employeesCount == employeesCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, date, totalAmount, employeesCount);

  @override
  String toString() {
    return 'LightWorkModel(id: $id, date: $date, totalAmount: $totalAmount, employeesCount: $employeesCount)';
  }
}

/// @nodoc
abstract mixin class $LightWorkModelCopyWith<$Res> {
  factory $LightWorkModelCopyWith(
          LightWorkModel value, $Res Function(LightWorkModel) _then) =
      _$LightWorkModelCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      DateTime date,
      @JsonKey(name: 'total_amount') double totalAmount,
      @JsonKey(name: 'employees_count') int employeesCount});
}

/// @nodoc
class _$LightWorkModelCopyWithImpl<$Res>
    implements $LightWorkModelCopyWith<$Res> {
  _$LightWorkModelCopyWithImpl(this._self, this._then);

  final LightWorkModel _self;
  final $Res Function(LightWorkModel) _then;

  /// Create a copy of LightWorkModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? date = null,
    Object? totalAmount = null,
    Object? employeesCount = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _self.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      totalAmount: null == totalAmount
          ? _self.totalAmount
          : totalAmount // ignore: cast_nullable_to_non_nullable
              as double,
      employeesCount: null == employeesCount
          ? _self.employeesCount
          : employeesCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _LightWorkModel implements LightWorkModel {
  const _LightWorkModel(
      {required this.id,
      required this.date,
      @JsonKey(name: 'total_amount') required this.totalAmount,
      @JsonKey(name: 'employees_count') this.employeesCount = 0});
  factory _LightWorkModel.fromJson(Map<String, dynamic> json) =>
      _$LightWorkModelFromJson(json);

  /// Идентификатор смены.
  @override
  final String id;

  /// Дата смены.
  @override
  final DateTime date;

  /// Общая сумма выработки.
  @override
  @JsonKey(name: 'total_amount')
  final double totalAmount;

  /// Количество сотрудников.
  @override
  @JsonKey(name: 'employees_count')
  final int employeesCount;

  /// Create a copy of LightWorkModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$LightWorkModelCopyWith<_LightWorkModel> get copyWith =>
      __$LightWorkModelCopyWithImpl<_LightWorkModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$LightWorkModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _LightWorkModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.totalAmount, totalAmount) ||
                other.totalAmount == totalAmount) &&
            (identical(other.employeesCount, employeesCount) ||
                other.employeesCount == employeesCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, date, totalAmount, employeesCount);

  @override
  String toString() {
    return 'LightWorkModel(id: $id, date: $date, totalAmount: $totalAmount, employeesCount: $employeesCount)';
  }
}

/// @nodoc
abstract mixin class _$LightWorkModelCopyWith<$Res>
    implements $LightWorkModelCopyWith<$Res> {
  factory _$LightWorkModelCopyWith(
          _LightWorkModel value, $Res Function(_LightWorkModel) _then) =
      __$LightWorkModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      DateTime date,
      @JsonKey(name: 'total_amount') double totalAmount,
      @JsonKey(name: 'employees_count') int employeesCount});
}

/// @nodoc
class __$LightWorkModelCopyWithImpl<$Res>
    implements _$LightWorkModelCopyWith<$Res> {
  __$LightWorkModelCopyWithImpl(this._self, this._then);

  final _LightWorkModel _self;
  final $Res Function(_LightWorkModel) _then;

  /// Create a copy of LightWorkModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? date = null,
    Object? totalAmount = null,
    Object? employeesCount = null,
  }) {
    return _then(_LightWorkModel(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _self.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      totalAmount: null == totalAmount
          ? _self.totalAmount
          : totalAmount // ignore: cast_nullable_to_non_nullable
              as double,
      employeesCount: null == employeesCount
          ? _self.employeesCount
          : employeesCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

// dart format on
