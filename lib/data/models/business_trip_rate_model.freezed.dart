// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'business_trip_rate_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BusinessTripRateModel {
  String get id;
  String get objectId;
  String? get employeeId;
  double get rate;
  double get minimumHours;
  DateTime get validFrom;
  DateTime? get validTo;
  DateTime? get createdAt;
  DateTime? get updatedAt;
  String? get createdBy;

  /// Create a copy of BusinessTripRateModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BusinessTripRateModelCopyWith<BusinessTripRateModel> get copyWith =>
      _$BusinessTripRateModelCopyWithImpl<BusinessTripRateModel>(
          this as BusinessTripRateModel, _$identity);

  /// Serializes this BusinessTripRateModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BusinessTripRateModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.objectId, objectId) ||
                other.objectId == objectId) &&
            (identical(other.employeeId, employeeId) ||
                other.employeeId == employeeId) &&
            (identical(other.rate, rate) || other.rate == rate) &&
            (identical(other.minimumHours, minimumHours) ||
                other.minimumHours == minimumHours) &&
            (identical(other.validFrom, validFrom) ||
                other.validFrom == validFrom) &&
            (identical(other.validTo, validTo) || other.validTo == validTo) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, objectId, employeeId, rate,
      minimumHours, validFrom, validTo, createdAt, updatedAt, createdBy);

  @override
  String toString() {
    return 'BusinessTripRateModel(id: $id, objectId: $objectId, employeeId: $employeeId, rate: $rate, minimumHours: $minimumHours, validFrom: $validFrom, validTo: $validTo, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy)';
  }
}

/// @nodoc
abstract mixin class $BusinessTripRateModelCopyWith<$Res> {
  factory $BusinessTripRateModelCopyWith(BusinessTripRateModel value,
          $Res Function(BusinessTripRateModel) _then) =
      _$BusinessTripRateModelCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String objectId,
      String? employeeId,
      double rate,
      double minimumHours,
      DateTime validFrom,
      DateTime? validTo,
      DateTime? createdAt,
      DateTime? updatedAt,
      String? createdBy});
}

/// @nodoc
class _$BusinessTripRateModelCopyWithImpl<$Res>
    implements $BusinessTripRateModelCopyWith<$Res> {
  _$BusinessTripRateModelCopyWithImpl(this._self, this._then);

  final BusinessTripRateModel _self;
  final $Res Function(BusinessTripRateModel) _then;

  /// Create a copy of BusinessTripRateModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? objectId = null,
    Object? employeeId = freezed,
    Object? rate = null,
    Object? minimumHours = null,
    Object? validFrom = null,
    Object? validTo = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? createdBy = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      objectId: null == objectId
          ? _self.objectId
          : objectId // ignore: cast_nullable_to_non_nullable
              as String,
      employeeId: freezed == employeeId
          ? _self.employeeId
          : employeeId // ignore: cast_nullable_to_non_nullable
              as String?,
      rate: null == rate
          ? _self.rate
          : rate // ignore: cast_nullable_to_non_nullable
              as double,
      minimumHours: null == minimumHours
          ? _self.minimumHours
          : minimumHours // ignore: cast_nullable_to_non_nullable
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
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdBy: freezed == createdBy
          ? _self.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class _BusinessTripRateModel extends BusinessTripRateModel {
  const _BusinessTripRateModel(
      {required this.id,
      required this.objectId,
      this.employeeId,
      required this.rate,
      this.minimumHours = 0.0,
      required this.validFrom,
      this.validTo,
      this.createdAt,
      this.updatedAt,
      this.createdBy})
      : super._();
  factory _BusinessTripRateModel.fromJson(Map<String, dynamic> json) =>
      _$BusinessTripRateModelFromJson(json);

  @override
  final String id;
  @override
  final String objectId;
  @override
  final String? employeeId;
  @override
  final double rate;
  @override
  @JsonKey()
  final double minimumHours;
  @override
  final DateTime validFrom;
  @override
  final DateTime? validTo;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;
  @override
  final String? createdBy;

  /// Create a copy of BusinessTripRateModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BusinessTripRateModelCopyWith<_BusinessTripRateModel> get copyWith =>
      __$BusinessTripRateModelCopyWithImpl<_BusinessTripRateModel>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$BusinessTripRateModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BusinessTripRateModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.objectId, objectId) ||
                other.objectId == objectId) &&
            (identical(other.employeeId, employeeId) ||
                other.employeeId == employeeId) &&
            (identical(other.rate, rate) || other.rate == rate) &&
            (identical(other.minimumHours, minimumHours) ||
                other.minimumHours == minimumHours) &&
            (identical(other.validFrom, validFrom) ||
                other.validFrom == validFrom) &&
            (identical(other.validTo, validTo) || other.validTo == validTo) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, objectId, employeeId, rate,
      minimumHours, validFrom, validTo, createdAt, updatedAt, createdBy);

  @override
  String toString() {
    return 'BusinessTripRateModel(id: $id, objectId: $objectId, employeeId: $employeeId, rate: $rate, minimumHours: $minimumHours, validFrom: $validFrom, validTo: $validTo, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy)';
  }
}

/// @nodoc
abstract mixin class _$BusinessTripRateModelCopyWith<$Res>
    implements $BusinessTripRateModelCopyWith<$Res> {
  factory _$BusinessTripRateModelCopyWith(_BusinessTripRateModel value,
          $Res Function(_BusinessTripRateModel) _then) =
      __$BusinessTripRateModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String objectId,
      String? employeeId,
      double rate,
      double minimumHours,
      DateTime validFrom,
      DateTime? validTo,
      DateTime? createdAt,
      DateTime? updatedAt,
      String? createdBy});
}

/// @nodoc
class __$BusinessTripRateModelCopyWithImpl<$Res>
    implements _$BusinessTripRateModelCopyWith<$Res> {
  __$BusinessTripRateModelCopyWithImpl(this._self, this._then);

  final _BusinessTripRateModel _self;
  final $Res Function(_BusinessTripRateModel) _then;

  /// Create a copy of BusinessTripRateModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? objectId = null,
    Object? employeeId = freezed,
    Object? rate = null,
    Object? minimumHours = null,
    Object? validFrom = null,
    Object? validTo = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? createdBy = freezed,
  }) {
    return _then(_BusinessTripRateModel(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      objectId: null == objectId
          ? _self.objectId
          : objectId // ignore: cast_nullable_to_non_nullable
              as String,
      employeeId: freezed == employeeId
          ? _self.employeeId
          : employeeId // ignore: cast_nullable_to_non_nullable
              as String?,
      rate: null == rate
          ? _self.rate
          : rate // ignore: cast_nullable_to_non_nullable
              as double,
      minimumHours: null == minimumHours
          ? _self.minimumHours
          : minimumHours // ignore: cast_nullable_to_non_nullable
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
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdBy: freezed == createdBy
          ? _self.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
