// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settlement_operation_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SettlementOperationModel {

 String get id; String get companyId; SettlementOperationType get operationType; String get objectId; String get contractorId; String get contractId;@JsonKey(toJson: dateOnlyToJson) DateTime? get periodFrom;@JsonKey(toJson: dateOnlyToJson) DateTime? get periodTo; String? get actNumber;@JsonKey(toJson: dateOnlyToJson) DateTime? get actDate; String get invoiceNumber;@JsonKey(toJson: dateOnlyToJson) DateTime get invoiceDate; double get amount; bool get isVatIncluded; double? get vatRate; double get vatAmount; double get advanceRetention; double get warrantyRetention; double get totalToPay; double get paidAmount; SettlementPaymentStatus get paymentStatus; String? get purpose; String? get note; DateTime? get createdAt; String? get createdBy;@JsonKey(includeToJson: false) String? get objectName;@JsonKey(includeToJson: false) String? get contractorName;@JsonKey(includeToJson: false) String? get contractNumber;
/// Create a copy of SettlementOperationModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettlementOperationModelCopyWith<SettlementOperationModel> get copyWith => _$SettlementOperationModelCopyWithImpl<SettlementOperationModel>(this as SettlementOperationModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettlementOperationModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.operationType, operationType) || other.operationType == operationType)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.contractorId, contractorId) || other.contractorId == contractorId)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.periodFrom, periodFrom) || other.periodFrom == periodFrom)&&(identical(other.periodTo, periodTo) || other.periodTo == periodTo)&&(identical(other.actNumber, actNumber) || other.actNumber == actNumber)&&(identical(other.actDate, actDate) || other.actDate == actDate)&&(identical(other.invoiceNumber, invoiceNumber) || other.invoiceNumber == invoiceNumber)&&(identical(other.invoiceDate, invoiceDate) || other.invoiceDate == invoiceDate)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.isVatIncluded, isVatIncluded) || other.isVatIncluded == isVatIncluded)&&(identical(other.vatRate, vatRate) || other.vatRate == vatRate)&&(identical(other.vatAmount, vatAmount) || other.vatAmount == vatAmount)&&(identical(other.advanceRetention, advanceRetention) || other.advanceRetention == advanceRetention)&&(identical(other.warrantyRetention, warrantyRetention) || other.warrantyRetention == warrantyRetention)&&(identical(other.totalToPay, totalToPay) || other.totalToPay == totalToPay)&&(identical(other.paidAmount, paidAmount) || other.paidAmount == paidAmount)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.purpose, purpose) || other.purpose == purpose)&&(identical(other.note, note) || other.note == note)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.objectName, objectName) || other.objectName == objectName)&&(identical(other.contractorName, contractorName) || other.contractorName == contractorName)&&(identical(other.contractNumber, contractNumber) || other.contractNumber == contractNumber));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,operationType,objectId,contractorId,contractId,periodFrom,periodTo,actNumber,actDate,invoiceNumber,invoiceDate,amount,isVatIncluded,vatRate,vatAmount,advanceRetention,warrantyRetention,totalToPay,paidAmount,paymentStatus,purpose,note,createdAt,createdBy,objectName,contractorName,contractNumber]);

@override
String toString() {
  return 'SettlementOperationModel(id: $id, companyId: $companyId, operationType: $operationType, objectId: $objectId, contractorId: $contractorId, contractId: $contractId, periodFrom: $periodFrom, periodTo: $periodTo, actNumber: $actNumber, actDate: $actDate, invoiceNumber: $invoiceNumber, invoiceDate: $invoiceDate, amount: $amount, isVatIncluded: $isVatIncluded, vatRate: $vatRate, vatAmount: $vatAmount, advanceRetention: $advanceRetention, warrantyRetention: $warrantyRetention, totalToPay: $totalToPay, paidAmount: $paidAmount, paymentStatus: $paymentStatus, purpose: $purpose, note: $note, createdAt: $createdAt, createdBy: $createdBy, objectName: $objectName, contractorName: $contractorName, contractNumber: $contractNumber)';
}


}

/// @nodoc
abstract mixin class $SettlementOperationModelCopyWith<$Res>  {
  factory $SettlementOperationModelCopyWith(SettlementOperationModel value, $Res Function(SettlementOperationModel) _then) = _$SettlementOperationModelCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, SettlementOperationType operationType, String objectId, String contractorId, String contractId,@JsonKey(toJson: dateOnlyToJson) DateTime? periodFrom,@JsonKey(toJson: dateOnlyToJson) DateTime? periodTo, String? actNumber,@JsonKey(toJson: dateOnlyToJson) DateTime? actDate, String invoiceNumber,@JsonKey(toJson: dateOnlyToJson) DateTime invoiceDate, double amount, bool isVatIncluded, double? vatRate, double vatAmount, double advanceRetention, double warrantyRetention, double totalToPay, double paidAmount, SettlementPaymentStatus paymentStatus, String? purpose, String? note, DateTime? createdAt, String? createdBy,@JsonKey(includeToJson: false) String? objectName,@JsonKey(includeToJson: false) String? contractorName,@JsonKey(includeToJson: false) String? contractNumber
});




}
/// @nodoc
class _$SettlementOperationModelCopyWithImpl<$Res>
    implements $SettlementOperationModelCopyWith<$Res> {
  _$SettlementOperationModelCopyWithImpl(this._self, this._then);

  final SettlementOperationModel _self;
  final $Res Function(SettlementOperationModel) _then;

/// Create a copy of SettlementOperationModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? operationType = null,Object? objectId = null,Object? contractorId = null,Object? contractId = null,Object? periodFrom = freezed,Object? periodTo = freezed,Object? actNumber = freezed,Object? actDate = freezed,Object? invoiceNumber = null,Object? invoiceDate = null,Object? amount = null,Object? isVatIncluded = null,Object? vatRate = freezed,Object? vatAmount = null,Object? advanceRetention = null,Object? warrantyRetention = null,Object? totalToPay = null,Object? paidAmount = null,Object? paymentStatus = null,Object? purpose = freezed,Object? note = freezed,Object? createdAt = freezed,Object? createdBy = freezed,Object? objectName = freezed,Object? contractorName = freezed,Object? contractNumber = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,operationType: null == operationType ? _self.operationType : operationType // ignore: cast_nullable_to_non_nullable
as SettlementOperationType,objectId: null == objectId ? _self.objectId : objectId // ignore: cast_nullable_to_non_nullable
as String,contractorId: null == contractorId ? _self.contractorId : contractorId // ignore: cast_nullable_to_non_nullable
as String,contractId: null == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String,periodFrom: freezed == periodFrom ? _self.periodFrom : periodFrom // ignore: cast_nullable_to_non_nullable
as DateTime?,periodTo: freezed == periodTo ? _self.periodTo : periodTo // ignore: cast_nullable_to_non_nullable
as DateTime?,actNumber: freezed == actNumber ? _self.actNumber : actNumber // ignore: cast_nullable_to_non_nullable
as String?,actDate: freezed == actDate ? _self.actDate : actDate // ignore: cast_nullable_to_non_nullable
as DateTime?,invoiceNumber: null == invoiceNumber ? _self.invoiceNumber : invoiceNumber // ignore: cast_nullable_to_non_nullable
as String,invoiceDate: null == invoiceDate ? _self.invoiceDate : invoiceDate // ignore: cast_nullable_to_non_nullable
as DateTime,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,isVatIncluded: null == isVatIncluded ? _self.isVatIncluded : isVatIncluded // ignore: cast_nullable_to_non_nullable
as bool,vatRate: freezed == vatRate ? _self.vatRate : vatRate // ignore: cast_nullable_to_non_nullable
as double?,vatAmount: null == vatAmount ? _self.vatAmount : vatAmount // ignore: cast_nullable_to_non_nullable
as double,advanceRetention: null == advanceRetention ? _self.advanceRetention : advanceRetention // ignore: cast_nullable_to_non_nullable
as double,warrantyRetention: null == warrantyRetention ? _self.warrantyRetention : warrantyRetention // ignore: cast_nullable_to_non_nullable
as double,totalToPay: null == totalToPay ? _self.totalToPay : totalToPay // ignore: cast_nullable_to_non_nullable
as double,paidAmount: null == paidAmount ? _self.paidAmount : paidAmount // ignore: cast_nullable_to_non_nullable
as double,paymentStatus: null == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as SettlementPaymentStatus,purpose: freezed == purpose ? _self.purpose : purpose // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,objectName: freezed == objectName ? _self.objectName : objectName // ignore: cast_nullable_to_non_nullable
as String?,contractorName: freezed == contractorName ? _self.contractorName : contractorName // ignore: cast_nullable_to_non_nullable
as String?,contractNumber: freezed == contractNumber ? _self.contractNumber : contractNumber // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _SettlementOperationModel extends SettlementOperationModel {
  const _SettlementOperationModel({required this.id, required this.companyId, required this.operationType, required this.objectId, required this.contractorId, required this.contractId, @JsonKey(toJson: dateOnlyToJson) this.periodFrom, @JsonKey(toJson: dateOnlyToJson) this.periodTo, this.actNumber, @JsonKey(toJson: dateOnlyToJson) this.actDate, required this.invoiceNumber, @JsonKey(toJson: dateOnlyToJson) required this.invoiceDate, required this.amount, this.isVatIncluded = true, this.vatRate, this.vatAmount = 0, this.advanceRetention = 0, this.warrantyRetention = 0, this.totalToPay = 0, this.paidAmount = 0, this.paymentStatus = SettlementPaymentStatus.unpaid, this.purpose, this.note, this.createdAt, this.createdBy, @JsonKey(includeToJson: false) this.objectName, @JsonKey(includeToJson: false) this.contractorName, @JsonKey(includeToJson: false) this.contractNumber}): super._();
  

@override final  String id;
@override final  String companyId;
@override final  SettlementOperationType operationType;
@override final  String objectId;
@override final  String contractorId;
@override final  String contractId;
@override@JsonKey(toJson: dateOnlyToJson) final  DateTime? periodFrom;
@override@JsonKey(toJson: dateOnlyToJson) final  DateTime? periodTo;
@override final  String? actNumber;
@override@JsonKey(toJson: dateOnlyToJson) final  DateTime? actDate;
@override final  String invoiceNumber;
@override@JsonKey(toJson: dateOnlyToJson) final  DateTime invoiceDate;
@override final  double amount;
@override@JsonKey() final  bool isVatIncluded;
@override final  double? vatRate;
@override@JsonKey() final  double vatAmount;
@override@JsonKey() final  double advanceRetention;
@override@JsonKey() final  double warrantyRetention;
@override@JsonKey() final  double totalToPay;
@override@JsonKey() final  double paidAmount;
@override@JsonKey() final  SettlementPaymentStatus paymentStatus;
@override final  String? purpose;
@override final  String? note;
@override final  DateTime? createdAt;
@override final  String? createdBy;
@override@JsonKey(includeToJson: false) final  String? objectName;
@override@JsonKey(includeToJson: false) final  String? contractorName;
@override@JsonKey(includeToJson: false) final  String? contractNumber;

/// Create a copy of SettlementOperationModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SettlementOperationModelCopyWith<_SettlementOperationModel> get copyWith => __$SettlementOperationModelCopyWithImpl<_SettlementOperationModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SettlementOperationModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.operationType, operationType) || other.operationType == operationType)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.contractorId, contractorId) || other.contractorId == contractorId)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.periodFrom, periodFrom) || other.periodFrom == periodFrom)&&(identical(other.periodTo, periodTo) || other.periodTo == periodTo)&&(identical(other.actNumber, actNumber) || other.actNumber == actNumber)&&(identical(other.actDate, actDate) || other.actDate == actDate)&&(identical(other.invoiceNumber, invoiceNumber) || other.invoiceNumber == invoiceNumber)&&(identical(other.invoiceDate, invoiceDate) || other.invoiceDate == invoiceDate)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.isVatIncluded, isVatIncluded) || other.isVatIncluded == isVatIncluded)&&(identical(other.vatRate, vatRate) || other.vatRate == vatRate)&&(identical(other.vatAmount, vatAmount) || other.vatAmount == vatAmount)&&(identical(other.advanceRetention, advanceRetention) || other.advanceRetention == advanceRetention)&&(identical(other.warrantyRetention, warrantyRetention) || other.warrantyRetention == warrantyRetention)&&(identical(other.totalToPay, totalToPay) || other.totalToPay == totalToPay)&&(identical(other.paidAmount, paidAmount) || other.paidAmount == paidAmount)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.purpose, purpose) || other.purpose == purpose)&&(identical(other.note, note) || other.note == note)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.objectName, objectName) || other.objectName == objectName)&&(identical(other.contractorName, contractorName) || other.contractorName == contractorName)&&(identical(other.contractNumber, contractNumber) || other.contractNumber == contractNumber));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,operationType,objectId,contractorId,contractId,periodFrom,periodTo,actNumber,actDate,invoiceNumber,invoiceDate,amount,isVatIncluded,vatRate,vatAmount,advanceRetention,warrantyRetention,totalToPay,paidAmount,paymentStatus,purpose,note,createdAt,createdBy,objectName,contractorName,contractNumber]);

@override
String toString() {
  return 'SettlementOperationModel(id: $id, companyId: $companyId, operationType: $operationType, objectId: $objectId, contractorId: $contractorId, contractId: $contractId, periodFrom: $periodFrom, periodTo: $periodTo, actNumber: $actNumber, actDate: $actDate, invoiceNumber: $invoiceNumber, invoiceDate: $invoiceDate, amount: $amount, isVatIncluded: $isVatIncluded, vatRate: $vatRate, vatAmount: $vatAmount, advanceRetention: $advanceRetention, warrantyRetention: $warrantyRetention, totalToPay: $totalToPay, paidAmount: $paidAmount, paymentStatus: $paymentStatus, purpose: $purpose, note: $note, createdAt: $createdAt, createdBy: $createdBy, objectName: $objectName, contractorName: $contractorName, contractNumber: $contractNumber)';
}


}

/// @nodoc
abstract mixin class _$SettlementOperationModelCopyWith<$Res> implements $SettlementOperationModelCopyWith<$Res> {
  factory _$SettlementOperationModelCopyWith(_SettlementOperationModel value, $Res Function(_SettlementOperationModel) _then) = __$SettlementOperationModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, SettlementOperationType operationType, String objectId, String contractorId, String contractId,@JsonKey(toJson: dateOnlyToJson) DateTime? periodFrom,@JsonKey(toJson: dateOnlyToJson) DateTime? periodTo, String? actNumber,@JsonKey(toJson: dateOnlyToJson) DateTime? actDate, String invoiceNumber,@JsonKey(toJson: dateOnlyToJson) DateTime invoiceDate, double amount, bool isVatIncluded, double? vatRate, double vatAmount, double advanceRetention, double warrantyRetention, double totalToPay, double paidAmount, SettlementPaymentStatus paymentStatus, String? purpose, String? note, DateTime? createdAt, String? createdBy,@JsonKey(includeToJson: false) String? objectName,@JsonKey(includeToJson: false) String? contractorName,@JsonKey(includeToJson: false) String? contractNumber
});




}
/// @nodoc
class __$SettlementOperationModelCopyWithImpl<$Res>
    implements _$SettlementOperationModelCopyWith<$Res> {
  __$SettlementOperationModelCopyWithImpl(this._self, this._then);

  final _SettlementOperationModel _self;
  final $Res Function(_SettlementOperationModel) _then;

/// Create a copy of SettlementOperationModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? operationType = null,Object? objectId = null,Object? contractorId = null,Object? contractId = null,Object? periodFrom = freezed,Object? periodTo = freezed,Object? actNumber = freezed,Object? actDate = freezed,Object? invoiceNumber = null,Object? invoiceDate = null,Object? amount = null,Object? isVatIncluded = null,Object? vatRate = freezed,Object? vatAmount = null,Object? advanceRetention = null,Object? warrantyRetention = null,Object? totalToPay = null,Object? paidAmount = null,Object? paymentStatus = null,Object? purpose = freezed,Object? note = freezed,Object? createdAt = freezed,Object? createdBy = freezed,Object? objectName = freezed,Object? contractorName = freezed,Object? contractNumber = freezed,}) {
  return _then(_SettlementOperationModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,operationType: null == operationType ? _self.operationType : operationType // ignore: cast_nullable_to_non_nullable
as SettlementOperationType,objectId: null == objectId ? _self.objectId : objectId // ignore: cast_nullable_to_non_nullable
as String,contractorId: null == contractorId ? _self.contractorId : contractorId // ignore: cast_nullable_to_non_nullable
as String,contractId: null == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String,periodFrom: freezed == periodFrom ? _self.periodFrom : periodFrom // ignore: cast_nullable_to_non_nullable
as DateTime?,periodTo: freezed == periodTo ? _self.periodTo : periodTo // ignore: cast_nullable_to_non_nullable
as DateTime?,actNumber: freezed == actNumber ? _self.actNumber : actNumber // ignore: cast_nullable_to_non_nullable
as String?,actDate: freezed == actDate ? _self.actDate : actDate // ignore: cast_nullable_to_non_nullable
as DateTime?,invoiceNumber: null == invoiceNumber ? _self.invoiceNumber : invoiceNumber // ignore: cast_nullable_to_non_nullable
as String,invoiceDate: null == invoiceDate ? _self.invoiceDate : invoiceDate // ignore: cast_nullable_to_non_nullable
as DateTime,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,isVatIncluded: null == isVatIncluded ? _self.isVatIncluded : isVatIncluded // ignore: cast_nullable_to_non_nullable
as bool,vatRate: freezed == vatRate ? _self.vatRate : vatRate // ignore: cast_nullable_to_non_nullable
as double?,vatAmount: null == vatAmount ? _self.vatAmount : vatAmount // ignore: cast_nullable_to_non_nullable
as double,advanceRetention: null == advanceRetention ? _self.advanceRetention : advanceRetention // ignore: cast_nullable_to_non_nullable
as double,warrantyRetention: null == warrantyRetention ? _self.warrantyRetention : warrantyRetention // ignore: cast_nullable_to_non_nullable
as double,totalToPay: null == totalToPay ? _self.totalToPay : totalToPay // ignore: cast_nullable_to_non_nullable
as double,paidAmount: null == paidAmount ? _self.paidAmount : paidAmount // ignore: cast_nullable_to_non_nullable
as double,paymentStatus: null == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as SettlementPaymentStatus,purpose: freezed == purpose ? _self.purpose : purpose // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,objectName: freezed == objectName ? _self.objectName : objectName // ignore: cast_nullable_to_non_nullable
as String?,contractorName: freezed == contractorName ? _self.contractorName : contractorName // ignore: cast_nullable_to_non_nullable
as String?,contractNumber: freezed == contractNumber ? _self.contractNumber : contractNumber // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
