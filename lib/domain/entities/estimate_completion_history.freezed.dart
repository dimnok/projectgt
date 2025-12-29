// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'estimate_completion_history.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EstimateCompletionHistory {
  DateTime get date;
  double get quantity;
  String get section;
  String get floor;

  /// Create a copy of EstimateCompletionHistory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $EstimateCompletionHistoryCopyWith<EstimateCompletionHistory> get copyWith =>
      _$EstimateCompletionHistoryCopyWithImpl<EstimateCompletionHistory>(
          this as EstimateCompletionHistory, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is EstimateCompletionHistory &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.section, section) || other.section == section) &&
            (identical(other.floor, floor) || other.floor == floor));
  }

  @override
  int get hashCode => Object.hash(runtimeType, date, quantity, section, floor);

  @override
  String toString() {
    return 'EstimateCompletionHistory(date: $date, quantity: $quantity, section: $section, floor: $floor)';
  }
}

/// @nodoc
abstract mixin class $EstimateCompletionHistoryCopyWith<$Res> {
  factory $EstimateCompletionHistoryCopyWith(EstimateCompletionHistory value,
          $Res Function(EstimateCompletionHistory) _then) =
      _$EstimateCompletionHistoryCopyWithImpl;
  @useResult
  $Res call({DateTime date, double quantity, String section, String floor});
}

/// @nodoc
class _$EstimateCompletionHistoryCopyWithImpl<$Res>
    implements $EstimateCompletionHistoryCopyWith<$Res> {
  _$EstimateCompletionHistoryCopyWithImpl(this._self, this._then);

  final EstimateCompletionHistory _self;
  final $Res Function(EstimateCompletionHistory) _then;

  /// Create a copy of EstimateCompletionHistory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? quantity = null,
    Object? section = null,
    Object? floor = null,
  }) {
    return _then(_self.copyWith(
      date: null == date
          ? _self.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      quantity: null == quantity
          ? _self.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double,
      section: null == section
          ? _self.section
          : section // ignore: cast_nullable_to_non_nullable
              as String,
      floor: null == floor
          ? _self.floor
          : floor // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _EstimateCompletionHistory implements EstimateCompletionHistory {
  const _EstimateCompletionHistory(
      {required this.date,
      required this.quantity,
      required this.section,
      required this.floor});

  @override
  final DateTime date;
  @override
  final double quantity;
  @override
  final String section;
  @override
  final String floor;

  /// Create a copy of EstimateCompletionHistory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$EstimateCompletionHistoryCopyWith<_EstimateCompletionHistory>
      get copyWith =>
          __$EstimateCompletionHistoryCopyWithImpl<_EstimateCompletionHistory>(
              this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _EstimateCompletionHistory &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.section, section) || other.section == section) &&
            (identical(other.floor, floor) || other.floor == floor));
  }

  @override
  int get hashCode => Object.hash(runtimeType, date, quantity, section, floor);

  @override
  String toString() {
    return 'EstimateCompletionHistory(date: $date, quantity: $quantity, section: $section, floor: $floor)';
  }
}

/// @nodoc
abstract mixin class _$EstimateCompletionHistoryCopyWith<$Res>
    implements $EstimateCompletionHistoryCopyWith<$Res> {
  factory _$EstimateCompletionHistoryCopyWith(_EstimateCompletionHistory value,
          $Res Function(_EstimateCompletionHistory) _then) =
      __$EstimateCompletionHistoryCopyWithImpl;
  @override
  @useResult
  $Res call({DateTime date, double quantity, String section, String floor});
}

/// @nodoc
class __$EstimateCompletionHistoryCopyWithImpl<$Res>
    implements _$EstimateCompletionHistoryCopyWith<$Res> {
  __$EstimateCompletionHistoryCopyWithImpl(this._self, this._then);

  final _EstimateCompletionHistory _self;
  final $Res Function(_EstimateCompletionHistory) _then;

  /// Create a copy of EstimateCompletionHistory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? date = null,
    Object? quantity = null,
    Object? section = null,
    Object? floor = null,
  }) {
    return _then(_EstimateCompletionHistory(
      date: null == date
          ? _self.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      quantity: null == quantity
          ? _self.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double,
      section: null == section
          ? _self.section
          : section // ignore: cast_nullable_to_non_nullable
              as String,
      floor: null == floor
          ? _self.floor
          : floor // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
