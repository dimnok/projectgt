// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payroll_bonus_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PayrollBonusModel {
  /// Уникальный идентификатор премии
  String get id;

  /// Идентификатор расчёта ФОТ
  String get payrollId;

  /// Тип премии (ручная/авто/поощрительная)
  String get type;

  /// Сумма премии
  num get amount;

  /// Причина или комментарий
  String? get reason;

  /// Дата создания записи
  DateTime? get createdAt;

  /// Create a copy of PayrollBonusModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PayrollBonusModelCopyWith<PayrollBonusModel> get copyWith =>
      _$PayrollBonusModelCopyWithImpl<PayrollBonusModel>(
          this as PayrollBonusModel, _$identity);

  /// Serializes this PayrollBonusModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PayrollBonusModel &&
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
    return 'PayrollBonusModel(id: $id, payrollId: $payrollId, type: $type, amount: $amount, reason: $reason, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class $PayrollBonusModelCopyWith<$Res> {
  factory $PayrollBonusModelCopyWith(
          PayrollBonusModel value, $Res Function(PayrollBonusModel) _then) =
      _$PayrollBonusModelCopyWithImpl;
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
class _$PayrollBonusModelCopyWithImpl<$Res>
    implements $PayrollBonusModelCopyWith<$Res> {
  _$PayrollBonusModelCopyWithImpl(this._self, this._then);

  final PayrollBonusModel _self;
  final $Res Function(PayrollBonusModel) _then;

  /// Create a copy of PayrollBonusModel
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
class _PayrollBonusModel implements PayrollBonusModel {
  const _PayrollBonusModel(
      {required this.id,
      required this.payrollId,
      required this.type,
      required this.amount,
      this.reason,
      this.createdAt});
  factory _PayrollBonusModel.fromJson(Map<String, dynamic> json) =>
      _$PayrollBonusModelFromJson(json);

  /// Уникальный идентификатор премии
  @override
  final String id;

  /// Идентификатор расчёта ФОТ
  @override
  final String payrollId;

  /// Тип премии (ручная/авто/поощрительная)
  @override
  final String type;

  /// Сумма премии
  @override
  final num amount;

  /// Причина или комментарий
  @override
  final String? reason;

  /// Дата создания записи
  @override
  final DateTime? createdAt;

  /// Create a copy of PayrollBonusModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PayrollBonusModelCopyWith<_PayrollBonusModel> get copyWith =>
      __$PayrollBonusModelCopyWithImpl<_PayrollBonusModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PayrollBonusModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PayrollBonusModel &&
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
    return 'PayrollBonusModel(id: $id, payrollId: $payrollId, type: $type, amount: $amount, reason: $reason, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class _$PayrollBonusModelCopyWith<$Res>
    implements $PayrollBonusModelCopyWith<$Res> {
  factory _$PayrollBonusModelCopyWith(
          _PayrollBonusModel value, $Res Function(_PayrollBonusModel) _then) =
      __$PayrollBonusModelCopyWithImpl;
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
class __$PayrollBonusModelCopyWithImpl<$Res>
    implements _$PayrollBonusModelCopyWith<$Res> {
  __$PayrollBonusModelCopyWithImpl(this._self, this._then);

  final _PayrollBonusModel _self;
  final $Res Function(_PayrollBonusModel) _then;

  /// Create a copy of PayrollBonusModel
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
    return _then(_PayrollBonusModel(
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
