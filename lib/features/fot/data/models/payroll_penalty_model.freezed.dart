// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payroll_penalty_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PayrollPenaltyModel {
  /// Уникальный идентификатор штрафа
  String get id;

  /// Идентификатор расчёта ФОТ
  String get payrollId;

  /// Тип штрафа (дисциплинарный/автоматический)
  String get type;

  /// Сумма штрафа
  num get amount;

  /// Причина или комментарий
  String? get reason;

  /// Дата создания записи
  DateTime? get createdAt;

  /// Create a copy of PayrollPenaltyModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PayrollPenaltyModelCopyWith<PayrollPenaltyModel> get copyWith =>
      _$PayrollPenaltyModelCopyWithImpl<PayrollPenaltyModel>(
          this as PayrollPenaltyModel, _$identity);

  /// Serializes this PayrollPenaltyModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PayrollPenaltyModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.payrollId, payrollId) ||
                other.payrollId == payrollId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, payrollId, type, amount, reason, createdAt);

  @override
  String toString() {
    return 'PayrollPenaltyModel(id: $id, payrollId: $payrollId, type: $type, amount: $amount, reason: $reason, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class $PayrollPenaltyModelCopyWith<$Res> {
  factory $PayrollPenaltyModelCopyWith(
          PayrollPenaltyModel value, $Res Function(PayrollPenaltyModel) _then) =
      _$PayrollPenaltyModelCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String payrollId,
      String type,
      num amount,
      String? reason,
      DateTime? createdAt});
}

/// @nodoc
class _$PayrollPenaltyModelCopyWithImpl<$Res>
    implements $PayrollPenaltyModelCopyWith<$Res> {
  _$PayrollPenaltyModelCopyWithImpl(this._self, this._then);

  final PayrollPenaltyModel _self;
  final $Res Function(PayrollPenaltyModel) _then;

  /// Create a copy of PayrollPenaltyModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? payrollId = null,
    Object? type = null,
    Object? amount = null,
    Object? reason = freezed,
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
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _self.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as num,
      reason: freezed == reason
          ? _self.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _PayrollPenaltyModel implements PayrollPenaltyModel {
  const _PayrollPenaltyModel(
      {required this.id,
      required this.payrollId,
      required this.type,
      required this.amount,
      this.reason,
      this.createdAt});
  factory _PayrollPenaltyModel.fromJson(Map<String, dynamic> json) =>
      _$PayrollPenaltyModelFromJson(json);

  /// Уникальный идентификатор штрафа
  @override
  final String id;

  /// Идентификатор расчёта ФОТ
  @override
  final String payrollId;

  /// Тип штрафа (дисциплинарный/автоматический)
  @override
  final String type;

  /// Сумма штрафа
  @override
  final num amount;

  /// Причина или комментарий
  @override
  final String? reason;

  /// Дата создания записи
  @override
  final DateTime? createdAt;

  /// Create a copy of PayrollPenaltyModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PayrollPenaltyModelCopyWith<_PayrollPenaltyModel> get copyWith =>
      __$PayrollPenaltyModelCopyWithImpl<_PayrollPenaltyModel>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PayrollPenaltyModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PayrollPenaltyModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.payrollId, payrollId) ||
                other.payrollId == payrollId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, payrollId, type, amount, reason, createdAt);

  @override
  String toString() {
    return 'PayrollPenaltyModel(id: $id, payrollId: $payrollId, type: $type, amount: $amount, reason: $reason, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class _$PayrollPenaltyModelCopyWith<$Res>
    implements $PayrollPenaltyModelCopyWith<$Res> {
  factory _$PayrollPenaltyModelCopyWith(_PayrollPenaltyModel value,
          $Res Function(_PayrollPenaltyModel) _then) =
      __$PayrollPenaltyModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String payrollId,
      String type,
      num amount,
      String? reason,
      DateTime? createdAt});
}

/// @nodoc
class __$PayrollPenaltyModelCopyWithImpl<$Res>
    implements _$PayrollPenaltyModelCopyWith<$Res> {
  __$PayrollPenaltyModelCopyWithImpl(this._self, this._then);

  final _PayrollPenaltyModel _self;
  final $Res Function(_PayrollPenaltyModel) _then;

  /// Create a copy of PayrollPenaltyModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? payrollId = null,
    Object? type = null,
    Object? amount = null,
    Object? reason = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_PayrollPenaltyModel(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      payrollId: null == payrollId
          ? _self.payrollId
          : payrollId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _self.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as num,
      reason: freezed == reason
          ? _self.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

// dart format on
