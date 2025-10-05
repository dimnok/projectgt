// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'employee_rate_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EmployeeRateModel {
  /// Уникальный идентификатор записи ставки
  String get id;

  /// Идентификатор сотрудника
  @JsonKey(name: 'employee_id')
  String get employeeId;

  /// Почасовая ставка в рублях
  @JsonKey(name: 'hourly_rate')
  double get hourlyRate;

  /// Дата начала действия ставки
  @JsonKey(name: 'valid_from')
  DateTime get validFrom;

  /// Дата окончания действия ставки (null означает текущую ставку)
  @JsonKey(name: 'valid_to')
  DateTime? get validTo;

  /// Дата создания записи
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;

  /// Идентификатор пользователя, создавшего запись
  @JsonKey(name: 'created_by')
  String? get createdBy;

  /// Create a copy of EmployeeRateModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $EmployeeRateModelCopyWith<EmployeeRateModel> get copyWith =>
      _$EmployeeRateModelCopyWithImpl<EmployeeRateModel>(
          this as EmployeeRateModel, _$identity);

  /// Serializes this EmployeeRateModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is EmployeeRateModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.employeeId, employeeId) ||
                other.employeeId == employeeId) &&
            (identical(other.hourlyRate, hourlyRate) ||
                other.hourlyRate == hourlyRate) &&
            (identical(other.validFrom, validFrom) ||
                other.validFrom == validFrom) &&
            (identical(other.validTo, validTo) || other.validTo == validTo) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, employeeId, hourlyRate,
      validFrom, validTo, createdAt, createdBy);

  @override
  String toString() {
    return 'EmployeeRateModel(id: $id, employeeId: $employeeId, hourlyRate: $hourlyRate, validFrom: $validFrom, validTo: $validTo, createdAt: $createdAt, createdBy: $createdBy)';
  }
}

/// @nodoc
abstract mixin class $EmployeeRateModelCopyWith<$Res> {
  factory $EmployeeRateModelCopyWith(
          EmployeeRateModel value, $Res Function(EmployeeRateModel) _then) =
      _$EmployeeRateModelCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'employee_id') String employeeId,
      @JsonKey(name: 'hourly_rate') double hourlyRate,
      @JsonKey(name: 'valid_from') DateTime validFrom,
      @JsonKey(name: 'valid_to') DateTime? validTo,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'created_by') String? createdBy});
}

/// @nodoc
class _$EmployeeRateModelCopyWithImpl<$Res>
    implements $EmployeeRateModelCopyWith<$Res> {
  _$EmployeeRateModelCopyWithImpl(this._self, this._then);

  final EmployeeRateModel _self;
  final $Res Function(EmployeeRateModel) _then;

  /// Create a copy of EmployeeRateModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? employeeId = null,
    Object? hourlyRate = null,
    Object? validFrom = null,
    Object? validTo = freezed,
    Object? createdAt = freezed,
    Object? createdBy = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      employeeId: null == employeeId
          ? _self.employeeId
          : employeeId // ignore: cast_nullable_to_non_nullable
              as String,
      hourlyRate: null == hourlyRate
          ? _self.hourlyRate
          : hourlyRate // ignore: cast_nullable_to_non_nullable
              as double,
      validFrom: null == validFrom
          ? _self.validFrom
          : validFrom // ignore: cast_nullable_to_non_nullable
              as DateTime,
      validTo: freezed == validTo
          ? _self.validTo
          : validTo // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdBy: freezed == createdBy
          ? _self.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _EmployeeRateModel extends EmployeeRateModel {
  const _EmployeeRateModel(
      {required this.id,
      @JsonKey(name: 'employee_id') required this.employeeId,
      @JsonKey(name: 'hourly_rate') required this.hourlyRate,
      @JsonKey(name: 'valid_from') required this.validFrom,
      @JsonKey(name: 'valid_to') this.validTo,
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'created_by') this.createdBy})
      : super._();
  factory _EmployeeRateModel.fromJson(Map<String, dynamic> json) =>
      _$EmployeeRateModelFromJson(json);

  /// Уникальный идентификатор записи ставки
  @override
  final String id;

  /// Идентификатор сотрудника
  @override
  @JsonKey(name: 'employee_id')
  final String employeeId;

  /// Почасовая ставка в рублях
  @override
  @JsonKey(name: 'hourly_rate')
  final double hourlyRate;

  /// Дата начала действия ставки
  @override
  @JsonKey(name: 'valid_from')
  final DateTime validFrom;

  /// Дата окончания действия ставки (null означает текущую ставку)
  @override
  @JsonKey(name: 'valid_to')
  final DateTime? validTo;

  /// Дата создания записи
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  /// Идентификатор пользователя, создавшего запись
  @override
  @JsonKey(name: 'created_by')
  final String? createdBy;

  /// Create a copy of EmployeeRateModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$EmployeeRateModelCopyWith<_EmployeeRateModel> get copyWith =>
      __$EmployeeRateModelCopyWithImpl<_EmployeeRateModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$EmployeeRateModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _EmployeeRateModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.employeeId, employeeId) ||
                other.employeeId == employeeId) &&
            (identical(other.hourlyRate, hourlyRate) ||
                other.hourlyRate == hourlyRate) &&
            (identical(other.validFrom, validFrom) ||
                other.validFrom == validFrom) &&
            (identical(other.validTo, validTo) || other.validTo == validTo) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, employeeId, hourlyRate,
      validFrom, validTo, createdAt, createdBy);

  @override
  String toString() {
    return 'EmployeeRateModel(id: $id, employeeId: $employeeId, hourlyRate: $hourlyRate, validFrom: $validFrom, validTo: $validTo, createdAt: $createdAt, createdBy: $createdBy)';
  }
}

/// @nodoc
abstract mixin class _$EmployeeRateModelCopyWith<$Res>
    implements $EmployeeRateModelCopyWith<$Res> {
  factory _$EmployeeRateModelCopyWith(
          _EmployeeRateModel value, $Res Function(_EmployeeRateModel) _then) =
      __$EmployeeRateModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'employee_id') String employeeId,
      @JsonKey(name: 'hourly_rate') double hourlyRate,
      @JsonKey(name: 'valid_from') DateTime validFrom,
      @JsonKey(name: 'valid_to') DateTime? validTo,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'created_by') String? createdBy});
}

/// @nodoc
class __$EmployeeRateModelCopyWithImpl<$Res>
    implements _$EmployeeRateModelCopyWith<$Res> {
  __$EmployeeRateModelCopyWithImpl(this._self, this._then);

  final _EmployeeRateModel _self;
  final $Res Function(_EmployeeRateModel) _then;

  /// Create a copy of EmployeeRateModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? employeeId = null,
    Object? hourlyRate = null,
    Object? validFrom = null,
    Object? validTo = freezed,
    Object? createdAt = freezed,
    Object? createdBy = freezed,
  }) {
    return _then(_EmployeeRateModel(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      employeeId: null == employeeId
          ? _self.employeeId
          : employeeId // ignore: cast_nullable_to_non_nullable
              as String,
      hourlyRate: null == hourlyRate
          ? _self.hourlyRate
          : hourlyRate // ignore: cast_nullable_to_non_nullable
              as double,
      validFrom: null == validFrom
          ? _self.validFrom
          : validFrom // ignore: cast_nullable_to_non_nullable
              as DateTime,
      validTo: freezed == validTo
          ? _self.validTo
          : validTo // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdBy: freezed == createdBy
          ? _self.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
