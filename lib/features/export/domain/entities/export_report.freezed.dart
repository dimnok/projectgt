// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'export_report.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ExportReport {
  /// Дата смены.
  DateTime get workDate;

  /// Название объекта.
  String get objectName;

  /// Название договора.
  String get contractName;

  /// Система.
  String get system;

  /// Подсистема.
  String get subsystem;

  /// Наименование работы.
  String get workName;

  /// Секция.
  String get section;

  /// Этаж.
  String get floor;

  /// Единица измерения.
  String get unit;

  /// Количество.
  num get quantity;

  /// Цена за единицу.
  double? get price;

  /// Итоговая сумма.
  double? get total;

  /// Имя сотрудника.
  String? get employeeName;

  /// Количество часов.
  num? get hours;

  /// Список материалов (JSON строка).
  String? get materials;

  /// Create a copy of ExportReport
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ExportReportCopyWith<ExportReport> get copyWith =>
      _$ExportReportCopyWithImpl<ExportReport>(
          this as ExportReport, _$identity);

  /// Serializes this ExportReport to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ExportReport &&
            (identical(other.workDate, workDate) ||
                other.workDate == workDate) &&
            (identical(other.objectName, objectName) ||
                other.objectName == objectName) &&
            (identical(other.contractName, contractName) ||
                other.contractName == contractName) &&
            (identical(other.system, system) || other.system == system) &&
            (identical(other.subsystem, subsystem) ||
                other.subsystem == subsystem) &&
            (identical(other.workName, workName) ||
                other.workName == workName) &&
            (identical(other.section, section) || other.section == section) &&
            (identical(other.floor, floor) || other.floor == floor) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.employeeName, employeeName) ||
                other.employeeName == employeeName) &&
            (identical(other.hours, hours) || other.hours == hours) &&
            (identical(other.materials, materials) ||
                other.materials == materials));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      workDate,
      objectName,
      contractName,
      system,
      subsystem,
      workName,
      section,
      floor,
      unit,
      quantity,
      price,
      total,
      employeeName,
      hours,
      materials);

  @override
  String toString() {
    return 'ExportReport(workDate: $workDate, objectName: $objectName, contractName: $contractName, system: $system, subsystem: $subsystem, workName: $workName, section: $section, floor: $floor, unit: $unit, quantity: $quantity, price: $price, total: $total, employeeName: $employeeName, hours: $hours, materials: $materials)';
  }
}

/// @nodoc
abstract mixin class $ExportReportCopyWith<$Res> {
  factory $ExportReportCopyWith(
          ExportReport value, $Res Function(ExportReport) _then) =
      _$ExportReportCopyWithImpl;
  @useResult
  $Res call(
      {DateTime workDate,
      String objectName,
      String contractName,
      String system,
      String subsystem,
      String workName,
      String section,
      String floor,
      String unit,
      num quantity,
      double? price,
      double? total,
      String? employeeName,
      num? hours,
      String? materials});
}

/// @nodoc
class _$ExportReportCopyWithImpl<$Res> implements $ExportReportCopyWith<$Res> {
  _$ExportReportCopyWithImpl(this._self, this._then);

  final ExportReport _self;
  final $Res Function(ExportReport) _then;

  /// Create a copy of ExportReport
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? workDate = null,
    Object? objectName = null,
    Object? contractName = null,
    Object? system = null,
    Object? subsystem = null,
    Object? workName = null,
    Object? section = null,
    Object? floor = null,
    Object? unit = null,
    Object? quantity = null,
    Object? price = freezed,
    Object? total = freezed,
    Object? employeeName = freezed,
    Object? hours = freezed,
    Object? materials = freezed,
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
      contractName: null == contractName
          ? _self.contractName
          : contractName // ignore: cast_nullable_to_non_nullable
              as String,
      system: null == system
          ? _self.system
          : system // ignore: cast_nullable_to_non_nullable
              as String,
      subsystem: null == subsystem
          ? _self.subsystem
          : subsystem // ignore: cast_nullable_to_non_nullable
              as String,
      workName: null == workName
          ? _self.workName
          : workName // ignore: cast_nullable_to_non_nullable
              as String,
      section: null == section
          ? _self.section
          : section // ignore: cast_nullable_to_non_nullable
              as String,
      floor: null == floor
          ? _self.floor
          : floor // ignore: cast_nullable_to_non_nullable
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
      employeeName: freezed == employeeName
          ? _self.employeeName
          : employeeName // ignore: cast_nullable_to_non_nullable
              as String?,
      hours: freezed == hours
          ? _self.hours
          : hours // ignore: cast_nullable_to_non_nullable
              as num?,
      materials: freezed == materials
          ? _self.materials
          : materials // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _ExportReport implements ExportReport {
  const _ExportReport(
      {required this.workDate,
      required this.objectName,
      required this.contractName,
      required this.system,
      required this.subsystem,
      required this.workName,
      required this.section,
      required this.floor,
      required this.unit,
      required this.quantity,
      this.price,
      this.total,
      this.employeeName,
      this.hours,
      this.materials});
  factory _ExportReport.fromJson(Map<String, dynamic> json) =>
      _$ExportReportFromJson(json);

  /// Дата смены.
  @override
  final DateTime workDate;

  /// Название объекта.
  @override
  final String objectName;

  /// Название договора.
  @override
  final String contractName;

  /// Система.
  @override
  final String system;

  /// Подсистема.
  @override
  final String subsystem;

  /// Наименование работы.
  @override
  final String workName;

  /// Секция.
  @override
  final String section;

  /// Этаж.
  @override
  final String floor;

  /// Единица измерения.
  @override
  final String unit;

  /// Количество.
  @override
  final num quantity;

  /// Цена за единицу.
  @override
  final double? price;

  /// Итоговая сумма.
  @override
  final double? total;

  /// Имя сотрудника.
  @override
  final String? employeeName;

  /// Количество часов.
  @override
  final num? hours;

  /// Список материалов (JSON строка).
  @override
  final String? materials;

  /// Create a copy of ExportReport
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ExportReportCopyWith<_ExportReport> get copyWith =>
      __$ExportReportCopyWithImpl<_ExportReport>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ExportReportToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ExportReport &&
            (identical(other.workDate, workDate) ||
                other.workDate == workDate) &&
            (identical(other.objectName, objectName) ||
                other.objectName == objectName) &&
            (identical(other.contractName, contractName) ||
                other.contractName == contractName) &&
            (identical(other.system, system) || other.system == system) &&
            (identical(other.subsystem, subsystem) ||
                other.subsystem == subsystem) &&
            (identical(other.workName, workName) ||
                other.workName == workName) &&
            (identical(other.section, section) || other.section == section) &&
            (identical(other.floor, floor) || other.floor == floor) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.employeeName, employeeName) ||
                other.employeeName == employeeName) &&
            (identical(other.hours, hours) || other.hours == hours) &&
            (identical(other.materials, materials) ||
                other.materials == materials));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      workDate,
      objectName,
      contractName,
      system,
      subsystem,
      workName,
      section,
      floor,
      unit,
      quantity,
      price,
      total,
      employeeName,
      hours,
      materials);

  @override
  String toString() {
    return 'ExportReport(workDate: $workDate, objectName: $objectName, contractName: $contractName, system: $system, subsystem: $subsystem, workName: $workName, section: $section, floor: $floor, unit: $unit, quantity: $quantity, price: $price, total: $total, employeeName: $employeeName, hours: $hours, materials: $materials)';
  }
}

/// @nodoc
abstract mixin class _$ExportReportCopyWith<$Res>
    implements $ExportReportCopyWith<$Res> {
  factory _$ExportReportCopyWith(
          _ExportReport value, $Res Function(_ExportReport) _then) =
      __$ExportReportCopyWithImpl;
  @override
  @useResult
  $Res call(
      {DateTime workDate,
      String objectName,
      String contractName,
      String system,
      String subsystem,
      String workName,
      String section,
      String floor,
      String unit,
      num quantity,
      double? price,
      double? total,
      String? employeeName,
      num? hours,
      String? materials});
}

/// @nodoc
class __$ExportReportCopyWithImpl<$Res>
    implements _$ExportReportCopyWith<$Res> {
  __$ExportReportCopyWithImpl(this._self, this._then);

  final _ExportReport _self;
  final $Res Function(_ExportReport) _then;

  /// Create a copy of ExportReport
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? workDate = null,
    Object? objectName = null,
    Object? contractName = null,
    Object? system = null,
    Object? subsystem = null,
    Object? workName = null,
    Object? section = null,
    Object? floor = null,
    Object? unit = null,
    Object? quantity = null,
    Object? price = freezed,
    Object? total = freezed,
    Object? employeeName = freezed,
    Object? hours = freezed,
    Object? materials = freezed,
  }) {
    return _then(_ExportReport(
      workDate: null == workDate
          ? _self.workDate
          : workDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      objectName: null == objectName
          ? _self.objectName
          : objectName // ignore: cast_nullable_to_non_nullable
              as String,
      contractName: null == contractName
          ? _self.contractName
          : contractName // ignore: cast_nullable_to_non_nullable
              as String,
      system: null == system
          ? _self.system
          : system // ignore: cast_nullable_to_non_nullable
              as String,
      subsystem: null == subsystem
          ? _self.subsystem
          : subsystem // ignore: cast_nullable_to_non_nullable
              as String,
      workName: null == workName
          ? _self.workName
          : workName // ignore: cast_nullable_to_non_nullable
              as String,
      section: null == section
          ? _self.section
          : section // ignore: cast_nullable_to_non_nullable
              as String,
      floor: null == floor
          ? _self.floor
          : floor // ignore: cast_nullable_to_non_nullable
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
      employeeName: freezed == employeeName
          ? _self.employeeName
          : employeeName // ignore: cast_nullable_to_non_nullable
              as String?,
      hours: freezed == hours
          ? _self.hours
          : hours // ignore: cast_nullable_to_non_nullable
              as num?,
      materials: freezed == materials
          ? _self.materials
          : materials // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
