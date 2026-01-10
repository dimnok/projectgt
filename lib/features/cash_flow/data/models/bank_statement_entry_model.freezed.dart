// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bank_statement_entry_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BankStatementEntryModel {

 String get id;@JsonKey(name: 'company_id') String get companyId;@JsonKey(name: 'bank_account_id') String get bankAccountId; DateTime get date; double get amount; String get type;@JsonKey(name: 'contractor_name') String? get contractorName;@JsonKey(name: 'contractor_inn') String? get contractorInn; String? get comment;@JsonKey(name: 'transaction_number') String? get transactionNumber;@JsonKey(name: 'is_imported') bool get isImported;@JsonKey(name: 'linked_transaction_id') String? get linkedTransactionId;@JsonKey(name: 'operation_hash') String? get operationHash;
/// Create a copy of BankStatementEntryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BankStatementEntryModelCopyWith<BankStatementEntryModel> get copyWith => _$BankStatementEntryModelCopyWithImpl<BankStatementEntryModel>(this as BankStatementEntryModel, _$identity);

  /// Serializes this BankStatementEntryModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BankStatementEntryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.bankAccountId, bankAccountId) || other.bankAccountId == bankAccountId)&&(identical(other.date, date) || other.date == date)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.type, type) || other.type == type)&&(identical(other.contractorName, contractorName) || other.contractorName == contractorName)&&(identical(other.contractorInn, contractorInn) || other.contractorInn == contractorInn)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.transactionNumber, transactionNumber) || other.transactionNumber == transactionNumber)&&(identical(other.isImported, isImported) || other.isImported == isImported)&&(identical(other.linkedTransactionId, linkedTransactionId) || other.linkedTransactionId == linkedTransactionId)&&(identical(other.operationHash, operationHash) || other.operationHash == operationHash));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,bankAccountId,date,amount,type,contractorName,contractorInn,comment,transactionNumber,isImported,linkedTransactionId,operationHash);

@override
String toString() {
  return 'BankStatementEntryModel(id: $id, companyId: $companyId, bankAccountId: $bankAccountId, date: $date, amount: $amount, type: $type, contractorName: $contractorName, contractorInn: $contractorInn, comment: $comment, transactionNumber: $transactionNumber, isImported: $isImported, linkedTransactionId: $linkedTransactionId, operationHash: $operationHash)';
}


}

/// @nodoc
abstract mixin class $BankStatementEntryModelCopyWith<$Res>  {
  factory $BankStatementEntryModelCopyWith(BankStatementEntryModel value, $Res Function(BankStatementEntryModel) _then) = _$BankStatementEntryModelCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'company_id') String companyId,@JsonKey(name: 'bank_account_id') String bankAccountId, DateTime date, double amount, String type,@JsonKey(name: 'contractor_name') String? contractorName,@JsonKey(name: 'contractor_inn') String? contractorInn, String? comment,@JsonKey(name: 'transaction_number') String? transactionNumber,@JsonKey(name: 'is_imported') bool isImported,@JsonKey(name: 'linked_transaction_id') String? linkedTransactionId,@JsonKey(name: 'operation_hash') String? operationHash
});




}
/// @nodoc
class _$BankStatementEntryModelCopyWithImpl<$Res>
    implements $BankStatementEntryModelCopyWith<$Res> {
  _$BankStatementEntryModelCopyWithImpl(this._self, this._then);

  final BankStatementEntryModel _self;
  final $Res Function(BankStatementEntryModel) _then;

/// Create a copy of BankStatementEntryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? bankAccountId = null,Object? date = null,Object? amount = null,Object? type = null,Object? contractorName = freezed,Object? contractorInn = freezed,Object? comment = freezed,Object? transactionNumber = freezed,Object? isImported = null,Object? linkedTransactionId = freezed,Object? operationHash = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,bankAccountId: null == bankAccountId ? _self.bankAccountId : bankAccountId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,contractorName: freezed == contractorName ? _self.contractorName : contractorName // ignore: cast_nullable_to_non_nullable
as String?,contractorInn: freezed == contractorInn ? _self.contractorInn : contractorInn // ignore: cast_nullable_to_non_nullable
as String?,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,transactionNumber: freezed == transactionNumber ? _self.transactionNumber : transactionNumber // ignore: cast_nullable_to_non_nullable
as String?,isImported: null == isImported ? _self.isImported : isImported // ignore: cast_nullable_to_non_nullable
as bool,linkedTransactionId: freezed == linkedTransactionId ? _self.linkedTransactionId : linkedTransactionId // ignore: cast_nullable_to_non_nullable
as String?,operationHash: freezed == operationHash ? _self.operationHash : operationHash // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _BankStatementEntryModel extends BankStatementEntryModel {
  const _BankStatementEntryModel({required this.id, @JsonKey(name: 'company_id') required this.companyId, @JsonKey(name: 'bank_account_id') required this.bankAccountId, required this.date, required this.amount, required this.type, @JsonKey(name: 'contractor_name') this.contractorName, @JsonKey(name: 'contractor_inn') this.contractorInn, this.comment, @JsonKey(name: 'transaction_number') this.transactionNumber, @JsonKey(name: 'is_imported') this.isImported = false, @JsonKey(name: 'linked_transaction_id') this.linkedTransactionId, @JsonKey(name: 'operation_hash') this.operationHash}): super._();
  factory _BankStatementEntryModel.fromJson(Map<String, dynamic> json) => _$BankStatementEntryModelFromJson(json);

@override final  String id;
@override@JsonKey(name: 'company_id') final  String companyId;
@override@JsonKey(name: 'bank_account_id') final  String bankAccountId;
@override final  DateTime date;
@override final  double amount;
@override final  String type;
@override@JsonKey(name: 'contractor_name') final  String? contractorName;
@override@JsonKey(name: 'contractor_inn') final  String? contractorInn;
@override final  String? comment;
@override@JsonKey(name: 'transaction_number') final  String? transactionNumber;
@override@JsonKey(name: 'is_imported') final  bool isImported;
@override@JsonKey(name: 'linked_transaction_id') final  String? linkedTransactionId;
@override@JsonKey(name: 'operation_hash') final  String? operationHash;

/// Create a copy of BankStatementEntryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BankStatementEntryModelCopyWith<_BankStatementEntryModel> get copyWith => __$BankStatementEntryModelCopyWithImpl<_BankStatementEntryModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BankStatementEntryModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BankStatementEntryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.bankAccountId, bankAccountId) || other.bankAccountId == bankAccountId)&&(identical(other.date, date) || other.date == date)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.type, type) || other.type == type)&&(identical(other.contractorName, contractorName) || other.contractorName == contractorName)&&(identical(other.contractorInn, contractorInn) || other.contractorInn == contractorInn)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.transactionNumber, transactionNumber) || other.transactionNumber == transactionNumber)&&(identical(other.isImported, isImported) || other.isImported == isImported)&&(identical(other.linkedTransactionId, linkedTransactionId) || other.linkedTransactionId == linkedTransactionId)&&(identical(other.operationHash, operationHash) || other.operationHash == operationHash));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,bankAccountId,date,amount,type,contractorName,contractorInn,comment,transactionNumber,isImported,linkedTransactionId,operationHash);

@override
String toString() {
  return 'BankStatementEntryModel(id: $id, companyId: $companyId, bankAccountId: $bankAccountId, date: $date, amount: $amount, type: $type, contractorName: $contractorName, contractorInn: $contractorInn, comment: $comment, transactionNumber: $transactionNumber, isImported: $isImported, linkedTransactionId: $linkedTransactionId, operationHash: $operationHash)';
}


}

/// @nodoc
abstract mixin class _$BankStatementEntryModelCopyWith<$Res> implements $BankStatementEntryModelCopyWith<$Res> {
  factory _$BankStatementEntryModelCopyWith(_BankStatementEntryModel value, $Res Function(_BankStatementEntryModel) _then) = __$BankStatementEntryModelCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'company_id') String companyId,@JsonKey(name: 'bank_account_id') String bankAccountId, DateTime date, double amount, String type,@JsonKey(name: 'contractor_name') String? contractorName,@JsonKey(name: 'contractor_inn') String? contractorInn, String? comment,@JsonKey(name: 'transaction_number') String? transactionNumber,@JsonKey(name: 'is_imported') bool isImported,@JsonKey(name: 'linked_transaction_id') String? linkedTransactionId,@JsonKey(name: 'operation_hash') String? operationHash
});




}
/// @nodoc
class __$BankStatementEntryModelCopyWithImpl<$Res>
    implements _$BankStatementEntryModelCopyWith<$Res> {
  __$BankStatementEntryModelCopyWithImpl(this._self, this._then);

  final _BankStatementEntryModel _self;
  final $Res Function(_BankStatementEntryModel) _then;

/// Create a copy of BankStatementEntryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? bankAccountId = null,Object? date = null,Object? amount = null,Object? type = null,Object? contractorName = freezed,Object? contractorInn = freezed,Object? comment = freezed,Object? transactionNumber = freezed,Object? isImported = null,Object? linkedTransactionId = freezed,Object? operationHash = freezed,}) {
  return _then(_BankStatementEntryModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,bankAccountId: null == bankAccountId ? _self.bankAccountId : bankAccountId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,contractorName: freezed == contractorName ? _self.contractorName : contractorName // ignore: cast_nullable_to_non_nullable
as String?,contractorInn: freezed == contractorInn ? _self.contractorInn : contractorInn // ignore: cast_nullable_to_non_nullable
as String?,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,transactionNumber: freezed == transactionNumber ? _self.transactionNumber : transactionNumber // ignore: cast_nullable_to_non_nullable
as String?,isImported: null == isImported ? _self.isImported : isImported // ignore: cast_nullable_to_non_nullable
as bool,linkedTransactionId: freezed == linkedTransactionId ? _self.linkedTransactionId : linkedTransactionId // ignore: cast_nullable_to_non_nullable
as String?,operationHash: freezed == operationHash ? _self.operationHash : operationHash // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
