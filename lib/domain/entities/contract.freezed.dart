// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'contract.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Contract {
  /// Уникальный идентификатор контракта.
  String get id;

  /// Номер контракта.
  String get number;

  /// Дата заключения контракта.
  DateTime get date;

  /// Дата окончания действия контракта.
  DateTime? get endDate;

  /// Идентификатор подрядчика.
  String get contractorId;

  /// Имя подрядчика.
  String? get contractorName;

  /// Сумма контракта.
  double get amount;

  /// Идентификатор объекта.
  String get objectId;

  /// Имя объекта.
  String? get objectName;

  /// Статус контракта ([ContractStatus]).
  ContractStatus get status;

  /// Дата создания записи.
  DateTime? get createdAt;

  /// Дата последнего обновления записи.
  DateTime? get updatedAt;

  /// Create a copy of Contract
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ContractCopyWith<Contract> get copyWith =>
      _$ContractCopyWithImpl<Contract>(this as Contract, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Contract &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.number, number) || other.number == number) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.contractorId, contractorId) ||
                other.contractorId == contractorId) &&
            (identical(other.contractorName, contractorName) ||
                other.contractorName == contractorName) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.objectId, objectId) ||
                other.objectId == objectId) &&
            (identical(other.objectName, objectName) ||
                other.objectName == objectName) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      number,
      date,
      endDate,
      contractorId,
      contractorName,
      amount,
      objectId,
      objectName,
      status,
      createdAt,
      updatedAt);

  @override
  String toString() {
    return 'Contract(id: $id, number: $number, date: $date, endDate: $endDate, contractorId: $contractorId, contractorName: $contractorName, amount: $amount, objectId: $objectId, objectName: $objectName, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class $ContractCopyWith<$Res> {
  factory $ContractCopyWith(Contract value, $Res Function(Contract) _then) =
      _$ContractCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String number,
      DateTime date,
      DateTime? endDate,
      String contractorId,
      String? contractorName,
      double amount,
      String objectId,
      String? objectName,
      ContractStatus status,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class _$ContractCopyWithImpl<$Res> implements $ContractCopyWith<$Res> {
  _$ContractCopyWithImpl(this._self, this._then);

  final Contract _self;
  final $Res Function(Contract) _then;

  /// Create a copy of Contract
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? number = null,
    Object? date = null,
    Object? endDate = freezed,
    Object? contractorId = null,
    Object? contractorName = freezed,
    Object? amount = null,
    Object? objectId = null,
    Object? objectName = freezed,
    Object? status = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      number: null == number
          ? _self.number
          : number // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _self.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endDate: freezed == endDate
          ? _self.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      contractorId: null == contractorId
          ? _self.contractorId
          : contractorId // ignore: cast_nullable_to_non_nullable
              as String,
      contractorName: freezed == contractorName
          ? _self.contractorName
          : contractorName // ignore: cast_nullable_to_non_nullable
              as String?,
      amount: null == amount
          ? _self.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      objectId: null == objectId
          ? _self.objectId
          : objectId // ignore: cast_nullable_to_non_nullable
              as String,
      objectName: freezed == objectName
          ? _self.objectName
          : objectName // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as ContractStatus,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc

class _Contract extends Contract {
  const _Contract(
      {required this.id,
      required this.number,
      required this.date,
      this.endDate,
      required this.contractorId,
      this.contractorName,
      required this.amount,
      required this.objectId,
      this.objectName,
      this.status = ContractStatus.active,
      this.createdAt,
      this.updatedAt})
      : super._();

  /// Уникальный идентификатор контракта.
  @override
  final String id;

  /// Номер контракта.
  @override
  final String number;

  /// Дата заключения контракта.
  @override
  final DateTime date;

  /// Дата окончания действия контракта.
  @override
  final DateTime? endDate;

  /// Идентификатор подрядчика.
  @override
  final String contractorId;

  /// Имя подрядчика.
  @override
  final String? contractorName;

  /// Сумма контракта.
  @override
  final double amount;

  /// Идентификатор объекта.
  @override
  final String objectId;

  /// Имя объекта.
  @override
  final String? objectName;

  /// Статус контракта ([ContractStatus]).
  @override
  @JsonKey()
  final ContractStatus status;

  /// Дата создания записи.
  @override
  final DateTime? createdAt;

  /// Дата последнего обновления записи.
  @override
  final DateTime? updatedAt;

  /// Create a copy of Contract
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ContractCopyWith<_Contract> get copyWith =>
      __$ContractCopyWithImpl<_Contract>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Contract &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.number, number) || other.number == number) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.contractorId, contractorId) ||
                other.contractorId == contractorId) &&
            (identical(other.contractorName, contractorName) ||
                other.contractorName == contractorName) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.objectId, objectId) ||
                other.objectId == objectId) &&
            (identical(other.objectName, objectName) ||
                other.objectName == objectName) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      number,
      date,
      endDate,
      contractorId,
      contractorName,
      amount,
      objectId,
      objectName,
      status,
      createdAt,
      updatedAt);

  @override
  String toString() {
    return 'Contract(id: $id, number: $number, date: $date, endDate: $endDate, contractorId: $contractorId, contractorName: $contractorName, amount: $amount, objectId: $objectId, objectName: $objectName, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$ContractCopyWith<$Res>
    implements $ContractCopyWith<$Res> {
  factory _$ContractCopyWith(_Contract value, $Res Function(_Contract) _then) =
      __$ContractCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String number,
      DateTime date,
      DateTime? endDate,
      String contractorId,
      String? contractorName,
      double amount,
      String objectId,
      String? objectName,
      ContractStatus status,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class __$ContractCopyWithImpl<$Res> implements _$ContractCopyWith<$Res> {
  __$ContractCopyWithImpl(this._self, this._then);

  final _Contract _self;
  final $Res Function(_Contract) _then;

  /// Create a copy of Contract
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? number = null,
    Object? date = null,
    Object? endDate = freezed,
    Object? contractorId = null,
    Object? contractorName = freezed,
    Object? amount = null,
    Object? objectId = null,
    Object? objectName = freezed,
    Object? status = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_Contract(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      number: null == number
          ? _self.number
          : number // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _self.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endDate: freezed == endDate
          ? _self.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      contractorId: null == contractorId
          ? _self.contractorId
          : contractorId // ignore: cast_nullable_to_non_nullable
              as String,
      contractorName: freezed == contractorName
          ? _self.contractorName
          : contractorName // ignore: cast_nullable_to_non_nullable
              as String?,
      amount: null == amount
          ? _self.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      objectId: null == objectId
          ? _self.objectId
          : objectId // ignore: cast_nullable_to_non_nullable
              as String,
      objectName: freezed == objectName
          ? _self.objectName
          : objectName // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as ContractStatus,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

// dart format on
