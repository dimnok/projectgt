// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'work_search_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WorkSearchResult {
  /// Дата смены.
  DateTime get workDate;

  /// Название объекта.
  String get objectName;

  /// Система.
  String get system;

  /// Подсистема.
  String get subsystem;

  /// Секция (модуль).
  String get section;

  /// Этаж.
  String get floor;

  /// Наименование работы.
  String get workName;

  /// Наименование работы (для совместимости с интерфейсом).
  String get materialName;

  /// Единица измерения.
  String get unit;

  /// Количество.
  num get quantity;

  /// Create a copy of WorkSearchResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WorkSearchResultCopyWith<WorkSearchResult> get copyWith =>
      _$WorkSearchResultCopyWithImpl<WorkSearchResult>(
          this as WorkSearchResult, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WorkSearchResult &&
            (identical(other.workDate, workDate) ||
                other.workDate == workDate) &&
            (identical(other.objectName, objectName) ||
                other.objectName == objectName) &&
            (identical(other.system, system) || other.system == system) &&
            (identical(other.subsystem, subsystem) ||
                other.subsystem == subsystem) &&
            (identical(other.section, section) || other.section == section) &&
            (identical(other.floor, floor) || other.floor == floor) &&
            (identical(other.workName, workName) ||
                other.workName == workName) &&
            (identical(other.materialName, materialName) ||
                other.materialName == materialName) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity));
  }

  @override
  int get hashCode => Object.hash(runtimeType, workDate, objectName, system,
      subsystem, section, floor, workName, materialName, unit, quantity);

  @override
  String toString() {
    return 'WorkSearchResult(workDate: $workDate, objectName: $objectName, system: $system, subsystem: $subsystem, section: $section, floor: $floor, workName: $workName, materialName: $materialName, unit: $unit, quantity: $quantity)';
  }
}

/// @nodoc
abstract mixin class $WorkSearchResultCopyWith<$Res> {
  factory $WorkSearchResultCopyWith(
          WorkSearchResult value, $Res Function(WorkSearchResult) _then) =
      _$WorkSearchResultCopyWithImpl;
  @useResult
  $Res call(
      {DateTime workDate,
      String objectName,
      String system,
      String subsystem,
      String section,
      String floor,
      String workName,
      String materialName,
      String unit,
      num quantity});
}

/// @nodoc
class _$WorkSearchResultCopyWithImpl<$Res>
    implements $WorkSearchResultCopyWith<$Res> {
  _$WorkSearchResultCopyWithImpl(this._self, this._then);

  final WorkSearchResult _self;
  final $Res Function(WorkSearchResult) _then;

  /// Create a copy of WorkSearchResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? workDate = null,
    Object? objectName = null,
    Object? system = null,
    Object? subsystem = null,
    Object? section = null,
    Object? floor = null,
    Object? workName = null,
    Object? materialName = null,
    Object? unit = null,
    Object? quantity = null,
  }) {
    return _then(_self.copyWith(
      workDate: null == workDate
          ? _self.workDate
          : workDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      objectName: null == objectName
          ? _self.objectName
          : objectName // ignore: cast_nullable_to_non_nullable
              as String,
      system: null == system
          ? _self.system
          : system // ignore: cast_nullable_to_non_nullable
              as String,
      subsystem: null == subsystem
          ? _self.subsystem
          : subsystem // ignore: cast_nullable_to_non_nullable
              as String,
      section: null == section
          ? _self.section
          : section // ignore: cast_nullable_to_non_nullable
              as String,
      floor: null == floor
          ? _self.floor
          : floor // ignore: cast_nullable_to_non_nullable
              as String,
      workName: null == workName
          ? _self.workName
          : workName // ignore: cast_nullable_to_non_nullable
              as String,
      materialName: null == materialName
          ? _self.materialName
          : materialName // ignore: cast_nullable_to_non_nullable
              as String,
      unit: null == unit
          ? _self.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _self.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as num,
    ));
  }
}

/// @nodoc

class _WorkSearchResult implements WorkSearchResult {
  const _WorkSearchResult(
      {required this.workDate,
      required this.objectName,
      required this.system,
      required this.subsystem,
      required this.section,
      required this.floor,
      required this.workName,
      required this.materialName,
      required this.unit,
      required this.quantity});

  /// Дата смены.
  @override
  final DateTime workDate;

  /// Название объекта.
  @override
  final String objectName;

  /// Система.
  @override
  final String system;

  /// Подсистема.
  @override
  final String subsystem;

  /// Секция (модуль).
  @override
  final String section;

  /// Этаж.
  @override
  final String floor;

  /// Наименование работы.
  @override
  final String workName;

  /// Наименование работы (для совместимости с интерфейсом).
  @override
  final String materialName;

  /// Единица измерения.
  @override
  final String unit;

  /// Количество.
  @override
  final num quantity;

  /// Create a copy of WorkSearchResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$WorkSearchResultCopyWith<_WorkSearchResult> get copyWith =>
      __$WorkSearchResultCopyWithImpl<_WorkSearchResult>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _WorkSearchResult &&
            (identical(other.workDate, workDate) ||
                other.workDate == workDate) &&
            (identical(other.objectName, objectName) ||
                other.objectName == objectName) &&
            (identical(other.system, system) || other.system == system) &&
            (identical(other.subsystem, subsystem) ||
                other.subsystem == subsystem) &&
            (identical(other.section, section) || other.section == section) &&
            (identical(other.floor, floor) || other.floor == floor) &&
            (identical(other.workName, workName) ||
                other.workName == workName) &&
            (identical(other.materialName, materialName) ||
                other.materialName == materialName) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity));
  }

  @override
  int get hashCode => Object.hash(runtimeType, workDate, objectName, system,
      subsystem, section, floor, workName, materialName, unit, quantity);

  @override
  String toString() {
    return 'WorkSearchResult(workDate: $workDate, objectName: $objectName, system: $system, subsystem: $subsystem, section: $section, floor: $floor, workName: $workName, materialName: $materialName, unit: $unit, quantity: $quantity)';
  }
}

/// @nodoc
abstract mixin class _$WorkSearchResultCopyWith<$Res>
    implements $WorkSearchResultCopyWith<$Res> {
  factory _$WorkSearchResultCopyWith(
          _WorkSearchResult value, $Res Function(_WorkSearchResult) _then) =
      __$WorkSearchResultCopyWithImpl;
  @override
  @useResult
  $Res call(
      {DateTime workDate,
      String objectName,
      String system,
      String subsystem,
      String section,
      String floor,
      String workName,
      String materialName,
      String unit,
      num quantity});
}

/// @nodoc
class __$WorkSearchResultCopyWithImpl<$Res>
    implements _$WorkSearchResultCopyWith<$Res> {
  __$WorkSearchResultCopyWithImpl(this._self, this._then);

  final _WorkSearchResult _self;
  final $Res Function(_WorkSearchResult) _then;

  /// Create a copy of WorkSearchResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? workDate = null,
    Object? objectName = null,
    Object? system = null,
    Object? subsystem = null,
    Object? section = null,
    Object? floor = null,
    Object? workName = null,
    Object? materialName = null,
    Object? unit = null,
    Object? quantity = null,
  }) {
    return _then(_WorkSearchResult(
      workDate: null == workDate
          ? _self.workDate
          : workDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      objectName: null == objectName
          ? _self.objectName
          : objectName // ignore: cast_nullable_to_non_nullable
              as String,
      system: null == system
          ? _self.system
          : system // ignore: cast_nullable_to_non_nullable
              as String,
      subsystem: null == subsystem
          ? _self.subsystem
          : subsystem // ignore: cast_nullable_to_non_nullable
              as String,
      section: null == section
          ? _self.section
          : section // ignore: cast_nullable_to_non_nullable
              as String,
      floor: null == floor
          ? _self.floor
          : floor // ignore: cast_nullable_to_non_nullable
              as String,
      workName: null == workName
          ? _self.workName
          : workName // ignore: cast_nullable_to_non_nullable
              as String,
      materialName: null == materialName
          ? _self.materialName
          : materialName // ignore: cast_nullable_to_non_nullable
              as String,
      unit: null == unit
          ? _self.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _self.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as num,
    ));
  }
}

// dart format on
