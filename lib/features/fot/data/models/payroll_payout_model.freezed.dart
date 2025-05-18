// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payroll_payout_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PayrollPayoutModel {
  String get id;
  String get payrollId;
  num get amount;
  DateTime get payoutDate;
  String get method;
  String get status;
  DateTime? get createdAt;

  /// Create a copy of PayrollPayoutModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PayrollPayoutModelCopyWith<PayrollPayoutModel> get copyWith =>
      _$PayrollPayoutModelCopyWithImpl<PayrollPayoutModel>(
          this as PayrollPayoutModel, _$identity);

  /// Serializes this PayrollPayoutModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PayrollPayoutModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.payrollId, payrollId) ||
                other.payrollId == payrollId) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.payoutDate, payoutDate) ||
                other.payoutDate == payoutDate) &&
            (identical(other.method, method) || other.method == method) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, payrollId, amount,
      payoutDate, method, status, createdAt);

  @override
  String toString() {
    return 'PayrollPayoutModel(id: $id, payrollId: $payrollId, amount: $amount, payoutDate: $payoutDate, method: $method, status: $status, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class $PayrollPayoutModelCopyWith<$Res> {
  factory $PayrollPayoutModelCopyWith(
          PayrollPayoutModel value, $Res Function(PayrollPayoutModel) _then) =
      _$PayrollPayoutModelCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String payrollId,
      num amount,
      DateTime payoutDate,
      String method,
      String status,
      DateTime? createdAt});
}

/// @nodoc
class _$PayrollPayoutModelCopyWithImpl<$Res>
    implements $PayrollPayoutModelCopyWith<$Res> {
  _$PayrollPayoutModelCopyWithImpl(this._self, this._then);

  final PayrollPayoutModel _self;
  final $Res Function(PayrollPayoutModel) _then;

  /// Create a copy of PayrollPayoutModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? payrollId = null,
    Object? amount = null,
    Object? payoutDate = null,
    Object? method = null,
    Object? status = null,
    Object? createdAt = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      payrollId: null == payrollId
          ? _self.payrollId
          : payrollId // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _self.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as num,
      payoutDate: null == payoutDate
          ? _self.payoutDate
          : payoutDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      method: null == method
          ? _self.method
          : method // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _PayrollPayoutModel implements PayrollPayoutModel {
  const _PayrollPayoutModel(
      {required this.id,
      required this.payrollId,
      required this.amount,
      required this.payoutDate,
      required this.method,
      this.status = 'pending',
      this.createdAt});
  factory _PayrollPayoutModel.fromJson(Map<String, dynamic> json) =>
      _$PayrollPayoutModelFromJson(json);

  @override
  final String id;
  @override
  final String payrollId;
  @override
  final num amount;
  @override
  final DateTime payoutDate;
  @override
  final String method;
  @override
  @JsonKey()
  final String status;
  @override
  final DateTime? createdAt;

  /// Create a copy of PayrollPayoutModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PayrollPayoutModelCopyWith<_PayrollPayoutModel> get copyWith =>
      __$PayrollPayoutModelCopyWithImpl<_PayrollPayoutModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PayrollPayoutModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PayrollPayoutModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.payrollId, payrollId) ||
                other.payrollId == payrollId) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.payoutDate, payoutDate) ||
                other.payoutDate == payoutDate) &&
            (identical(other.method, method) || other.method == method) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, payrollId, amount,
      payoutDate, method, status, createdAt);

  @override
  String toString() {
    return 'PayrollPayoutModel(id: $id, payrollId: $payrollId, amount: $amount, payoutDate: $payoutDate, method: $method, status: $status, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class _$PayrollPayoutModelCopyWith<$Res>
    implements $PayrollPayoutModelCopyWith<$Res> {
  factory _$PayrollPayoutModelCopyWith(
          _PayrollPayoutModel value, $Res Function(_PayrollPayoutModel) _then) =
      __$PayrollPayoutModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String payrollId,
      num amount,
      DateTime payoutDate,
      String method,
      String status,
      DateTime? createdAt});
}

/// @nodoc
class __$PayrollPayoutModelCopyWithImpl<$Res>
    implements _$PayrollPayoutModelCopyWith<$Res> {
  __$PayrollPayoutModelCopyWithImpl(this._self, this._then);

  final _PayrollPayoutModel _self;
  final $Res Function(_PayrollPayoutModel) _then;

  /// Create a copy of PayrollPayoutModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? payrollId = null,
    Object? amount = null,
    Object? payoutDate = null,
    Object? method = null,
    Object? status = null,
    Object? createdAt = freezed,
  }) {
    return _then(_PayrollPayoutModel(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      payrollId: null == payrollId
          ? _self.payrollId
          : payrollId // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _self.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as num,
      payoutDate: null == payoutDate
          ? _self.payoutDate
          : payoutDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      method: null == method
          ? _self.method
          : method // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

// dart format on
