// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'contract_act_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ContractActModel {

 String get id;@JsonKey(name: 'company_id') String get companyId;@JsonKey(name: 'contract_id') String get contractId;@JsonKey(name: 'act_kind') String get actKind; String get title; String get number;@JsonKey(name: 'act_date') DateTime get actDate;@JsonKey(name: 'period_from') DateTime get periodFrom;@JsonKey(name: 'period_to') DateTime get periodTo; double get amount;@JsonKey(name: 'vat_amount') double get vatAmount;@JsonKey(name: 'advance_retention') double get advanceRetention;@JsonKey(name: 'warranty_retention') double get warrantyRetention;@JsonKey(name: 'other_retentions') double get otherRetentions;@JsonKey(name: 'total_to_pay') double get totalToPay;@JsonKey(name: 'amount_source') String get amountSource; String? get note;@JsonKey(name: 'workflow_status') String get workflowStatus;@JsonKey(name: 'payment_status') String get paymentStatus;@JsonKey(name: 'vor_id') String? get vorId;@JsonKey(name: 'excel_path') String? get excelPath;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;@JsonKey(name: 'created_by') String? get createdBy;@JsonKey(includeFromJson: false, includeToJson: false) String? get vorNumber;
/// Create a copy of ContractActModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContractActModelCopyWith<ContractActModel> get copyWith => _$ContractActModelCopyWithImpl<ContractActModel>(this as ContractActModel, _$identity);

  /// Serializes this ContractActModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContractActModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.actKind, actKind) || other.actKind == actKind)&&(identical(other.title, title) || other.title == title)&&(identical(other.number, number) || other.number == number)&&(identical(other.actDate, actDate) || other.actDate == actDate)&&(identical(other.periodFrom, periodFrom) || other.periodFrom == periodFrom)&&(identical(other.periodTo, periodTo) || other.periodTo == periodTo)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.vatAmount, vatAmount) || other.vatAmount == vatAmount)&&(identical(other.advanceRetention, advanceRetention) || other.advanceRetention == advanceRetention)&&(identical(other.warrantyRetention, warrantyRetention) || other.warrantyRetention == warrantyRetention)&&(identical(other.otherRetentions, otherRetentions) || other.otherRetentions == otherRetentions)&&(identical(other.totalToPay, totalToPay) || other.totalToPay == totalToPay)&&(identical(other.amountSource, amountSource) || other.amountSource == amountSource)&&(identical(other.note, note) || other.note == note)&&(identical(other.workflowStatus, workflowStatus) || other.workflowStatus == workflowStatus)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.vorId, vorId) || other.vorId == vorId)&&(identical(other.excelPath, excelPath) || other.excelPath == excelPath)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.vorNumber, vorNumber) || other.vorNumber == vorNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,contractId,actKind,title,number,actDate,periodFrom,periodTo,amount,vatAmount,advanceRetention,warrantyRetention,otherRetentions,totalToPay,amountSource,note,workflowStatus,paymentStatus,vorId,excelPath,createdAt,updatedAt,createdBy,vorNumber]);

@override
String toString() {
  return 'ContractActModel(id: $id, companyId: $companyId, contractId: $contractId, actKind: $actKind, title: $title, number: $number, actDate: $actDate, periodFrom: $periodFrom, periodTo: $periodTo, amount: $amount, vatAmount: $vatAmount, advanceRetention: $advanceRetention, warrantyRetention: $warrantyRetention, otherRetentions: $otherRetentions, totalToPay: $totalToPay, amountSource: $amountSource, note: $note, workflowStatus: $workflowStatus, paymentStatus: $paymentStatus, vorId: $vorId, excelPath: $excelPath, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, vorNumber: $vorNumber)';
}


}

/// @nodoc
abstract mixin class $ContractActModelCopyWith<$Res>  {
  factory $ContractActModelCopyWith(ContractActModel value, $Res Function(ContractActModel) _then) = _$ContractActModelCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'company_id') String companyId,@JsonKey(name: 'contract_id') String contractId,@JsonKey(name: 'act_kind') String actKind, String title, String number,@JsonKey(name: 'act_date') DateTime actDate,@JsonKey(name: 'period_from') DateTime periodFrom,@JsonKey(name: 'period_to') DateTime periodTo, double amount,@JsonKey(name: 'vat_amount') double vatAmount,@JsonKey(name: 'advance_retention') double advanceRetention,@JsonKey(name: 'warranty_retention') double warrantyRetention,@JsonKey(name: 'other_retentions') double otherRetentions,@JsonKey(name: 'total_to_pay') double totalToPay,@JsonKey(name: 'amount_source') String amountSource, String? note,@JsonKey(name: 'workflow_status') String workflowStatus,@JsonKey(name: 'payment_status') String paymentStatus,@JsonKey(name: 'vor_id') String? vorId,@JsonKey(name: 'excel_path') String? excelPath,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt,@JsonKey(name: 'created_by') String? createdBy,@JsonKey(includeFromJson: false, includeToJson: false) String? vorNumber
});




}
/// @nodoc
class _$ContractActModelCopyWithImpl<$Res>
    implements $ContractActModelCopyWith<$Res> {
  _$ContractActModelCopyWithImpl(this._self, this._then);

  final ContractActModel _self;
  final $Res Function(ContractActModel) _then;

/// Create a copy of ContractActModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? contractId = null,Object? actKind = null,Object? title = null,Object? number = null,Object? actDate = null,Object? periodFrom = null,Object? periodTo = null,Object? amount = null,Object? vatAmount = null,Object? advanceRetention = null,Object? warrantyRetention = null,Object? otherRetentions = null,Object? totalToPay = null,Object? amountSource = null,Object? note = freezed,Object? workflowStatus = null,Object? paymentStatus = null,Object? vorId = freezed,Object? excelPath = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,Object? vorNumber = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,contractId: null == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String,actKind: null == actKind ? _self.actKind : actKind // ignore: cast_nullable_to_non_nullable
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
as double,amountSource: null == amountSource ? _self.amountSource : amountSource // ignore: cast_nullable_to_non_nullable
as String,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,workflowStatus: null == workflowStatus ? _self.workflowStatus : workflowStatus // ignore: cast_nullable_to_non_nullable
as String,paymentStatus: null == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as String,vorId: freezed == vorId ? _self.vorId : vorId // ignore: cast_nullable_to_non_nullable
as String?,excelPath: freezed == excelPath ? _self.excelPath : excelPath // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,vorNumber: freezed == vorNumber ? _self.vorNumber : vorNumber // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _ContractActModel extends ContractActModel {
  const _ContractActModel({required this.id, @JsonKey(name: 'company_id') required this.companyId, @JsonKey(name: 'contract_id') required this.contractId, @JsonKey(name: 'act_kind') this.actKind = 'manual', required this.title, required this.number, @JsonKey(name: 'act_date') required this.actDate, @JsonKey(name: 'period_from') required this.periodFrom, @JsonKey(name: 'period_to') required this.periodTo, required this.amount, @JsonKey(name: 'vat_amount') required this.vatAmount, @JsonKey(name: 'advance_retention') required this.advanceRetention, @JsonKey(name: 'warranty_retention') required this.warrantyRetention, @JsonKey(name: 'other_retentions') required this.otherRetentions, @JsonKey(name: 'total_to_pay') required this.totalToPay, @JsonKey(name: 'amount_source') this.amountSource = 'manual', this.note, @JsonKey(name: 'workflow_status') required this.workflowStatus, @JsonKey(name: 'payment_status') required this.paymentStatus, @JsonKey(name: 'vor_id') this.vorId, @JsonKey(name: 'excel_path') this.excelPath, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt, @JsonKey(name: 'created_by') this.createdBy, @JsonKey(includeFromJson: false, includeToJson: false) this.vorNumber}): super._();
  factory _ContractActModel.fromJson(Map<String, dynamic> json) => _$ContractActModelFromJson(json);

@override final  String id;
@override@JsonKey(name: 'company_id') final  String companyId;
@override@JsonKey(name: 'contract_id') final  String contractId;
@override@JsonKey(name: 'act_kind') final  String actKind;
@override final  String title;
@override final  String number;
@override@JsonKey(name: 'act_date') final  DateTime actDate;
@override@JsonKey(name: 'period_from') final  DateTime periodFrom;
@override@JsonKey(name: 'period_to') final  DateTime periodTo;
@override final  double amount;
@override@JsonKey(name: 'vat_amount') final  double vatAmount;
@override@JsonKey(name: 'advance_retention') final  double advanceRetention;
@override@JsonKey(name: 'warranty_retention') final  double warrantyRetention;
@override@JsonKey(name: 'other_retentions') final  double otherRetentions;
@override@JsonKey(name: 'total_to_pay') final  double totalToPay;
@override@JsonKey(name: 'amount_source') final  String amountSource;
@override final  String? note;
@override@JsonKey(name: 'workflow_status') final  String workflowStatus;
@override@JsonKey(name: 'payment_status') final  String paymentStatus;
@override@JsonKey(name: 'vor_id') final  String? vorId;
@override@JsonKey(name: 'excel_path') final  String? excelPath;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;
@override@JsonKey(name: 'created_by') final  String? createdBy;
@override@JsonKey(includeFromJson: false, includeToJson: false) final  String? vorNumber;

/// Create a copy of ContractActModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContractActModelCopyWith<_ContractActModel> get copyWith => __$ContractActModelCopyWithImpl<_ContractActModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ContractActModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ContractActModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.actKind, actKind) || other.actKind == actKind)&&(identical(other.title, title) || other.title == title)&&(identical(other.number, number) || other.number == number)&&(identical(other.actDate, actDate) || other.actDate == actDate)&&(identical(other.periodFrom, periodFrom) || other.periodFrom == periodFrom)&&(identical(other.periodTo, periodTo) || other.periodTo == periodTo)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.vatAmount, vatAmount) || other.vatAmount == vatAmount)&&(identical(other.advanceRetention, advanceRetention) || other.advanceRetention == advanceRetention)&&(identical(other.warrantyRetention, warrantyRetention) || other.warrantyRetention == warrantyRetention)&&(identical(other.otherRetentions, otherRetentions) || other.otherRetentions == otherRetentions)&&(identical(other.totalToPay, totalToPay) || other.totalToPay == totalToPay)&&(identical(other.amountSource, amountSource) || other.amountSource == amountSource)&&(identical(other.note, note) || other.note == note)&&(identical(other.workflowStatus, workflowStatus) || other.workflowStatus == workflowStatus)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.vorId, vorId) || other.vorId == vorId)&&(identical(other.excelPath, excelPath) || other.excelPath == excelPath)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.vorNumber, vorNumber) || other.vorNumber == vorNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,contractId,actKind,title,number,actDate,periodFrom,periodTo,amount,vatAmount,advanceRetention,warrantyRetention,otherRetentions,totalToPay,amountSource,note,workflowStatus,paymentStatus,vorId,excelPath,createdAt,updatedAt,createdBy,vorNumber]);

@override
String toString() {
  return 'ContractActModel(id: $id, companyId: $companyId, contractId: $contractId, actKind: $actKind, title: $title, number: $number, actDate: $actDate, periodFrom: $periodFrom, periodTo: $periodTo, amount: $amount, vatAmount: $vatAmount, advanceRetention: $advanceRetention, warrantyRetention: $warrantyRetention, otherRetentions: $otherRetentions, totalToPay: $totalToPay, amountSource: $amountSource, note: $note, workflowStatus: $workflowStatus, paymentStatus: $paymentStatus, vorId: $vorId, excelPath: $excelPath, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, vorNumber: $vorNumber)';
}


}

/// @nodoc
abstract mixin class _$ContractActModelCopyWith<$Res> implements $ContractActModelCopyWith<$Res> {
  factory _$ContractActModelCopyWith(_ContractActModel value, $Res Function(_ContractActModel) _then) = __$ContractActModelCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'company_id') String companyId,@JsonKey(name: 'contract_id') String contractId,@JsonKey(name: 'act_kind') String actKind, String title, String number,@JsonKey(name: 'act_date') DateTime actDate,@JsonKey(name: 'period_from') DateTime periodFrom,@JsonKey(name: 'period_to') DateTime periodTo, double amount,@JsonKey(name: 'vat_amount') double vatAmount,@JsonKey(name: 'advance_retention') double advanceRetention,@JsonKey(name: 'warranty_retention') double warrantyRetention,@JsonKey(name: 'other_retentions') double otherRetentions,@JsonKey(name: 'total_to_pay') double totalToPay,@JsonKey(name: 'amount_source') String amountSource, String? note,@JsonKey(name: 'workflow_status') String workflowStatus,@JsonKey(name: 'payment_status') String paymentStatus,@JsonKey(name: 'vor_id') String? vorId,@JsonKey(name: 'excel_path') String? excelPath,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt,@JsonKey(name: 'created_by') String? createdBy,@JsonKey(includeFromJson: false, includeToJson: false) String? vorNumber
});




}
/// @nodoc
class __$ContractActModelCopyWithImpl<$Res>
    implements _$ContractActModelCopyWith<$Res> {
  __$ContractActModelCopyWithImpl(this._self, this._then);

  final _ContractActModel _self;
  final $Res Function(_ContractActModel) _then;

/// Create a copy of ContractActModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? contractId = null,Object? actKind = null,Object? title = null,Object? number = null,Object? actDate = null,Object? periodFrom = null,Object? periodTo = null,Object? amount = null,Object? vatAmount = null,Object? advanceRetention = null,Object? warrantyRetention = null,Object? otherRetentions = null,Object? totalToPay = null,Object? amountSource = null,Object? note = freezed,Object? workflowStatus = null,Object? paymentStatus = null,Object? vorId = freezed,Object? excelPath = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,Object? vorNumber = freezed,}) {
  return _then(_ContractActModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,contractId: null == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String,actKind: null == actKind ? _self.actKind : actKind // ignore: cast_nullable_to_non_nullable
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
as double,amountSource: null == amountSource ? _self.amountSource : amountSource // ignore: cast_nullable_to_non_nullable
as String,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,workflowStatus: null == workflowStatus ? _self.workflowStatus : workflowStatus // ignore: cast_nullable_to_non_nullable
as String,paymentStatus: null == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as String,vorId: freezed == vorId ? _self.vorId : vorId // ignore: cast_nullable_to_non_nullable
as String?,excelPath: freezed == excelPath ? _self.excelPath : excelPath // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,vorNumber: freezed == vorNumber ? _self.vorNumber : vorNumber // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
