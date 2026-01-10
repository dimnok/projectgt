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
 String get id;/// Идентификатор компании.
 String get companyId;/// Номер контракта.
 String get number;/// Дата заключения контракта.
 DateTime get date;/// Дата окончания действия контракта.
 DateTime? get endDate;/// Идентификатор подрядчика.
 String get contractorId;/// Имя подрядчика.
 String? get contractorName;/// Сумма контракта.
 double get amount;/// Ставка НДС (в процентах).
 double get vatRate;/// Включен ли НДС в стоимость (true - в том числе, false - сверху).
 bool get isVatIncluded;/// Сумма НДС.
 double get vatAmount;/// Сумма аванса.
 double get advanceAmount;/// Гарантийные удержания (сумма).
 double get warrantyRetentionAmount;/// Процент гарантийных удержаний.
 double get warrantyRetentionRate;/// Срок гарантийных обязательств (в месяцах).
 int get warrantyPeriodMonths;/// Генподрядные (сумма).
 double get generalContractorFeeAmount;/// Процент генподрядных.
 double get generalContractorFeeRate;/// Идентификатор объекта.
 String get objectId;/// Имя объекта.
 String? get objectName;/// Статус контракта ([ContractStatus]).
 ContractStatus get status;/// Название организации подрядчика (для документов).
 String? get contractorOrgName;/// Должность подписанта подрядчика.
 String? get contractorPosition;/// ФИО подписанта подрядчика.
 String? get contractorSigner;/// Название организации заказчика (для документов).
 String? get customerOrgName;/// Должность подписанта заказчика.
 String? get customerPosition;/// ФИО подписанта заказчика.
 String? get customerSigner;/// Дата создания записи.
 DateTime? get createdAt;/// Дата последнего обновления записи.
 DateTime? get updatedAt;
/// Create a copy of Contract
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContractCopyWith<Contract> get copyWith => _$ContractCopyWithImpl<Contract>(this as Contract, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Contract&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.number, number) || other.number == number)&&(identical(other.date, date) || other.date == date)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.contractorId, contractorId) || other.contractorId == contractorId)&&(identical(other.contractorName, contractorName) || other.contractorName == contractorName)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.vatRate, vatRate) || other.vatRate == vatRate)&&(identical(other.isVatIncluded, isVatIncluded) || other.isVatIncluded == isVatIncluded)&&(identical(other.vatAmount, vatAmount) || other.vatAmount == vatAmount)&&(identical(other.advanceAmount, advanceAmount) || other.advanceAmount == advanceAmount)&&(identical(other.warrantyRetentionAmount, warrantyRetentionAmount) || other.warrantyRetentionAmount == warrantyRetentionAmount)&&(identical(other.warrantyRetentionRate, warrantyRetentionRate) || other.warrantyRetentionRate == warrantyRetentionRate)&&(identical(other.warrantyPeriodMonths, warrantyPeriodMonths) || other.warrantyPeriodMonths == warrantyPeriodMonths)&&(identical(other.generalContractorFeeAmount, generalContractorFeeAmount) || other.generalContractorFeeAmount == generalContractorFeeAmount)&&(identical(other.generalContractorFeeRate, generalContractorFeeRate) || other.generalContractorFeeRate == generalContractorFeeRate)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.objectName, objectName) || other.objectName == objectName)&&(identical(other.status, status) || other.status == status)&&(identical(other.contractorOrgName, contractorOrgName) || other.contractorOrgName == contractorOrgName)&&(identical(other.contractorPosition, contractorPosition) || other.contractorPosition == contractorPosition)&&(identical(other.contractorSigner, contractorSigner) || other.contractorSigner == contractorSigner)&&(identical(other.customerOrgName, customerOrgName) || other.customerOrgName == customerOrgName)&&(identical(other.customerPosition, customerPosition) || other.customerPosition == customerPosition)&&(identical(other.customerSigner, customerSigner) || other.customerSigner == customerSigner)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,number,date,endDate,contractorId,contractorName,amount,vatRate,isVatIncluded,vatAmount,advanceAmount,warrantyRetentionAmount,warrantyRetentionRate,warrantyPeriodMonths,generalContractorFeeAmount,generalContractorFeeRate,objectId,objectName,status,contractorOrgName,contractorPosition,contractorSigner,customerOrgName,customerPosition,customerSigner,createdAt,updatedAt]);

@override
String toString() {
  return 'Contract(id: $id, companyId: $companyId, number: $number, date: $date, endDate: $endDate, contractorId: $contractorId, contractorName: $contractorName, amount: $amount, vatRate: $vatRate, isVatIncluded: $isVatIncluded, vatAmount: $vatAmount, advanceAmount: $advanceAmount, warrantyRetentionAmount: $warrantyRetentionAmount, warrantyRetentionRate: $warrantyRetentionRate, warrantyPeriodMonths: $warrantyPeriodMonths, generalContractorFeeAmount: $generalContractorFeeAmount, generalContractorFeeRate: $generalContractorFeeRate, objectId: $objectId, objectName: $objectName, status: $status, contractorOrgName: $contractorOrgName, contractorPosition: $contractorPosition, contractorSigner: $contractorSigner, customerOrgName: $customerOrgName, customerPosition: $customerPosition, customerSigner: $customerSigner, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ContractCopyWith<$Res>  {
  factory $ContractCopyWith(Contract value, $Res Function(Contract) _then) = _$ContractCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String number, DateTime date, DateTime? endDate, String contractorId, String? contractorName, double amount, double vatRate, bool isVatIncluded, double vatAmount, double advanceAmount, double warrantyRetentionAmount, double warrantyRetentionRate, int warrantyPeriodMonths, double generalContractorFeeAmount, double generalContractorFeeRate, String objectId, String? objectName, ContractStatus status, String? contractorOrgName, String? contractorPosition, String? contractorSigner, String? customerOrgName, String? customerPosition, String? customerSigner, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$ContractCopyWithImpl<$Res>
    implements $ContractCopyWith<$Res> {
  _$ContractCopyWithImpl(this._self, this._then);

  final Contract _self;
  final $Res Function(Contract) _then;

/// Create a copy of Contract
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? number = null,Object? date = null,Object? endDate = freezed,Object? contractorId = null,Object? contractorName = freezed,Object? amount = null,Object? vatRate = null,Object? isVatIncluded = null,Object? vatAmount = null,Object? advanceAmount = null,Object? warrantyRetentionAmount = null,Object? warrantyRetentionRate = null,Object? warrantyPeriodMonths = null,Object? generalContractorFeeAmount = null,Object? generalContractorFeeRate = null,Object? objectId = null,Object? objectName = freezed,Object? status = null,Object? contractorOrgName = freezed,Object? contractorPosition = freezed,Object? contractorSigner = freezed,Object? customerOrgName = freezed,Object? customerPosition = freezed,Object? customerSigner = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,contractorId: null == contractorId ? _self.contractorId : contractorId // ignore: cast_nullable_to_non_nullable
as String,contractorName: freezed == contractorName ? _self.contractorName : contractorName // ignore: cast_nullable_to_non_nullable
as String?,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,vatRate: null == vatRate ? _self.vatRate : vatRate // ignore: cast_nullable_to_non_nullable
as double,isVatIncluded: null == isVatIncluded ? _self.isVatIncluded : isVatIncluded // ignore: cast_nullable_to_non_nullable
as bool,vatAmount: null == vatAmount ? _self.vatAmount : vatAmount // ignore: cast_nullable_to_non_nullable
as double,advanceAmount: null == advanceAmount ? _self.advanceAmount : advanceAmount // ignore: cast_nullable_to_non_nullable
as double,warrantyRetentionAmount: null == warrantyRetentionAmount ? _self.warrantyRetentionAmount : warrantyRetentionAmount // ignore: cast_nullable_to_non_nullable
as double,warrantyRetentionRate: null == warrantyRetentionRate ? _self.warrantyRetentionRate : warrantyRetentionRate // ignore: cast_nullable_to_non_nullable
as double,warrantyPeriodMonths: null == warrantyPeriodMonths ? _self.warrantyPeriodMonths : warrantyPeriodMonths // ignore: cast_nullable_to_non_nullable
as int,generalContractorFeeAmount: null == generalContractorFeeAmount ? _self.generalContractorFeeAmount : generalContractorFeeAmount // ignore: cast_nullable_to_non_nullable
as double,generalContractorFeeRate: null == generalContractorFeeRate ? _self.generalContractorFeeRate : generalContractorFeeRate // ignore: cast_nullable_to_non_nullable
as double,objectId: null == objectId ? _self.objectId : objectId // ignore: cast_nullable_to_non_nullable
as String,objectName: freezed == objectName ? _self.objectName : objectName // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ContractStatus,contractorOrgName: freezed == contractorOrgName ? _self.contractorOrgName : contractorOrgName // ignore: cast_nullable_to_non_nullable
as String?,contractorPosition: freezed == contractorPosition ? _self.contractorPosition : contractorPosition // ignore: cast_nullable_to_non_nullable
as String?,contractorSigner: freezed == contractorSigner ? _self.contractorSigner : contractorSigner // ignore: cast_nullable_to_non_nullable
as String?,customerOrgName: freezed == customerOrgName ? _self.customerOrgName : customerOrgName // ignore: cast_nullable_to_non_nullable
as String?,customerPosition: freezed == customerPosition ? _self.customerPosition : customerPosition // ignore: cast_nullable_to_non_nullable
as String?,customerSigner: freezed == customerSigner ? _self.customerSigner : customerSigner // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc


class _Contract extends Contract {
  const _Contract({required this.id, required this.companyId, required this.number, required this.date, this.endDate, required this.contractorId, this.contractorName, required this.amount, this.vatRate = 0.0, this.isVatIncluded = true, this.vatAmount = 0.0, this.advanceAmount = 0.0, this.warrantyRetentionAmount = 0.0, this.warrantyRetentionRate = 0.0, this.warrantyPeriodMonths = 0, this.generalContractorFeeAmount = 0.0, this.generalContractorFeeRate = 0.0, required this.objectId, this.objectName, this.status = ContractStatus.active, this.contractorOrgName, this.contractorPosition, this.contractorSigner, this.customerOrgName, this.customerPosition, this.customerSigner, this.createdAt, this.updatedAt}): super._();
  

/// Уникальный идентификатор контракта.
@override final  String id;
/// Идентификатор компании.
@override final  String companyId;
/// Номер контракта.
@override final  String number;
/// Дата заключения контракта.
@override final  DateTime date;
/// Дата окончания действия контракта.
@override final  DateTime? endDate;
/// Идентификатор подрядчика.
@override final  String contractorId;
/// Имя подрядчика.
@override final  String? contractorName;
/// Сумма контракта.
@override final  double amount;
/// Ставка НДС (в процентах).
@override@JsonKey() final  double vatRate;
/// Включен ли НДС в стоимость (true - в том числе, false - сверху).
@override@JsonKey() final  bool isVatIncluded;
/// Сумма НДС.
@override@JsonKey() final  double vatAmount;
/// Сумма аванса.
@override@JsonKey() final  double advanceAmount;
/// Гарантийные удержания (сумма).
@override@JsonKey() final  double warrantyRetentionAmount;
/// Процент гарантийных удержаний.
@override@JsonKey() final  double warrantyRetentionRate;
/// Срок гарантийных обязательств (в месяцах).
@override@JsonKey() final  int warrantyPeriodMonths;
/// Генподрядные (сумма).
@override@JsonKey() final  double generalContractorFeeAmount;
/// Процент генподрядных.
@override@JsonKey() final  double generalContractorFeeRate;
/// Идентификатор объекта.
@override final  String objectId;
/// Имя объекта.
@override final  String? objectName;
/// Статус контракта ([ContractStatus]).
@override@JsonKey() final  ContractStatus status;
/// Название организации подрядчика (для документов).
@override final  String? contractorOrgName;
/// Должность подписанта подрядчика.
@override final  String? contractorPosition;
/// ФИО подписанта подрядчика.
@override final  String? contractorSigner;
/// Название организации заказчика (для документов).
@override final  String? customerOrgName;
/// Должность подписанта заказчика.
@override final  String? customerPosition;
/// ФИО подписанта заказчика.
@override final  String? customerSigner;
/// Дата создания записи.
@override final  DateTime? createdAt;
/// Дата последнего обновления записи.
@override final  DateTime? updatedAt;

/// Create a copy of Contract
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContractCopyWith<_Contract> get copyWith => __$ContractCopyWithImpl<_Contract>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Contract&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.number, number) || other.number == number)&&(identical(other.date, date) || other.date == date)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.contractorId, contractorId) || other.contractorId == contractorId)&&(identical(other.contractorName, contractorName) || other.contractorName == contractorName)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.vatRate, vatRate) || other.vatRate == vatRate)&&(identical(other.isVatIncluded, isVatIncluded) || other.isVatIncluded == isVatIncluded)&&(identical(other.vatAmount, vatAmount) || other.vatAmount == vatAmount)&&(identical(other.advanceAmount, advanceAmount) || other.advanceAmount == advanceAmount)&&(identical(other.warrantyRetentionAmount, warrantyRetentionAmount) || other.warrantyRetentionAmount == warrantyRetentionAmount)&&(identical(other.warrantyRetentionRate, warrantyRetentionRate) || other.warrantyRetentionRate == warrantyRetentionRate)&&(identical(other.warrantyPeriodMonths, warrantyPeriodMonths) || other.warrantyPeriodMonths == warrantyPeriodMonths)&&(identical(other.generalContractorFeeAmount, generalContractorFeeAmount) || other.generalContractorFeeAmount == generalContractorFeeAmount)&&(identical(other.generalContractorFeeRate, generalContractorFeeRate) || other.generalContractorFeeRate == generalContractorFeeRate)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.objectName, objectName) || other.objectName == objectName)&&(identical(other.status, status) || other.status == status)&&(identical(other.contractorOrgName, contractorOrgName) || other.contractorOrgName == contractorOrgName)&&(identical(other.contractorPosition, contractorPosition) || other.contractorPosition == contractorPosition)&&(identical(other.contractorSigner, contractorSigner) || other.contractorSigner == contractorSigner)&&(identical(other.customerOrgName, customerOrgName) || other.customerOrgName == customerOrgName)&&(identical(other.customerPosition, customerPosition) || other.customerPosition == customerPosition)&&(identical(other.customerSigner, customerSigner) || other.customerSigner == customerSigner)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,number,date,endDate,contractorId,contractorName,amount,vatRate,isVatIncluded,vatAmount,advanceAmount,warrantyRetentionAmount,warrantyRetentionRate,warrantyPeriodMonths,generalContractorFeeAmount,generalContractorFeeRate,objectId,objectName,status,contractorOrgName,contractorPosition,contractorSigner,customerOrgName,customerPosition,customerSigner,createdAt,updatedAt]);

@override
String toString() {
  return 'Contract(id: $id, companyId: $companyId, number: $number, date: $date, endDate: $endDate, contractorId: $contractorId, contractorName: $contractorName, amount: $amount, vatRate: $vatRate, isVatIncluded: $isVatIncluded, vatAmount: $vatAmount, advanceAmount: $advanceAmount, warrantyRetentionAmount: $warrantyRetentionAmount, warrantyRetentionRate: $warrantyRetentionRate, warrantyPeriodMonths: $warrantyPeriodMonths, generalContractorFeeAmount: $generalContractorFeeAmount, generalContractorFeeRate: $generalContractorFeeRate, objectId: $objectId, objectName: $objectName, status: $status, contractorOrgName: $contractorOrgName, contractorPosition: $contractorPosition, contractorSigner: $contractorSigner, customerOrgName: $customerOrgName, customerPosition: $customerPosition, customerSigner: $customerSigner, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ContractCopyWith<$Res> implements $ContractCopyWith<$Res> {
  factory _$ContractCopyWith(_Contract value, $Res Function(_Contract) _then) = __$ContractCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String number, DateTime date, DateTime? endDate, String contractorId, String? contractorName, double amount, double vatRate, bool isVatIncluded, double vatAmount, double advanceAmount, double warrantyRetentionAmount, double warrantyRetentionRate, int warrantyPeriodMonths, double generalContractorFeeAmount, double generalContractorFeeRate, String objectId, String? objectName, ContractStatus status, String? contractorOrgName, String? contractorPosition, String? contractorSigner, String? customerOrgName, String? customerPosition, String? customerSigner, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$ContractCopyWithImpl<$Res>
    implements _$ContractCopyWith<$Res> {
  __$ContractCopyWithImpl(this._self, this._then);

  final _Contract _self;
  final $Res Function(_Contract) _then;

/// Create a copy of Contract
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? number = null,Object? date = null,Object? endDate = freezed,Object? contractorId = null,Object? contractorName = freezed,Object? amount = null,Object? vatRate = null,Object? isVatIncluded = null,Object? vatAmount = null,Object? advanceAmount = null,Object? warrantyRetentionAmount = null,Object? warrantyRetentionRate = null,Object? warrantyPeriodMonths = null,Object? generalContractorFeeAmount = null,Object? generalContractorFeeRate = null,Object? objectId = null,Object? objectName = freezed,Object? status = null,Object? contractorOrgName = freezed,Object? contractorPosition = freezed,Object? contractorSigner = freezed,Object? customerOrgName = freezed,Object? customerPosition = freezed,Object? customerSigner = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Contract(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,contractorId: null == contractorId ? _self.contractorId : contractorId // ignore: cast_nullable_to_non_nullable
as String,contractorName: freezed == contractorName ? _self.contractorName : contractorName // ignore: cast_nullable_to_non_nullable
as String?,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,vatRate: null == vatRate ? _self.vatRate : vatRate // ignore: cast_nullable_to_non_nullable
as double,isVatIncluded: null == isVatIncluded ? _self.isVatIncluded : isVatIncluded // ignore: cast_nullable_to_non_nullable
as bool,vatAmount: null == vatAmount ? _self.vatAmount : vatAmount // ignore: cast_nullable_to_non_nullable
as double,advanceAmount: null == advanceAmount ? _self.advanceAmount : advanceAmount // ignore: cast_nullable_to_non_nullable
as double,warrantyRetentionAmount: null == warrantyRetentionAmount ? _self.warrantyRetentionAmount : warrantyRetentionAmount // ignore: cast_nullable_to_non_nullable
as double,warrantyRetentionRate: null == warrantyRetentionRate ? _self.warrantyRetentionRate : warrantyRetentionRate // ignore: cast_nullable_to_non_nullable
as double,warrantyPeriodMonths: null == warrantyPeriodMonths ? _self.warrantyPeriodMonths : warrantyPeriodMonths // ignore: cast_nullable_to_non_nullable
as int,generalContractorFeeAmount: null == generalContractorFeeAmount ? _self.generalContractorFeeAmount : generalContractorFeeAmount // ignore: cast_nullable_to_non_nullable
as double,generalContractorFeeRate: null == generalContractorFeeRate ? _self.generalContractorFeeRate : generalContractorFeeRate // ignore: cast_nullable_to_non_nullable
as double,objectId: null == objectId ? _self.objectId : objectId // ignore: cast_nullable_to_non_nullable
as String,objectName: freezed == objectName ? _self.objectName : objectName // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ContractStatus,contractorOrgName: freezed == contractorOrgName ? _self.contractorOrgName : contractorOrgName // ignore: cast_nullable_to_non_nullable
as String?,contractorPosition: freezed == contractorPosition ? _self.contractorPosition : contractorPosition // ignore: cast_nullable_to_non_nullable
as String?,contractorSigner: freezed == contractorSigner ? _self.contractorSigner : contractorSigner // ignore: cast_nullable_to_non_nullable
as String?,customerOrgName: freezed == customerOrgName ? _self.customerOrgName : customerOrgName // ignore: cast_nullable_to_non_nullable
as String?,customerPosition: freezed == customerPosition ? _self.customerPosition : customerPosition // ignore: cast_nullable_to_non_nullable
as String?,customerSigner: freezed == customerSigner ? _self.customerSigner : customerSigner // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
