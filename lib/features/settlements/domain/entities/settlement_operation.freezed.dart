// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settlement_operation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SettlementOperation {

/// Идентификатор записи.
 String get id;/// Компания-владелец.
 String get companyId;/// Тип операции.
 SettlementOperationType get operationType;/// Объект.
 String get objectId;/// Название объекта (join).
 String? get objectName;/// Контрагент.
 String get contractorId;/// Название контрагента (join).
 String? get contractorName;/// Договор.
 String get contractId;/// Номер договора (join).
 String? get contractNumber;/// Начало периода работ (для типа акт).
 DateTime? get periodFrom;/// Конец периода работ (для типа акт).
 DateTime? get periodTo;/// Номер акта (для типа акт).
 String? get actNumber;/// Дата акта (для типа акт).
 DateTime? get actDate;/// Номер счёта.
 String get invoiceNumber;/// Дата счёта.
 DateTime get invoiceDate;/// Базовая сумма (без НДС).
 double get amount;/// Включён ли НДС в введённую сумму (true — «в том числе», false — «сверху»).
 bool get isVatIncluded;/// Ставка НДС (в процентах). null = без НДС.
 double? get vatRate;/// Сумма НДС.
 double get vatAmount;/// Авансовые удержания (только акт).
 double get advanceRetention;/// Гарантийные удержания (только акт).
 double get warrantyRetention;/// К оплате (из БД / формулы).
 double get totalToPay;/// Уже оплачено.
 double get paidAmount;/// Статус оплаты.
 SettlementPaymentStatus get paymentStatus;/// Назначение (обязательно для «прочее»).
 String? get purpose;/// Комментарий.
 String? get note;/// Дата создания.
 DateTime? get createdAt;/// Автор.
 String? get createdBy;
/// Create a copy of SettlementOperation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettlementOperationCopyWith<SettlementOperation> get copyWith => _$SettlementOperationCopyWithImpl<SettlementOperation>(this as SettlementOperation, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettlementOperation&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.operationType, operationType) || other.operationType == operationType)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.objectName, objectName) || other.objectName == objectName)&&(identical(other.contractorId, contractorId) || other.contractorId == contractorId)&&(identical(other.contractorName, contractorName) || other.contractorName == contractorName)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.contractNumber, contractNumber) || other.contractNumber == contractNumber)&&(identical(other.periodFrom, periodFrom) || other.periodFrom == periodFrom)&&(identical(other.periodTo, periodTo) || other.periodTo == periodTo)&&(identical(other.actNumber, actNumber) || other.actNumber == actNumber)&&(identical(other.actDate, actDate) || other.actDate == actDate)&&(identical(other.invoiceNumber, invoiceNumber) || other.invoiceNumber == invoiceNumber)&&(identical(other.invoiceDate, invoiceDate) || other.invoiceDate == invoiceDate)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.isVatIncluded, isVatIncluded) || other.isVatIncluded == isVatIncluded)&&(identical(other.vatRate, vatRate) || other.vatRate == vatRate)&&(identical(other.vatAmount, vatAmount) || other.vatAmount == vatAmount)&&(identical(other.advanceRetention, advanceRetention) || other.advanceRetention == advanceRetention)&&(identical(other.warrantyRetention, warrantyRetention) || other.warrantyRetention == warrantyRetention)&&(identical(other.totalToPay, totalToPay) || other.totalToPay == totalToPay)&&(identical(other.paidAmount, paidAmount) || other.paidAmount == paidAmount)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.purpose, purpose) || other.purpose == purpose)&&(identical(other.note, note) || other.note == note)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,operationType,objectId,objectName,contractorId,contractorName,contractId,contractNumber,periodFrom,periodTo,actNumber,actDate,invoiceNumber,invoiceDate,amount,isVatIncluded,vatRate,vatAmount,advanceRetention,warrantyRetention,totalToPay,paidAmount,paymentStatus,purpose,note,createdAt,createdBy]);

@override
String toString() {
  return 'SettlementOperation(id: $id, companyId: $companyId, operationType: $operationType, objectId: $objectId, objectName: $objectName, contractorId: $contractorId, contractorName: $contractorName, contractId: $contractId, contractNumber: $contractNumber, periodFrom: $periodFrom, periodTo: $periodTo, actNumber: $actNumber, actDate: $actDate, invoiceNumber: $invoiceNumber, invoiceDate: $invoiceDate, amount: $amount, isVatIncluded: $isVatIncluded, vatRate: $vatRate, vatAmount: $vatAmount, advanceRetention: $advanceRetention, warrantyRetention: $warrantyRetention, totalToPay: $totalToPay, paidAmount: $paidAmount, paymentStatus: $paymentStatus, purpose: $purpose, note: $note, createdAt: $createdAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class $SettlementOperationCopyWith<$Res>  {
  factory $SettlementOperationCopyWith(SettlementOperation value, $Res Function(SettlementOperation) _then) = _$SettlementOperationCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, SettlementOperationType operationType, String objectId, String? objectName, String contractorId, String? contractorName, String contractId, String? contractNumber, DateTime? periodFrom, DateTime? periodTo, String? actNumber, DateTime? actDate, String invoiceNumber, DateTime invoiceDate, double amount, bool isVatIncluded, double? vatRate, double vatAmount, double advanceRetention, double warrantyRetention, double totalToPay, double paidAmount, SettlementPaymentStatus paymentStatus, String? purpose, String? note, DateTime? createdAt, String? createdBy
});




}
/// @nodoc
class _$SettlementOperationCopyWithImpl<$Res>
    implements $SettlementOperationCopyWith<$Res> {
  _$SettlementOperationCopyWithImpl(this._self, this._then);

  final SettlementOperation _self;
  final $Res Function(SettlementOperation) _then;

/// Create a copy of SettlementOperation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? operationType = null,Object? objectId = null,Object? objectName = freezed,Object? contractorId = null,Object? contractorName = freezed,Object? contractId = null,Object? contractNumber = freezed,Object? periodFrom = freezed,Object? periodTo = freezed,Object? actNumber = freezed,Object? actDate = freezed,Object? invoiceNumber = null,Object? invoiceDate = null,Object? amount = null,Object? isVatIncluded = null,Object? vatRate = freezed,Object? vatAmount = null,Object? advanceRetention = null,Object? warrantyRetention = null,Object? totalToPay = null,Object? paidAmount = null,Object? paymentStatus = null,Object? purpose = freezed,Object? note = freezed,Object? createdAt = freezed,Object? createdBy = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,operationType: null == operationType ? _self.operationType : operationType // ignore: cast_nullable_to_non_nullable
as SettlementOperationType,objectId: null == objectId ? _self.objectId : objectId // ignore: cast_nullable_to_non_nullable
as String,objectName: freezed == objectName ? _self.objectName : objectName // ignore: cast_nullable_to_non_nullable
as String?,contractorId: null == contractorId ? _self.contractorId : contractorId // ignore: cast_nullable_to_non_nullable
as String,contractorName: freezed == contractorName ? _self.contractorName : contractorName // ignore: cast_nullable_to_non_nullable
as String?,contractId: null == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String,contractNumber: freezed == contractNumber ? _self.contractNumber : contractNumber // ignore: cast_nullable_to_non_nullable
as String?,periodFrom: freezed == periodFrom ? _self.periodFrom : periodFrom // ignore: cast_nullable_to_non_nullable
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
as String?,
  ));
}

}


/// @nodoc


class _SettlementOperation extends SettlementOperation {
  const _SettlementOperation({required this.id, required this.companyId, required this.operationType, required this.objectId, this.objectName, required this.contractorId, this.contractorName, required this.contractId, this.contractNumber, this.periodFrom, this.periodTo, this.actNumber, this.actDate, required this.invoiceNumber, required this.invoiceDate, required this.amount, this.isVatIncluded = true, this.vatRate, this.vatAmount = 0, this.advanceRetention = 0, this.warrantyRetention = 0, this.totalToPay = 0, this.paidAmount = 0, this.paymentStatus = SettlementPaymentStatus.unpaid, this.purpose, this.note, this.createdAt, this.createdBy}): super._();
  

/// Идентификатор записи.
@override final  String id;
/// Компания-владелец.
@override final  String companyId;
/// Тип операции.
@override final  SettlementOperationType operationType;
/// Объект.
@override final  String objectId;
/// Название объекта (join).
@override final  String? objectName;
/// Контрагент.
@override final  String contractorId;
/// Название контрагента (join).
@override final  String? contractorName;
/// Договор.
@override final  String contractId;
/// Номер договора (join).
@override final  String? contractNumber;
/// Начало периода работ (для типа акт).
@override final  DateTime? periodFrom;
/// Конец периода работ (для типа акт).
@override final  DateTime? periodTo;
/// Номер акта (для типа акт).
@override final  String? actNumber;
/// Дата акта (для типа акт).
@override final  DateTime? actDate;
/// Номер счёта.
@override final  String invoiceNumber;
/// Дата счёта.
@override final  DateTime invoiceDate;
/// Базовая сумма (без НДС).
@override final  double amount;
/// Включён ли НДС в введённую сумму (true — «в том числе», false — «сверху»).
@override@JsonKey() final  bool isVatIncluded;
/// Ставка НДС (в процентах). null = без НДС.
@override final  double? vatRate;
/// Сумма НДС.
@override@JsonKey() final  double vatAmount;
/// Авансовые удержания (только акт).
@override@JsonKey() final  double advanceRetention;
/// Гарантийные удержания (только акт).
@override@JsonKey() final  double warrantyRetention;
/// К оплате (из БД / формулы).
@override@JsonKey() final  double totalToPay;
/// Уже оплачено.
@override@JsonKey() final  double paidAmount;
/// Статус оплаты.
@override@JsonKey() final  SettlementPaymentStatus paymentStatus;
/// Назначение (обязательно для «прочее»).
@override final  String? purpose;
/// Комментарий.
@override final  String? note;
/// Дата создания.
@override final  DateTime? createdAt;
/// Автор.
@override final  String? createdBy;

/// Create a copy of SettlementOperation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SettlementOperationCopyWith<_SettlementOperation> get copyWith => __$SettlementOperationCopyWithImpl<_SettlementOperation>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SettlementOperation&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.operationType, operationType) || other.operationType == operationType)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.objectName, objectName) || other.objectName == objectName)&&(identical(other.contractorId, contractorId) || other.contractorId == contractorId)&&(identical(other.contractorName, contractorName) || other.contractorName == contractorName)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.contractNumber, contractNumber) || other.contractNumber == contractNumber)&&(identical(other.periodFrom, periodFrom) || other.periodFrom == periodFrom)&&(identical(other.periodTo, periodTo) || other.periodTo == periodTo)&&(identical(other.actNumber, actNumber) || other.actNumber == actNumber)&&(identical(other.actDate, actDate) || other.actDate == actDate)&&(identical(other.invoiceNumber, invoiceNumber) || other.invoiceNumber == invoiceNumber)&&(identical(other.invoiceDate, invoiceDate) || other.invoiceDate == invoiceDate)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.isVatIncluded, isVatIncluded) || other.isVatIncluded == isVatIncluded)&&(identical(other.vatRate, vatRate) || other.vatRate == vatRate)&&(identical(other.vatAmount, vatAmount) || other.vatAmount == vatAmount)&&(identical(other.advanceRetention, advanceRetention) || other.advanceRetention == advanceRetention)&&(identical(other.warrantyRetention, warrantyRetention) || other.warrantyRetention == warrantyRetention)&&(identical(other.totalToPay, totalToPay) || other.totalToPay == totalToPay)&&(identical(other.paidAmount, paidAmount) || other.paidAmount == paidAmount)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.purpose, purpose) || other.purpose == purpose)&&(identical(other.note, note) || other.note == note)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,operationType,objectId,objectName,contractorId,contractorName,contractId,contractNumber,periodFrom,periodTo,actNumber,actDate,invoiceNumber,invoiceDate,amount,isVatIncluded,vatRate,vatAmount,advanceRetention,warrantyRetention,totalToPay,paidAmount,paymentStatus,purpose,note,createdAt,createdBy]);

@override
String toString() {
  return 'SettlementOperation(id: $id, companyId: $companyId, operationType: $operationType, objectId: $objectId, objectName: $objectName, contractorId: $contractorId, contractorName: $contractorName, contractId: $contractId, contractNumber: $contractNumber, periodFrom: $periodFrom, periodTo: $periodTo, actNumber: $actNumber, actDate: $actDate, invoiceNumber: $invoiceNumber, invoiceDate: $invoiceDate, amount: $amount, isVatIncluded: $isVatIncluded, vatRate: $vatRate, vatAmount: $vatAmount, advanceRetention: $advanceRetention, warrantyRetention: $warrantyRetention, totalToPay: $totalToPay, paidAmount: $paidAmount, paymentStatus: $paymentStatus, purpose: $purpose, note: $note, createdAt: $createdAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class _$SettlementOperationCopyWith<$Res> implements $SettlementOperationCopyWith<$Res> {
  factory _$SettlementOperationCopyWith(_SettlementOperation value, $Res Function(_SettlementOperation) _then) = __$SettlementOperationCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, SettlementOperationType operationType, String objectId, String? objectName, String contractorId, String? contractorName, String contractId, String? contractNumber, DateTime? periodFrom, DateTime? periodTo, String? actNumber, DateTime? actDate, String invoiceNumber, DateTime invoiceDate, double amount, bool isVatIncluded, double? vatRate, double vatAmount, double advanceRetention, double warrantyRetention, double totalToPay, double paidAmount, SettlementPaymentStatus paymentStatus, String? purpose, String? note, DateTime? createdAt, String? createdBy
});




}
/// @nodoc
class __$SettlementOperationCopyWithImpl<$Res>
    implements _$SettlementOperationCopyWith<$Res> {
  __$SettlementOperationCopyWithImpl(this._self, this._then);

  final _SettlementOperation _self;
  final $Res Function(_SettlementOperation) _then;

/// Create a copy of SettlementOperation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? operationType = null,Object? objectId = null,Object? objectName = freezed,Object? contractorId = null,Object? contractorName = freezed,Object? contractId = null,Object? contractNumber = freezed,Object? periodFrom = freezed,Object? periodTo = freezed,Object? actNumber = freezed,Object? actDate = freezed,Object? invoiceNumber = null,Object? invoiceDate = null,Object? amount = null,Object? isVatIncluded = null,Object? vatRate = freezed,Object? vatAmount = null,Object? advanceRetention = null,Object? warrantyRetention = null,Object? totalToPay = null,Object? paidAmount = null,Object? paymentStatus = null,Object? purpose = freezed,Object? note = freezed,Object? createdAt = freezed,Object? createdBy = freezed,}) {
  return _then(_SettlementOperation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,operationType: null == operationType ? _self.operationType : operationType // ignore: cast_nullable_to_non_nullable
as SettlementOperationType,objectId: null == objectId ? _self.objectId : objectId // ignore: cast_nullable_to_non_nullable
as String,objectName: freezed == objectName ? _self.objectName : objectName // ignore: cast_nullable_to_non_nullable
as String?,contractorId: null == contractorId ? _self.contractorId : contractorId // ignore: cast_nullable_to_non_nullable
as String,contractorName: freezed == contractorName ? _self.contractorName : contractorName // ignore: cast_nullable_to_non_nullable
as String?,contractId: null == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String,contractNumber: freezed == contractNumber ? _self.contractNumber : contractNumber // ignore: cast_nullable_to_non_nullable
as String?,periodFrom: freezed == periodFrom ? _self.periodFrom : periodFrom // ignore: cast_nullable_to_non_nullable
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
as String?,
  ));
}


}

// dart format on
