// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payroll_deduction_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PayrollDeductionModel {
  /// Уникальный идентификатор удержания
  String get id;

  /// Идентификатор расчёта ФОТ
  String get payrollId;

  /// Тип удержания (налог, аванс, прочее)
  String get type;

  /// Сумма удержания
  num get amount;

  /// Комментарий
  String? get comment;

  /// Дата создания записи
  DateTime? get createdAt;

  /// Create a copy of PayrollDeductionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PayrollDeductionModelCopyWith<PayrollDeductionModel> get copyWith =>
      _$PayrollDeductionModelCopyWithImpl<PayrollDeductionModel>(
          this as PayrollDeductionModel, _$identity);

  /// Serializes this PayrollDeductionModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PayrollDeductionModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.payrollId, payrollId) ||
                other.payrollId == payrollId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.comment, comment) || other.comment == comment) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, payrollId, type, amount, comment, createdAt);

  @override
  String toString() {
    return 'PayrollDeductionModel(id: $id, payrollId: $payrollId, type: $type, amount: $amount, comment: $comment, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class $PayrollDeductionModelCopyWith<$Res> {
  factory $PayrollDeductionModelCopyWith(PayrollDeductionModel value,
          $Res Function(PayrollDeductionModel) _then) =
      _$PayrollDeductionModelCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String payrollId,
      String type,
      num amount,
      String? comment,
      DateTime? createdAt});
}

/// @nodoc
class _$PayrollDeductionModelCopyWithImpl<$Res>
    implements $PayrollDeductionModelCopyWith<$Res> {
  _$PayrollDeductionModelCopyWithImpl(this._self, this._then);

  final PayrollDeductionModel _self;
  final $Res Function(PayrollDeductionModel) _then;

  /// Create a copy of PayrollDeductionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? payrollId = null,
    Object? type = null,
    Object? amount = null,
    Object? comment = freezed,
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
      comment: freezed == comment
          ? _self.comment
          : comment // ignore: cast_nullable_to_non_nullable
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
class _PayrollDeductionModel implements PayrollDeductionModel {
  const _PayrollDeductionModel(
      {required this.id,
      required this.payrollId,
      required this.type,
      required this.amount,
      this.comment,
      this.createdAt});
  factory _PayrollDeductionModel.fromJson(Map<String, dynamic> json) =>
      _$PayrollDeductionModelFromJson(json);

  /// Уникальный идентификатор удержания
  @override
  final String id;

  /// Идентификатор расчёта ФОТ
  @override
  final String payrollId;

  /// Тип удержания (налог, аванс, прочее)
  @override
  final String type;

  /// Сумма удержания
  @override
  final num amount;

  /// Комментарий
  @override
  final String? comment;

  /// Дата создания записи
  @override
  final DateTime? createdAt;

  /// Create a copy of PayrollDeductionModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PayrollDeductionModelCopyWith<_PayrollDeductionModel> get copyWith =>
      __$PayrollDeductionModelCopyWithImpl<_PayrollDeductionModel>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PayrollDeductionModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PayrollDeductionModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.payrollId, payrollId) ||
                other.payrollId == payrollId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.comment, comment) || other.comment == comment) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, payrollId, type, amount, comment, createdAt);

  @override
  String toString() {
    return 'PayrollDeductionModel(id: $id, payrollId: $payrollId, type: $type, amount: $amount, comment: $comment, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class _$PayrollDeductionModelCopyWith<$Res>
    implements $PayrollDeductionModelCopyWith<$Res> {
  factory _$PayrollDeductionModelCopyWith(_PayrollDeductionModel value,
          $Res Function(_PayrollDeductionModel) _then) =
      __$PayrollDeductionModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String payrollId,
      String type,
      num amount,
      String? comment,
      DateTime? createdAt});
}

/// @nodoc
class __$PayrollDeductionModelCopyWithImpl<$Res>
    implements _$PayrollDeductionModelCopyWith<$Res> {
  __$PayrollDeductionModelCopyWithImpl(this._self, this._then);

  final _PayrollDeductionModel _self;
  final $Res Function(_PayrollDeductionModel) _then;

  /// Create a copy of PayrollDeductionModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? payrollId = null,
    Object? type = null,
    Object? amount = null,
    Object? comment = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_PayrollDeductionModel(
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
      comment: freezed == comment
          ? _self.comment
          : comment // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

// dart format on
