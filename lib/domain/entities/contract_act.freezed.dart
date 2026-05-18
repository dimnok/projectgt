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

 String get id; String get companyId; String get contractId; String get title; String get number; DateTime get actDate; DateTime get periodFrom; DateTime get periodTo; double get amount; double get vatAmount; double get advanceRetention; double get warrantyRetention; double get otherRetentions; double get totalToPay; String? get note; ContractActWorkflowStatus get workflowStatus; ContractActPaymentStatus get paymentStatus; DateTime? get createdAt; DateTime? get updatedAt; String? get createdBy;
/// Create a copy of ContractAct
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContractActCopyWith<ContractAct> get copyWith => _$ContractActCopyWithImpl<ContractAct>(this as ContractAct, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContractAct&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.title, title) || other.title == title)&&(identical(other.number, number) || other.number == number)&&(identical(other.actDate, actDate) || other.actDate == actDate)&&(identical(other.periodFrom, periodFrom) || other.periodFrom == periodFrom)&&(identical(other.periodTo, periodTo) || other.periodTo == periodTo)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.vatAmount, vatAmount) || other.vatAmount == vatAmount)&&(identical(other.advanceRetention, advanceRetention) || other.advanceRetention == advanceRetention)&&(identical(other.warrantyRetention, warrantyRetention) || other.warrantyRetention == warrantyRetention)&&(identical(other.otherRetentions, otherRetentions) || other.otherRetentions == otherRetentions)&&(identical(other.totalToPay, totalToPay) || other.totalToPay == totalToPay)&&(identical(other.note, note) || other.note == note)&&(identical(other.workflowStatus, workflowStatus) || other.workflowStatus == workflowStatus)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,contractId,title,number,actDate,periodFrom,periodTo,amount,vatAmount,advanceRetention,warrantyRetention,otherRetentions,totalToPay,note,workflowStatus,paymentStatus,createdAt,updatedAt,createdBy]);

@override
String toString() {
  return 'ContractAct(id: $id, companyId: $companyId, contractId: $contractId, title: $title, number: $number, actDate: $actDate, periodFrom: $periodFrom, periodTo: $periodTo, amount: $amount, vatAmount: $vatAmount, advanceRetention: $advanceRetention, warrantyRetention: $warrantyRetention, otherRetentions: $otherRetentions, totalToPay: $totalToPay, note: $note, workflowStatus: $workflowStatus, paymentStatus: $paymentStatus, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class $ContractActCopyWith<$Res>  {
  factory $ContractActCopyWith(ContractAct value, $Res Function(ContractAct) _then) = _$ContractActCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String contractId, String title, String number, DateTime actDate, DateTime periodFrom, DateTime periodTo, double amount, double vatAmount, double advanceRetention, double warrantyRetention, double otherRetentions, double totalToPay, String? note, ContractActWorkflowStatus workflowStatus, ContractActPaymentStatus paymentStatus, DateTime? createdAt, DateTime? updatedAt, String? createdBy
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? contractId = null,Object? title = null,Object? number = null,Object? actDate = null,Object? periodFrom = null,Object? periodTo = null,Object? amount = null,Object? vatAmount = null,Object? advanceRetention = null,Object? warrantyRetention = null,Object? otherRetentions = null,Object? totalToPay = null,Object? note = freezed,Object? workflowStatus = null,Object? paymentStatus = null,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,contractId: null == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
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
as double,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,workflowStatus: null == workflowStatus ? _self.workflowStatus : workflowStatus // ignore: cast_nullable_to_non_nullable
as ContractActWorkflowStatus,paymentStatus: null == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as ContractActPaymentStatus,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc


class _ContractAct implements ContractAct {
  const _ContractAct({required this.id, required this.companyId, required this.contractId, required this.title, required this.number, required this.actDate, required this.periodFrom, required this.periodTo, required this.amount, required this.vatAmount, required this.advanceRetention, required this.warrantyRetention, required this.otherRetentions, required this.totalToPay, this.note, required this.workflowStatus, required this.paymentStatus, this.createdAt, this.updatedAt, this.createdBy});
  

@override final  String id;
@override final  String companyId;
@override final  String contractId;
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
@override final  String? note;
@override final  ContractActWorkflowStatus workflowStatus;
@override final  ContractActPaymentStatus paymentStatus;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ContractAct&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.title, title) || other.title == title)&&(identical(other.number, number) || other.number == number)&&(identical(other.actDate, actDate) || other.actDate == actDate)&&(identical(other.periodFrom, periodFrom) || other.periodFrom == periodFrom)&&(identical(other.periodTo, periodTo) || other.periodTo == periodTo)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.vatAmount, vatAmount) || other.vatAmount == vatAmount)&&(identical(other.advanceRetention, advanceRetention) || other.advanceRetention == advanceRetention)&&(identical(other.warrantyRetention, warrantyRetention) || other.warrantyRetention == warrantyRetention)&&(identical(other.otherRetentions, otherRetentions) || other.otherRetentions == otherRetentions)&&(identical(other.totalToPay, totalToPay) || other.totalToPay == totalToPay)&&(identical(other.note, note) || other.note == note)&&(identical(other.workflowStatus, workflowStatus) || other.workflowStatus == workflowStatus)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,contractId,title,number,actDate,periodFrom,periodTo,amount,vatAmount,advanceRetention,warrantyRetention,otherRetentions,totalToPay,note,workflowStatus,paymentStatus,createdAt,updatedAt,createdBy]);

@override
String toString() {
  return 'ContractAct(id: $id, companyId: $companyId, contractId: $contractId, title: $title, number: $number, actDate: $actDate, periodFrom: $periodFrom, periodTo: $periodTo, amount: $amount, vatAmount: $vatAmount, advanceRetention: $advanceRetention, warrantyRetention: $warrantyRetention, otherRetentions: $otherRetentions, totalToPay: $totalToPay, note: $note, workflowStatus: $workflowStatus, paymentStatus: $paymentStatus, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class _$ContractActCopyWith<$Res> implements $ContractActCopyWith<$Res> {
  factory _$ContractActCopyWith(_ContractAct value, $Res Function(_ContractAct) _then) = __$ContractActCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String contractId, String title, String number, DateTime actDate, DateTime periodFrom, DateTime periodTo, double amount, double vatAmount, double advanceRetention, double warrantyRetention, double otherRetentions, double totalToPay, String? note, ContractActWorkflowStatus workflowStatus, ContractActPaymentStatus paymentStatus, DateTime? createdAt, DateTime? updatedAt, String? createdBy
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? contractId = null,Object? title = null,Object? number = null,Object? actDate = null,Object? periodFrom = null,Object? periodTo = null,Object? amount = null,Object? vatAmount = null,Object? advanceRetention = null,Object? warrantyRetention = null,Object? otherRetentions = null,Object? totalToPay = null,Object? note = freezed,Object? workflowStatus = null,Object? paymentStatus = null,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,}) {
  return _then(_ContractAct(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,contractId: null == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
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
as double,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,workflowStatus: null == workflowStatus ? _self.workflowStatus : workflowStatus // ignore: cast_nullable_to_non_nullable
as ContractActWorkflowStatus,paymentStatus: null == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as ContractActPaymentStatus,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
