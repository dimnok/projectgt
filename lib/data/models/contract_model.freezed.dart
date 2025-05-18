// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'contract_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ContractModel {
  String get id;
  String get number;
  @JsonKey(toJson: _dateOnlyToJson)
  DateTime get date;
  @JsonKey(toJson: _dateOnlyToJson)
  DateTime? get endDate;
  String get contractorId;
  String? get contractorName;
  double get amount;
  String get objectId;
  String? get objectName;
  ContractStatus get status;
  DateTime? get createdAt;
  DateTime? get updatedAt;

  /// Create a copy of ContractModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ContractModelCopyWith<ContractModel> get copyWith =>
      _$ContractModelCopyWithImpl<ContractModel>(
          this as ContractModel, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ContractModel &&
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
    return 'ContractModel(id: $id, number: $number, date: $date, endDate: $endDate, contractorId: $contractorId, contractorName: $contractorName, amount: $amount, objectId: $objectId, objectName: $objectName, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class $ContractModelCopyWith<$Res> {
  factory $ContractModelCopyWith(
          ContractModel value, $Res Function(ContractModel) _then) =
      _$ContractModelCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String number,
      @JsonKey(toJson: _dateOnlyToJson) DateTime date,
      @JsonKey(toJson: _dateOnlyToJson) DateTime? endDate,
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
class _$ContractModelCopyWithImpl<$Res>
    implements $ContractModelCopyWith<$Res> {
  _$ContractModelCopyWithImpl(this._self, this._then);

  final ContractModel _self;
  final $Res Function(ContractModel) _then;

  /// Create a copy of ContractModel
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

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class _ContractModel extends ContractModel {
  const _ContractModel(
      {required this.id,
      required this.number,
      @JsonKey(toJson: _dateOnlyToJson) required this.date,
      @JsonKey(toJson: _dateOnlyToJson) this.endDate,
      required this.contractorId,
      this.contractorName,
      required this.amount,
      required this.objectId,
      this.objectName,
      this.status = ContractStatus.active,
      this.createdAt,
      this.updatedAt})
      : super._();

  @override
  final String id;
  @override
  final String number;
  @override
  @JsonKey(toJson: _dateOnlyToJson)
  final DateTime date;
  @override
  @JsonKey(toJson: _dateOnlyToJson)
  final DateTime? endDate;
  @override
  final String contractorId;
  @override
  final String? contractorName;
  @override
  final double amount;
  @override
  final String objectId;
  @override
  final String? objectName;
  @override
  @JsonKey()
  final ContractStatus status;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  /// Create a copy of ContractModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ContractModelCopyWith<_ContractModel> get copyWith =>
      __$ContractModelCopyWithImpl<_ContractModel>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ContractModel &&
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
    return 'ContractModel(id: $id, number: $number, date: $date, endDate: $endDate, contractorId: $contractorId, contractorName: $contractorName, amount: $amount, objectId: $objectId, objectName: $objectName, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$ContractModelCopyWith<$Res>
    implements $ContractModelCopyWith<$Res> {
  factory _$ContractModelCopyWith(
          _ContractModel value, $Res Function(_ContractModel) _then) =
      __$ContractModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String number,
      @JsonKey(toJson: _dateOnlyToJson) DateTime date,
      @JsonKey(toJson: _dateOnlyToJson) DateTime? endDate,
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
class __$ContractModelCopyWithImpl<$Res>
    implements _$ContractModelCopyWith<$Res> {
  __$ContractModelCopyWithImpl(this._self, this._then);

  final _ContractModel _self;
  final $Res Function(_ContractModel) _then;

  /// Create a copy of ContractModel
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
    return _then(_ContractModel(
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
