// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'export_report_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ExportReportModel {
  /// Дата смены.
  @JsonKey(name: 'work_date')
  DateTime get workDate;

  /// Название объекта.
  @JsonKey(name: 'object_name')
  String get objectName;

  /// Название договора.
  @JsonKey(name: 'contract_name')
  String get contractName;

  /// Система.
  String get system;

  /// Подсистема.
  String get subsystem;

  /// Номер позиции в смете.
  @JsonKey(name: 'position_number')
  String get positionNumber;

  /// Наименование работы.
  @JsonKey(name: 'work_name')
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
  @JsonKey(name: 'employee_name')
  String? get employeeName;

  /// Количество часов.
  num? get hours;

  /// Список материалов (JSON строка).
  String? get materials;

  /// Create a copy of ExportReportModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ExportReportModelCopyWith<ExportReportModel> get copyWith =>
      _$ExportReportModelCopyWithImpl<ExportReportModel>(
          this as ExportReportModel, _$identity);

  /// Serializes this ExportReportModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ExportReportModel &&
            (identical(other.workDate, workDate) ||
                other.workDate == workDate) &&
            (identical(other.objectName, objectName) ||
                other.objectName == objectName) &&
            (identical(other.contractName, contractName) ||
                other.contractName == contractName) &&
            (identical(other.system, system) || other.system == system) &&
            (identical(other.subsystem, subsystem) ||
                other.subsystem == subsystem) &&
            (identical(other.positionNumber, positionNumber) ||
                other.positionNumber == positionNumber) &&
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
      positionNumber,
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
    return 'ExportReportModel(workDate: $workDate, objectName: $objectName, contractName: $contractName, system: $system, subsystem: $subsystem, positionNumber: $positionNumber, workName: $workName, section: $section, floor: $floor, unit: $unit, quantity: $quantity, price: $price, total: $total, employeeName: $employeeName, hours: $hours, materials: $materials)';
  }
}

/// @nodoc
abstract mixin class $ExportReportModelCopyWith<$Res> {
  factory $ExportReportModelCopyWith(
          ExportReportModel value, $Res Function(ExportReportModel) _then) =
      _$ExportReportModelCopyWithImpl;
  @useResult
  $Res call(
      {@JsonKey(name: 'work_date') DateTime workDate,
      @JsonKey(name: 'object_name') String objectName,
      @JsonKey(name: 'contract_name') String contractName,
      String system,
      String subsystem,
      @JsonKey(name: 'position_number') String positionNumber,
      @JsonKey(name: 'work_name') String workName,
      String section,
      String floor,
      String unit,
      num quantity,
      double? price,
      double? total,
      @JsonKey(name: 'employee_name') String? employeeName,
      num? hours,
      String? materials});
}

/// @nodoc
class _$ExportReportModelCopyWithImpl<$Res>
    implements $ExportReportModelCopyWith<$Res> {
  _$ExportReportModelCopyWithImpl(this._self, this._then);

  final ExportReportModel _self;
  final $Res Function(ExportReportModel) _then;

  /// Create a copy of ExportReportModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? workDate = null,
    Object? objectName = null,
    Object? contractName = null,
    Object? system = null,
    Object? subsystem = null,
    Object? positionNumber = null,
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
      positionNumber: null == positionNumber
          ? _self.positionNumber
          : positionNumber // ignore: cast_nullable_to_non_nullable
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
class _ExportReportModel implements ExportReportModel {
  const _ExportReportModel(
      {@JsonKey(name: 'work_date') required this.workDate,
      @JsonKey(name: 'object_name') required this.objectName,
      @JsonKey(name: 'contract_name') required this.contractName,
      required this.system,
      required this.subsystem,
      @JsonKey(name: 'position_number') required this.positionNumber,
      @JsonKey(name: 'work_name') required this.workName,
      required this.section,
      required this.floor,
      required this.unit,
      required this.quantity,
      this.price,
      this.total,
      @JsonKey(name: 'employee_name') this.employeeName,
      this.hours,
      this.materials});
  factory _ExportReportModel.fromJson(Map<String, dynamic> json) =>
      _$ExportReportModelFromJson(json);

  /// Дата смены.
  @override
  @JsonKey(name: 'work_date')
  final DateTime workDate;

  /// Название объекта.
  @override
  @JsonKey(name: 'object_name')
  final String objectName;

  /// Название договора.
  @override
  @JsonKey(name: 'contract_name')
  final String contractName;

  /// Система.
  @override
  final String system;

  /// Подсистема.
  @override
  final String subsystem;

  /// Номер позиции в смете.
  @override
  @JsonKey(name: 'position_number')
  final String positionNumber;

  /// Наименование работы.
  @override
  @JsonKey(name: 'work_name')
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
  @JsonKey(name: 'employee_name')
  final String? employeeName;

  /// Количество часов.
  @override
  final num? hours;

  /// Список материалов (JSON строка).
  @override
  final String? materials;

  /// Create a copy of ExportReportModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ExportReportModelCopyWith<_ExportReportModel> get copyWith =>
      __$ExportReportModelCopyWithImpl<_ExportReportModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ExportReportModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ExportReportModel &&
            (identical(other.workDate, workDate) ||
                other.workDate == workDate) &&
            (identical(other.objectName, objectName) ||
                other.objectName == objectName) &&
            (identical(other.contractName, contractName) ||
                other.contractName == contractName) &&
            (identical(other.system, system) || other.system == system) &&
            (identical(other.subsystem, subsystem) ||
                other.subsystem == subsystem) &&
            (identical(other.positionNumber, positionNumber) ||
                other.positionNumber == positionNumber) &&
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
      positionNumber,
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
    return 'ExportReportModel(workDate: $workDate, objectName: $objectName, contractName: $contractName, system: $system, subsystem: $subsystem, positionNumber: $positionNumber, workName: $workName, section: $section, floor: $floor, unit: $unit, quantity: $quantity, price: $price, total: $total, employeeName: $employeeName, hours: $hours, materials: $materials)';
  }
}

/// @nodoc
abstract mixin class _$ExportReportModelCopyWith<$Res>
    implements $ExportReportModelCopyWith<$Res> {
  factory _$ExportReportModelCopyWith(
          _ExportReportModel value, $Res Function(_ExportReportModel) _then) =
      __$ExportReportModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'work_date') DateTime workDate,
      @JsonKey(name: 'object_name') String objectName,
      @JsonKey(name: 'contract_name') String contractName,
      String system,
      String subsystem,
      @JsonKey(name: 'position_number') String positionNumber,
      @JsonKey(name: 'work_name') String workName,
      String section,
      String floor,
      String unit,
      num quantity,
      double? price,
      double? total,
      @JsonKey(name: 'employee_name') String? employeeName,
      num? hours,
      String? materials});
}

/// @nodoc
class __$ExportReportModelCopyWithImpl<$Res>
    implements _$ExportReportModelCopyWith<$Res> {
  __$ExportReportModelCopyWithImpl(this._self, this._then);

  final _ExportReportModel _self;
  final $Res Function(_ExportReportModel) _then;

  /// Create a copy of ExportReportModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? workDate = null,
    Object? objectName = null,
    Object? contractName = null,
    Object? system = null,
    Object? subsystem = null,
    Object? positionNumber = null,
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
    return _then(_ExportReportModel(
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
      positionNumber: null == positionNumber
          ? _self.positionNumber
          : positionNumber // ignore: cast_nullable_to_non_nullable
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
