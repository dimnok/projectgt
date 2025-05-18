// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'timesheet_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TimesheetSummary {
  /// Идентификатор сотрудника.
  String get employeeId;

  /// Полное имя сотрудника.
  String get employeeName;

  /// Часы по датам: {'2023-05-01': 8, ...}.
  Map<String, num> get hoursByDate;

  /// Часы по объектам: {'Объект 1': 40, ...}.
  Map<String, num> get hoursByObject;

  /// Общее количество часов.
  num get totalHours;

  /// Create a copy of TimesheetSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TimesheetSummaryCopyWith<TimesheetSummary> get copyWith =>
      _$TimesheetSummaryCopyWithImpl<TimesheetSummary>(
          this as TimesheetSummary, _$identity);

  /// Serializes this TimesheetSummary to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TimesheetSummary &&
            (identical(other.employeeId, employeeId) ||
                other.employeeId == employeeId) &&
            (identical(other.employeeName, employeeName) ||
                other.employeeName == employeeName) &&
            const DeepCollectionEquality()
                .equals(other.hoursByDate, hoursByDate) &&
            const DeepCollectionEquality()
                .equals(other.hoursByObject, hoursByObject) &&
            (identical(other.totalHours, totalHours) ||
                other.totalHours == totalHours));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      employeeId,
      employeeName,
      const DeepCollectionEquality().hash(hoursByDate),
      const DeepCollectionEquality().hash(hoursByObject),
      totalHours);

  @override
  String toString() {
    return 'TimesheetSummary(employeeId: $employeeId, employeeName: $employeeName, hoursByDate: $hoursByDate, hoursByObject: $hoursByObject, totalHours: $totalHours)';
  }
}

/// @nodoc
abstract mixin class $TimesheetSummaryCopyWith<$Res> {
  factory $TimesheetSummaryCopyWith(
          TimesheetSummary value, $Res Function(TimesheetSummary) _then) =
      _$TimesheetSummaryCopyWithImpl;
  @useResult
  $Res call(
      {String employeeId,
      String employeeName,
      Map<String, num> hoursByDate,
      Map<String, num> hoursByObject,
      num totalHours});
}

/// @nodoc
class _$TimesheetSummaryCopyWithImpl<$Res>
    implements $TimesheetSummaryCopyWith<$Res> {
  _$TimesheetSummaryCopyWithImpl(this._self, this._then);

  final TimesheetSummary _self;
  final $Res Function(TimesheetSummary) _then;

  /// Create a copy of TimesheetSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? employeeId = null,
    Object? employeeName = null,
    Object? hoursByDate = null,
    Object? hoursByObject = null,
    Object? totalHours = null,
  }) {
    return _then(_self.copyWith(
      employeeId: null == employeeId
          ? _self.employeeId
          : employeeId // ignore: cast_nullable_to_non_nullable
              as String,
      employeeName: null == employeeName
          ? _self.employeeName
          : employeeName // ignore: cast_nullable_to_non_nullable
              as String,
      hoursByDate: null == hoursByDate
          ? _self.hoursByDate
          : hoursByDate // ignore: cast_nullable_to_non_nullable
              as Map<String, num>,
      hoursByObject: null == hoursByObject
          ? _self.hoursByObject
          : hoursByObject // ignore: cast_nullable_to_non_nullable
              as Map<String, num>,
      totalHours: null == totalHours
          ? _self.totalHours
          : totalHours // ignore: cast_nullable_to_non_nullable
              as num,
    ));
  }
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class _TimesheetSummary implements TimesheetSummary {
  const _TimesheetSummary(
      {required this.employeeId,
      required this.employeeName,
      required final Map<String, num> hoursByDate,
      required final Map<String, num> hoursByObject,
      required this.totalHours})
      : _hoursByDate = hoursByDate,
        _hoursByObject = hoursByObject;
  factory _TimesheetSummary.fromJson(Map<String, dynamic> json) =>
      _$TimesheetSummaryFromJson(json);

  /// Идентификатор сотрудника.
  @override
  final String employeeId;

  /// Полное имя сотрудника.
  @override
  final String employeeName;

  /// Часы по датам: {'2023-05-01': 8, ...}.
  final Map<String, num> _hoursByDate;

  /// Часы по датам: {'2023-05-01': 8, ...}.
  @override
  Map<String, num> get hoursByDate {
    if (_hoursByDate is EqualUnmodifiableMapView) return _hoursByDate;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_hoursByDate);
  }

  /// Часы по объектам: {'Объект 1': 40, ...}.
  final Map<String, num> _hoursByObject;

  /// Часы по объектам: {'Объект 1': 40, ...}.
  @override
  Map<String, num> get hoursByObject {
    if (_hoursByObject is EqualUnmodifiableMapView) return _hoursByObject;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_hoursByObject);
  }

  /// Общее количество часов.
  @override
  final num totalHours;

  /// Create a copy of TimesheetSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TimesheetSummaryCopyWith<_TimesheetSummary> get copyWith =>
      __$TimesheetSummaryCopyWithImpl<_TimesheetSummary>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$TimesheetSummaryToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TimesheetSummary &&
            (identical(other.employeeId, employeeId) ||
                other.employeeId == employeeId) &&
            (identical(other.employeeName, employeeName) ||
                other.employeeName == employeeName) &&
            const DeepCollectionEquality()
                .equals(other._hoursByDate, _hoursByDate) &&
            const DeepCollectionEquality()
                .equals(other._hoursByObject, _hoursByObject) &&
            (identical(other.totalHours, totalHours) ||
                other.totalHours == totalHours));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      employeeId,
      employeeName,
      const DeepCollectionEquality().hash(_hoursByDate),
      const DeepCollectionEquality().hash(_hoursByObject),
      totalHours);

  @override
  String toString() {
    return 'TimesheetSummary(employeeId: $employeeId, employeeName: $employeeName, hoursByDate: $hoursByDate, hoursByObject: $hoursByObject, totalHours: $totalHours)';
  }
}

/// @nodoc
abstract mixin class _$TimesheetSummaryCopyWith<$Res>
    implements $TimesheetSummaryCopyWith<$Res> {
  factory _$TimesheetSummaryCopyWith(
          _TimesheetSummary value, $Res Function(_TimesheetSummary) _then) =
      __$TimesheetSummaryCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String employeeId,
      String employeeName,
      Map<String, num> hoursByDate,
      Map<String, num> hoursByObject,
      num totalHours});
}

/// @nodoc
class __$TimesheetSummaryCopyWithImpl<$Res>
    implements _$TimesheetSummaryCopyWith<$Res> {
  __$TimesheetSummaryCopyWithImpl(this._self, this._then);

  final _TimesheetSummary _self;
  final $Res Function(_TimesheetSummary) _then;

  /// Create a copy of TimesheetSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? employeeId = null,
    Object? employeeName = null,
    Object? hoursByDate = null,
    Object? hoursByObject = null,
    Object? totalHours = null,
  }) {
    return _then(_TimesheetSummary(
      employeeId: null == employeeId
          ? _self.employeeId
          : employeeId // ignore: cast_nullable_to_non_nullable
              as String,
      employeeName: null == employeeName
          ? _self.employeeName
          : employeeName // ignore: cast_nullable_to_non_nullable
              as String,
      hoursByDate: null == hoursByDate
          ? _self._hoursByDate
          : hoursByDate // ignore: cast_nullable_to_non_nullable
              as Map<String, num>,
      hoursByObject: null == hoursByObject
          ? _self._hoursByObject
          : hoursByObject // ignore: cast_nullable_to_non_nullable
              as Map<String, num>,
      totalHours: null == totalHours
          ? _self.totalHours
          : totalHours // ignore: cast_nullable_to_non_nullable
              as num,
    ));
  }
}

// dart format on
