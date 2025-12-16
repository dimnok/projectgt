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
  double get vatRate;
  bool get isVatIncluded;
  double get vatAmount;
  double get advanceAmount;
  double get warrantyRetentionAmount;
  double get warrantyRetentionRate;
  int get warrantyPeriodMonths;
  double get generalContractorFeeAmount;
  double get generalContractorFeeRate;
  String get objectId;
  String? get objectName;
  ContractStatus
      get status; // Новые поля для подписантов (маппятся на _legal_name в БД через snake_case)
  String? get contractorLegalName;
  String? get contractorPosition;
  String? get contractorSigner;
  String? get customerLegalName;
  String? get customerPosition;
  String? get customerSigner;
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
            (identical(other.vatRate, vatRate) || other.vatRate == vatRate) &&
            (identical(other.isVatIncluded, isVatIncluded) ||
                other.isVatIncluded == isVatIncluded) &&
            (identical(other.vatAmount, vatAmount) ||
                other.vatAmount == vatAmount) &&
            (identical(other.advanceAmount, advanceAmount) ||
                other.advanceAmount == advanceAmount) &&
            (identical(other.warrantyRetentionAmount, warrantyRetentionAmount) ||
                other.warrantyRetentionAmount == warrantyRetentionAmount) &&
            (identical(other.warrantyRetentionRate, warrantyRetentionRate) ||
                other.warrantyRetentionRate == warrantyRetentionRate) &&
            (identical(other.warrantyPeriodMonths, warrantyPeriodMonths) ||
                other.warrantyPeriodMonths == warrantyPeriodMonths) &&
            (identical(other.generalContractorFeeAmount,
                    generalContractorFeeAmount) ||
                other.generalContractorFeeAmount ==
                    generalContractorFeeAmount) &&
            (identical(
                    other.generalContractorFeeRate, generalContractorFeeRate) ||
                other.generalContractorFeeRate == generalContractorFeeRate) &&
            (identical(other.objectId, objectId) ||
                other.objectId == objectId) &&
            (identical(other.objectName, objectName) ||
                other.objectName == objectName) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.contractorLegalName, contractorLegalName) ||
                other.contractorLegalName == contractorLegalName) &&
            (identical(other.contractorPosition, contractorPosition) ||
                other.contractorPosition == contractorPosition) &&
            (identical(other.contractorSigner, contractorSigner) ||
                other.contractorSigner == contractorSigner) &&
            (identical(other.customerLegalName, customerLegalName) ||
                other.customerLegalName == customerLegalName) &&
            (identical(other.customerPosition, customerPosition) ||
                other.customerPosition == customerPosition) &&
            (identical(other.customerSigner, customerSigner) ||
                other.customerSigner == customerSigner) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        number,
        date,
        endDate,
        contractorId,
        contractorName,
        amount,
        vatRate,
        isVatIncluded,
        vatAmount,
        advanceAmount,
        warrantyRetentionAmount,
        warrantyRetentionRate,
        warrantyPeriodMonths,
        generalContractorFeeAmount,
        generalContractorFeeRate,
        objectId,
        objectName,
        status,
        contractorLegalName,
        contractorPosition,
        contractorSigner,
        customerLegalName,
        customerPosition,
        customerSigner,
        createdAt,
        updatedAt
      ]);

  @override
  String toString() {
    return 'ContractModel(id: $id, number: $number, date: $date, endDate: $endDate, contractorId: $contractorId, contractorName: $contractorName, amount: $amount, vatRate: $vatRate, isVatIncluded: $isVatIncluded, vatAmount: $vatAmount, advanceAmount: $advanceAmount, warrantyRetentionAmount: $warrantyRetentionAmount, warrantyRetentionRate: $warrantyRetentionRate, warrantyPeriodMonths: $warrantyPeriodMonths, generalContractorFeeAmount: $generalContractorFeeAmount, generalContractorFeeRate: $generalContractorFeeRate, objectId: $objectId, objectName: $objectName, status: $status, contractorLegalName: $contractorLegalName, contractorPosition: $contractorPosition, contractorSigner: $contractorSigner, customerLegalName: $customerLegalName, customerPosition: $customerPosition, customerSigner: $customerSigner, createdAt: $createdAt, updatedAt: $updatedAt)';
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
      double vatRate,
      bool isVatIncluded,
      double vatAmount,
      double advanceAmount,
      double warrantyRetentionAmount,
      double warrantyRetentionRate,
      int warrantyPeriodMonths,
      double generalContractorFeeAmount,
      double generalContractorFeeRate,
      String objectId,
      String? objectName,
      ContractStatus status,
      String? contractorLegalName,
      String? contractorPosition,
      String? contractorSigner,
      String? customerLegalName,
      String? customerPosition,
      String? customerSigner,
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
    Object? vatRate = null,
    Object? isVatIncluded = null,
    Object? vatAmount = null,
    Object? advanceAmount = null,
    Object? warrantyRetentionAmount = null,
    Object? warrantyRetentionRate = null,
    Object? warrantyPeriodMonths = null,
    Object? generalContractorFeeAmount = null,
    Object? generalContractorFeeRate = null,
    Object? objectId = null,
    Object? objectName = freezed,
    Object? status = null,
    Object? contractorLegalName = freezed,
    Object? contractorPosition = freezed,
    Object? contractorSigner = freezed,
    Object? customerLegalName = freezed,
    Object? customerPosition = freezed,
    Object? customerSigner = freezed,
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
      vatRate: null == vatRate
          ? _self.vatRate
          : vatRate // ignore: cast_nullable_to_non_nullable
              as double,
      isVatIncluded: null == isVatIncluded
          ? _self.isVatIncluded
          : isVatIncluded // ignore: cast_nullable_to_non_nullable
              as bool,
      vatAmount: null == vatAmount
          ? _self.vatAmount
          : vatAmount // ignore: cast_nullable_to_non_nullable
              as double,
      advanceAmount: null == advanceAmount
          ? _self.advanceAmount
          : advanceAmount // ignore: cast_nullable_to_non_nullable
              as double,
      warrantyRetentionAmount: null == warrantyRetentionAmount
          ? _self.warrantyRetentionAmount
          : warrantyRetentionAmount // ignore: cast_nullable_to_non_nullable
              as double,
      warrantyRetentionRate: null == warrantyRetentionRate
          ? _self.warrantyRetentionRate
          : warrantyRetentionRate // ignore: cast_nullable_to_non_nullable
              as double,
      warrantyPeriodMonths: null == warrantyPeriodMonths
          ? _self.warrantyPeriodMonths
          : warrantyPeriodMonths // ignore: cast_nullable_to_non_nullable
              as int,
      generalContractorFeeAmount: null == generalContractorFeeAmount
          ? _self.generalContractorFeeAmount
          : generalContractorFeeAmount // ignore: cast_nullable_to_non_nullable
              as double,
      generalContractorFeeRate: null == generalContractorFeeRate
          ? _self.generalContractorFeeRate
          : generalContractorFeeRate // ignore: cast_nullable_to_non_nullable
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
      contractorLegalName: freezed == contractorLegalName
          ? _self.contractorLegalName
          : contractorLegalName // ignore: cast_nullable_to_non_nullable
              as String?,
      contractorPosition: freezed == contractorPosition
          ? _self.contractorPosition
          : contractorPosition // ignore: cast_nullable_to_non_nullable
              as String?,
      contractorSigner: freezed == contractorSigner
          ? _self.contractorSigner
          : contractorSigner // ignore: cast_nullable_to_non_nullable
              as String?,
      customerLegalName: freezed == customerLegalName
          ? _self.customerLegalName
          : customerLegalName // ignore: cast_nullable_to_non_nullable
              as String?,
      customerPosition: freezed == customerPosition
          ? _self.customerPosition
          : customerPosition // ignore: cast_nullable_to_non_nullable
              as String?,
      customerSigner: freezed == customerSigner
          ? _self.customerSigner
          : customerSigner // ignore: cast_nullable_to_non_nullable
              as String?,
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
      this.vatRate = 0.0,
      this.isVatIncluded = true,
      this.vatAmount = 0.0,
      this.advanceAmount = 0.0,
      this.warrantyRetentionAmount = 0.0,
      this.warrantyRetentionRate = 0.0,
      this.warrantyPeriodMonths = 0,
      this.generalContractorFeeAmount = 0.0,
      this.generalContractorFeeRate = 0.0,
      required this.objectId,
      this.objectName,
      this.status = ContractStatus.active,
      this.contractorLegalName,
      this.contractorPosition,
      this.contractorSigner,
      this.customerLegalName,
      this.customerPosition,
      this.customerSigner,
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
  @JsonKey()
  final double vatRate;
  @override
  @JsonKey()
  final bool isVatIncluded;
  @override
  @JsonKey()
  final double vatAmount;
  @override
  @JsonKey()
  final double advanceAmount;
  @override
  @JsonKey()
  final double warrantyRetentionAmount;
  @override
  @JsonKey()
  final double warrantyRetentionRate;
  @override
  @JsonKey()
  final int warrantyPeriodMonths;
  @override
  @JsonKey()
  final double generalContractorFeeAmount;
  @override
  @JsonKey()
  final double generalContractorFeeRate;
  @override
  final String objectId;
  @override
  final String? objectName;
  @override
  @JsonKey()
  final ContractStatus status;
// Новые поля для подписантов (маппятся на _legal_name в БД через snake_case)
  @override
  final String? contractorLegalName;
  @override
  final String? contractorPosition;
  @override
  final String? contractorSigner;
  @override
  final String? customerLegalName;
  @override
  final String? customerPosition;
  @override
  final String? customerSigner;
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
            (identical(other.vatRate, vatRate) || other.vatRate == vatRate) &&
            (identical(other.isVatIncluded, isVatIncluded) ||
                other.isVatIncluded == isVatIncluded) &&
            (identical(other.vatAmount, vatAmount) ||
                other.vatAmount == vatAmount) &&
            (identical(other.advanceAmount, advanceAmount) ||
                other.advanceAmount == advanceAmount) &&
            (identical(other.warrantyRetentionAmount, warrantyRetentionAmount) ||
                other.warrantyRetentionAmount == warrantyRetentionAmount) &&
            (identical(other.warrantyRetentionRate, warrantyRetentionRate) ||
                other.warrantyRetentionRate == warrantyRetentionRate) &&
            (identical(other.warrantyPeriodMonths, warrantyPeriodMonths) ||
                other.warrantyPeriodMonths == warrantyPeriodMonths) &&
            (identical(other.generalContractorFeeAmount,
                    generalContractorFeeAmount) ||
                other.generalContractorFeeAmount ==
                    generalContractorFeeAmount) &&
            (identical(
                    other.generalContractorFeeRate, generalContractorFeeRate) ||
                other.generalContractorFeeRate == generalContractorFeeRate) &&
            (identical(other.objectId, objectId) ||
                other.objectId == objectId) &&
            (identical(other.objectName, objectName) ||
                other.objectName == objectName) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.contractorLegalName, contractorLegalName) ||
                other.contractorLegalName == contractorLegalName) &&
            (identical(other.contractorPosition, contractorPosition) ||
                other.contractorPosition == contractorPosition) &&
            (identical(other.contractorSigner, contractorSigner) ||
                other.contractorSigner == contractorSigner) &&
            (identical(other.customerLegalName, customerLegalName) ||
                other.customerLegalName == customerLegalName) &&
            (identical(other.customerPosition, customerPosition) ||
                other.customerPosition == customerPosition) &&
            (identical(other.customerSigner, customerSigner) ||
                other.customerSigner == customerSigner) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        number,
        date,
        endDate,
        contractorId,
        contractorName,
        amount,
        vatRate,
        isVatIncluded,
        vatAmount,
        advanceAmount,
        warrantyRetentionAmount,
        warrantyRetentionRate,
        warrantyPeriodMonths,
        generalContractorFeeAmount,
        generalContractorFeeRate,
        objectId,
        objectName,
        status,
        contractorLegalName,
        contractorPosition,
        contractorSigner,
        customerLegalName,
        customerPosition,
        customerSigner,
        createdAt,
        updatedAt
      ]);

  @override
  String toString() {
    return 'ContractModel(id: $id, number: $number, date: $date, endDate: $endDate, contractorId: $contractorId, contractorName: $contractorName, amount: $amount, vatRate: $vatRate, isVatIncluded: $isVatIncluded, vatAmount: $vatAmount, advanceAmount: $advanceAmount, warrantyRetentionAmount: $warrantyRetentionAmount, warrantyRetentionRate: $warrantyRetentionRate, warrantyPeriodMonths: $warrantyPeriodMonths, generalContractorFeeAmount: $generalContractorFeeAmount, generalContractorFeeRate: $generalContractorFeeRate, objectId: $objectId, objectName: $objectName, status: $status, contractorLegalName: $contractorLegalName, contractorPosition: $contractorPosition, contractorSigner: $contractorSigner, customerLegalName: $customerLegalName, customerPosition: $customerPosition, customerSigner: $customerSigner, createdAt: $createdAt, updatedAt: $updatedAt)';
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
      double vatRate,
      bool isVatIncluded,
      double vatAmount,
      double advanceAmount,
      double warrantyRetentionAmount,
      double warrantyRetentionRate,
      int warrantyPeriodMonths,
      double generalContractorFeeAmount,
      double generalContractorFeeRate,
      String objectId,
      String? objectName,
      ContractStatus status,
      String? contractorLegalName,
      String? contractorPosition,
      String? contractorSigner,
      String? customerLegalName,
      String? customerPosition,
      String? customerSigner,
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
    Object? vatRate = null,
    Object? isVatIncluded = null,
    Object? vatAmount = null,
    Object? advanceAmount = null,
    Object? warrantyRetentionAmount = null,
    Object? warrantyRetentionRate = null,
    Object? warrantyPeriodMonths = null,
    Object? generalContractorFeeAmount = null,
    Object? generalContractorFeeRate = null,
    Object? objectId = null,
    Object? objectName = freezed,
    Object? status = null,
    Object? contractorLegalName = freezed,
    Object? contractorPosition = freezed,
    Object? contractorSigner = freezed,
    Object? customerLegalName = freezed,
    Object? customerPosition = freezed,
    Object? customerSigner = freezed,
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
      vatRate: null == vatRate
          ? _self.vatRate
          : vatRate // ignore: cast_nullable_to_non_nullable
              as double,
      isVatIncluded: null == isVatIncluded
          ? _self.isVatIncluded
          : isVatIncluded // ignore: cast_nullable_to_non_nullable
              as bool,
      vatAmount: null == vatAmount
          ? _self.vatAmount
          : vatAmount // ignore: cast_nullable_to_non_nullable
              as double,
      advanceAmount: null == advanceAmount
          ? _self.advanceAmount
          : advanceAmount // ignore: cast_nullable_to_non_nullable
              as double,
      warrantyRetentionAmount: null == warrantyRetentionAmount
          ? _self.warrantyRetentionAmount
          : warrantyRetentionAmount // ignore: cast_nullable_to_non_nullable
              as double,
      warrantyRetentionRate: null == warrantyRetentionRate
          ? _self.warrantyRetentionRate
          : warrantyRetentionRate // ignore: cast_nullable_to_non_nullable
              as double,
      warrantyPeriodMonths: null == warrantyPeriodMonths
          ? _self.warrantyPeriodMonths
          : warrantyPeriodMonths // ignore: cast_nullable_to_non_nullable
              as int,
      generalContractorFeeAmount: null == generalContractorFeeAmount
          ? _self.generalContractorFeeAmount
          : generalContractorFeeAmount // ignore: cast_nullable_to_non_nullable
              as double,
      generalContractorFeeRate: null == generalContractorFeeRate
          ? _self.generalContractorFeeRate
          : generalContractorFeeRate // ignore: cast_nullable_to_non_nullable
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
      contractorLegalName: freezed == contractorLegalName
          ? _self.contractorLegalName
          : contractorLegalName // ignore: cast_nullable_to_non_nullable
              as String?,
      contractorPosition: freezed == contractorPosition
          ? _self.contractorPosition
          : contractorPosition // ignore: cast_nullable_to_non_nullable
              as String?,
      contractorSigner: freezed == contractorSigner
          ? _self.contractorSigner
          : contractorSigner // ignore: cast_nullable_to_non_nullable
              as String?,
      customerLegalName: freezed == customerLegalName
          ? _self.customerLegalName
          : customerLegalName // ignore: cast_nullable_to_non_nullable
              as String?,
      customerPosition: freezed == customerPosition
          ? _self.customerPosition
          : customerPosition // ignore: cast_nullable_to_non_nullable
              as String?,
      customerSigner: freezed == customerSigner
          ? _self.customerSigner
          : customerSigner // ignore: cast_nullable_to_non_nullable
              as String?,
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
