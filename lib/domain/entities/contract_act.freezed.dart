// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'contract_act.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ContractAct {

 String get id; String get companyId; String get contractId; ContractActKind get actKind; String get title; String get number; DateTime get actDate; DateTime get periodFrom; DateTime get periodTo; double get amount; double get vatAmount; double get advanceRetention; double get warrantyRetention; double get otherRetentions; double get totalToPay; ContractActAmountSource get amountSource; String? get note; ContractActWorkflowStatus get workflowStatus; ContractActPaymentStatus get paymentStatus; String? get vorId; String? get vorNumber; String? get excelPath; DateTime? get createdAt; DateTime? get updatedAt; String? get createdBy;
/// Create a copy of ContractAct
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContractActCopyWith<ContractAct> get copyWith => _$ContractActCopyWithImpl<ContractAct>(this as ContractAct, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContractAct&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.actKind, actKind) || other.actKind == actKind)&&(identical(other.title, title) || other.title == title)&&(identical(other.number, number) || other.number == number)&&(identical(other.actDate, actDate) || other.actDate == actDate)&&(identical(other.periodFrom, periodFrom) || other.periodFrom == periodFrom)&&(identical(other.periodTo, periodTo) || other.periodTo == periodTo)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.vatAmount, vatAmount) || other.vatAmount == vatAmount)&&(identical(other.advanceRetention, advanceRetention) || other.advanceRetention == advanceRetention)&&(identical(other.warrantyRetention, warrantyRetention) || other.warrantyRetention == warrantyRetention)&&(identical(other.otherRetentions, otherRetentions) || other.otherRetentions == otherRetentions)&&(identical(other.totalToPay, totalToPay) || other.totalToPay == totalToPay)&&(identical(other.amountSource, amountSource) || other.amountSource == amountSource)&&(identical(other.note, note) || other.note == note)&&(identical(other.workflowStatus, workflowStatus) || other.workflowStatus == workflowStatus)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.vorId, vorId) || other.vorId == vorId)&&(identical(other.vorNumber, vorNumber) || other.vorNumber == vorNumber)&&(identical(other.excelPath, excelPath) || other.excelPath == excelPath)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,contractId,actKind,title,number,actDate,periodFrom,periodTo,amount,vatAmount,advanceRetention,warrantyRetention,otherRetentions,totalToPay,amountSource,note,workflowStatus,paymentStatus,vorId,vorNumber,excelPath,createdAt,updatedAt,createdBy]);

@override
String toString() {
  return 'ContractAct(id: $id, companyId: $companyId, contractId: $contractId, actKind: $actKind, title: $title, number: $number, actDate: $actDate, periodFrom: $periodFrom, periodTo: $periodTo, amount: $amount, vatAmount: $vatAmount, advanceRetention: $advanceRetention, warrantyRetention: $warrantyRetention, otherRetentions: $otherRetentions, totalToPay: $totalToPay, amountSource: $amountSource, note: $note, workflowStatus: $workflowStatus, paymentStatus: $paymentStatus, vorId: $vorId, vorNumber: $vorNumber, excelPath: $excelPath, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class $ContractActCopyWith<$Res>  {
  factory $ContractActCopyWith(ContractAct value, $Res Function(ContractAct) _then) = _$ContractActCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String contractId, ContractActKind actKind, String title, String number, DateTime actDate, DateTime periodFrom, DateTime periodTo, double amount, double vatAmount, double advanceRetention, double warrantyRetention, double otherRetentions, double totalToPay, ContractActAmountSource amountSource, String? note, ContractActWorkflowStatus workflowStatus, ContractActPaymentStatus paymentStatus, String? vorId, String? vorNumber, String? excelPath, DateTime? createdAt, DateTime? updatedAt, String? createdBy
});




}
/// @nodoc
class _$ContractActCopyWithImpl<$Res>
    implements $ContractActCopyWith<$Res> {
  _$ContractActCopyWithImpl(this._self, this._then);

  final ContractAct _self;
  final $Res Function(ContractAct) _then;

/// Create a copy of ContractAct
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? contractId = null,Object? actKind = null,Object? title = null,Object? number = null,Object? actDate = null,Object? periodFrom = null,Object? periodTo = null,Object? amount = null,Object? vatAmount = null,Object? advanceRetention = null,Object? warrantyRetention = null,Object? otherRetentions = null,Object? totalToPay = null,Object? amountSource = null,Object? note = freezed,Object? workflowStatus = null,Object? paymentStatus = null,Object? vorId = freezed,Object? vorNumber = freezed,Object? excelPath = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,contractId: null == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String,actKind: null == actKind ? _self.actKind : actKind // ignore: cast_nullable_to_non_nullable
as ContractActKind,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,actDate: null == actDate ? _self.actDate : actDate // ignore: cast_nullable_to_non_nullable
as DateTime,periodFrom: null == periodFrom ? _self.periodFrom : periodFrom // ignore: cast_nullable_to_non_nullable
as DateTime,periodTo: null == periodTo ? _self.periodTo : periodTo // ignore: cast_nullable_to_non_nullable
as DateTime,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,vatAmount: null == vatAmount ? _self.vatAmount : vatAmount // ignore: cast_nullable_to_non_nullable
as double,advanceRetention: null == advanceRetention ? _self.advanceRetention : advanceRetention // ignore: cast_nullable_to_non_nullable
as double,warrantyRetention: null == warrantyRetention ? _self.warrantyRetention : warrantyRetention // ignore: cast_nullable_to_non_nullable
as double,otherRetentions: null == otherRetentions ? _self.otherRetentions : otherRetentions // ignore: cast_nullable_to_non_nullable
as double,totalToPay: null == totalToPay ? _self.totalToPay : totalToPay // ignore: cast_nullable_to_non_nullable
as double,amountSource: null == amountSource ? _self.amountSource : amountSource // ignore: cast_nullable_to_non_nullable
as ContractActAmountSource,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,workflowStatus: null == workflowStatus ? _self.workflowStatus : workflowStatus // ignore: cast_nullable_to_non_nullable
as ContractActWorkflowStatus,paymentStatus: null == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as ContractActPaymentStatus,vorId: freezed == vorId ? _self.vorId : vorId // ignore: cast_nullable_to_non_nullable
as String?,vorNumber: freezed == vorNumber ? _self.vorNumber : vorNumber // ignore: cast_nullable_to_non_nullable
as String?,excelPath: freezed == excelPath ? _self.excelPath : excelPath // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc


class _ContractAct implements ContractAct {
  const _ContractAct({required this.id, required this.companyId, required this.contractId, required this.actKind, required this.title, required this.number, required this.actDate, required this.periodFrom, required this.periodTo, required this.amount, required this.vatAmount, required this.advanceRetention, required this.warrantyRetention, required this.otherRetentions, required this.totalToPay, required this.amountSource, this.note, required this.workflowStatus, required this.paymentStatus, this.vorId, this.vorNumber, this.excelPath, this.createdAt, this.updatedAt, this.createdBy});
  

@override final  String id;
@override final  String companyId;
@override final  String contractId;
@override final  ContractActKind actKind;
@override final  String title;
@override final  String number;
@override final  DateTime actDate;
@override final  DateTime periodFrom;
@override final  DateTime periodTo;
@override final  double amount;
@override final  double vatAmount;
@override final  double advanceRetention;
@override final  double warrantyRetention;
@override final  double otherRetentions;
@override final  double totalToPay;
@override final  ContractActAmountSource amountSource;
@override final  String? note;
@override final  ContractActWorkflowStatus workflowStatus;
@override final  ContractActPaymentStatus paymentStatus;
@override final  String? vorId;
@override final  String? vorNumber;
@override final  String? excelPath;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;
@override final  String? createdBy;

/// Create a copy of ContractAct
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContractActCopyWith<_ContractAct> get copyWith => __$ContractActCopyWithImpl<_ContractAct>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ContractAct&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.actKind, actKind) || other.actKind == actKind)&&(identical(other.title, title) || other.title == title)&&(identical(other.number, number) || other.number == number)&&(identical(other.actDate, actDate) || other.actDate == actDate)&&(identical(other.periodFrom, periodFrom) || other.periodFrom == periodFrom)&&(identical(other.periodTo, periodTo) || other.periodTo == periodTo)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.vatAmount, vatAmount) || other.vatAmount == vatAmount)&&(identical(other.advanceRetention, advanceRetention) || other.advanceRetention == advanceRetention)&&(identical(other.warrantyRetention, warrantyRetention) || other.warrantyRetention == warrantyRetention)&&(identical(other.otherRetentions, otherRetentions) || other.otherRetentions == otherRetentions)&&(identical(other.totalToPay, totalToPay) || other.totalToPay == totalToPay)&&(identical(other.amountSource, amountSource) || other.amountSource == amountSource)&&(identical(other.note, note) || other.note == note)&&(identical(other.workflowStatus, workflowStatus) || other.workflowStatus == workflowStatus)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.vorId, vorId) || other.vorId == vorId)&&(identical(other.vorNumber, vorNumber) || other.vorNumber == vorNumber)&&(identical(other.excelPath, excelPath) || other.excelPath == excelPath)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,contractId,actKind,title,number,actDate,periodFrom,periodTo,amount,vatAmount,advanceRetention,warrantyRetention,otherRetentions,totalToPay,amountSource,note,workflowStatus,paymentStatus,vorId,vorNumber,excelPath,createdAt,updatedAt,createdBy]);

@override
String toString() {
  return 'ContractAct(id: $id, companyId: $companyId, contractId: $contractId, actKind: $actKind, title: $title, number: $number, actDate: $actDate, periodFrom: $periodFrom, periodTo: $periodTo, amount: $amount, vatAmount: $vatAmount, advanceRetention: $advanceRetention, warrantyRetention: $warrantyRetention, otherRetentions: $otherRetentions, totalToPay: $totalToPay, amountSource: $amountSource, note: $note, workflowStatus: $workflowStatus, paymentStatus: $paymentStatus, vorId: $vorId, vorNumber: $vorNumber, excelPath: $excelPath, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class _$ContractActCopyWith<$Res> implements $ContractActCopyWith<$Res> {
  factory _$ContractActCopyWith(_ContractAct value, $Res Function(_ContractAct) _then) = __$ContractActCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String contractId, ContractActKind actKind, String title, String number, DateTime actDate, DateTime periodFrom, DateTime periodTo, double amount, double vatAmount, double advanceRetention, double warrantyRetention, double otherRetentions, double totalToPay, ContractActAmountSource amountSource, String? note, ContractActWorkflowStatus workflowStatus, ContractActPaymentStatus paymentStatus, String? vorId, String? vorNumber, String? excelPath, DateTime? createdAt, DateTime? updatedAt, String? createdBy
});




}
/// @nodoc
class __$ContractActCopyWithImpl<$Res>
    implements _$ContractActCopyWith<$Res> {
  __$ContractActCopyWithImpl(this._self, this._then);

  final _ContractAct _self;
  final $Res Function(_ContractAct) _then;

/// Create a copy of ContractAct
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? contractId = null,Object? actKind = null,Object? title = null,Object? number = null,Object? actDate = null,Object? periodFrom = null,Object? periodTo = null,Object? amount = null,Object? vatAmount = null,Object? advanceRetention = null,Object? warrantyRetention = null,Object? otherRetentions = null,Object? totalToPay = null,Object? amountSource = null,Object? note = freezed,Object? workflowStatus = null,Object? paymentStatus = null,Object? vorId = freezed,Object? vorNumber = freezed,Object? excelPath = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,}) {
  return _then(_ContractAct(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,contractId: null == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String,actKind: null == actKind ? _self.actKind : actKind // ignore: cast_nullable_to_non_nullable
as ContractActKind,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,actDate: null == actDate ? _self.actDate : actDate // ignore: cast_nullable_to_non_nullable
as DateTime,periodFrom: null == periodFrom ? _self.periodFrom : periodFrom // ignore: cast_nullable_to_non_nullable
as DateTime,periodTo: null == periodTo ? _self.periodTo : periodTo // ignore: cast_nullable_to_non_nullable
as DateTime,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,vatAmount: null == vatAmount ? _self.vatAmount : vatAmount // ignore: cast_nullable_to_non_nullable
as double,advanceRetention: null == advanceRetention ? _self.advanceRetention : advanceRetention // ignore: cast_nullable_to_non_nullable
as double,warrantyRetention: null == warrantyRetention ? _self.warrantyRetention : warrantyRetention // ignore: cast_nullable_to_non_nullable
as double,otherRetentions: null == otherRetentions ? _self.otherRetentions : otherRetentions // ignore: cast_nullable_to_non_nullable
as double,totalToPay: null == totalToPay ? _self.totalToPay : totalToPay // ignore: cast_nullable_to_non_nullable
as double,amountSource: null == amountSource ? _self.amountSource : amountSource // ignore: cast_nullable_to_non_nullable
as ContractActAmountSource,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,workflowStatus: null == workflowStatus ? _self.workflowStatus : workflowStatus // ignore: cast_nullable_to_non_nullable
as ContractActWorkflowStatus,paymentStatus: null == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as ContractActPaymentStatus,vorId: freezed == vorId ? _self.vorId : vorId // ignore: cast_nullable_to_non_nullable
as String?,vorNumber: freezed == vorNumber ? _self.vorNumber : vorNumber // ignore: cast_nullable_to_non_nullable
as String?,excelPath: freezed == excelPath ? _self.excelPath : excelPath // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
