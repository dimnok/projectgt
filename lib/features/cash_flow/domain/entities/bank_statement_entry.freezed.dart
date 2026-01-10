// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bank_statement_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BankStatementEntry {

/// Уникальный ID записи.
 String get id;/// ID компании.
 String get companyId;/// ID банковского счета.
 String get bankAccountId;/// Дата операции из выписки.
 DateTime get date;/// Сумма операции.
 double get amount;/// Тип операции (приход/расход).
 CashFlowType get type;/// Название контрагента из выписки.
 String? get contractorName;/// ИНН контрагента из выписки.
 String? get contractorInn;/// Комментарий/назначение платежа.
 String? get comment;/// Номер транзакции в банке.
 String? get transactionNumber;/// Статус импорта (уже создана ли транзакция в системе).
 bool get isImported;/// ID связанной транзакции (если уже импортировано).
 String? get linkedTransactionId;/// Уникальный хеш операции для дедупликации.
 String? get operationHash;
/// Create a copy of BankStatementEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BankStatementEntryCopyWith<BankStatementEntry> get copyWith => _$BankStatementEntryCopyWithImpl<BankStatementEntry>(this as BankStatementEntry, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BankStatementEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.bankAccountId, bankAccountId) || other.bankAccountId == bankAccountId)&&(identical(other.date, date) || other.date == date)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.type, type) || other.type == type)&&(identical(other.contractorName, contractorName) || other.contractorName == contractorName)&&(identical(other.contractorInn, contractorInn) || other.contractorInn == contractorInn)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.transactionNumber, transactionNumber) || other.transactionNumber == transactionNumber)&&(identical(other.isImported, isImported) || other.isImported == isImported)&&(identical(other.linkedTransactionId, linkedTransactionId) || other.linkedTransactionId == linkedTransactionId)&&(identical(other.operationHash, operationHash) || other.operationHash == operationHash));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,bankAccountId,date,amount,type,contractorName,contractorInn,comment,transactionNumber,isImported,linkedTransactionId,operationHash);

@override
String toString() {
  return 'BankStatementEntry(id: $id, companyId: $companyId, bankAccountId: $bankAccountId, date: $date, amount: $amount, type: $type, contractorName: $contractorName, contractorInn: $contractorInn, comment: $comment, transactionNumber: $transactionNumber, isImported: $isImported, linkedTransactionId: $linkedTransactionId, operationHash: $operationHash)';
}


}

/// @nodoc
abstract mixin class $BankStatementEntryCopyWith<$Res>  {
  factory $BankStatementEntryCopyWith(BankStatementEntry value, $Res Function(BankStatementEntry) _then) = _$BankStatementEntryCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String bankAccountId, DateTime date, double amount, CashFlowType type, String? contractorName, String? contractorInn, String? comment, String? transactionNumber, bool isImported, String? linkedTransactionId, String? operationHash
});




}
/// @nodoc
class _$BankStatementEntryCopyWithImpl<$Res>
    implements $BankStatementEntryCopyWith<$Res> {
  _$BankStatementEntryCopyWithImpl(this._self, this._then);

  final BankStatementEntry _self;
  final $Res Function(BankStatementEntry) _then;

/// Create a copy of BankStatementEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? bankAccountId = null,Object? date = null,Object? amount = null,Object? type = null,Object? contractorName = freezed,Object? contractorInn = freezed,Object? comment = freezed,Object? transactionNumber = freezed,Object? isImported = null,Object? linkedTransactionId = freezed,Object? operationHash = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,bankAccountId: null == bankAccountId ? _self.bankAccountId : bankAccountId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CashFlowType,contractorName: freezed == contractorName ? _self.contractorName : contractorName // ignore: cast_nullable_to_non_nullable
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


class _BankStatementEntry implements BankStatementEntry {
  const _BankStatementEntry({required this.id, required this.companyId, required this.bankAccountId, required this.date, required this.amount, required this.type, this.contractorName, this.contractorInn, this.comment, this.transactionNumber, this.isImported = false, this.linkedTransactionId, this.operationHash});
  

/// Уникальный ID записи.
@override final  String id;
/// ID компании.
@override final  String companyId;
/// ID банковского счета.
@override final  String bankAccountId;
/// Дата операции из выписки.
@override final  DateTime date;
/// Сумма операции.
@override final  double amount;
/// Тип операции (приход/расход).
@override final  CashFlowType type;
/// Название контрагента из выписки.
@override final  String? contractorName;
/// ИНН контрагента из выписки.
@override final  String? contractorInn;
/// Комментарий/назначение платежа.
@override final  String? comment;
/// Номер транзакции в банке.
@override final  String? transactionNumber;
/// Статус импорта (уже создана ли транзакция в системе).
@override@JsonKey() final  bool isImported;
/// ID связанной транзакции (если уже импортировано).
@override final  String? linkedTransactionId;
/// Уникальный хеш операции для дедупликации.
@override final  String? operationHash;

/// Create a copy of BankStatementEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BankStatementEntryCopyWith<_BankStatementEntry> get copyWith => __$BankStatementEntryCopyWithImpl<_BankStatementEntry>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BankStatementEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.bankAccountId, bankAccountId) || other.bankAccountId == bankAccountId)&&(identical(other.date, date) || other.date == date)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.type, type) || other.type == type)&&(identical(other.contractorName, contractorName) || other.contractorName == contractorName)&&(identical(other.contractorInn, contractorInn) || other.contractorInn == contractorInn)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.transactionNumber, transactionNumber) || other.transactionNumber == transactionNumber)&&(identical(other.isImported, isImported) || other.isImported == isImported)&&(identical(other.linkedTransactionId, linkedTransactionId) || other.linkedTransactionId == linkedTransactionId)&&(identical(other.operationHash, operationHash) || other.operationHash == operationHash));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,bankAccountId,date,amount,type,contractorName,contractorInn,comment,transactionNumber,isImported,linkedTransactionId,operationHash);

@override
String toString() {
  return 'BankStatementEntry(id: $id, companyId: $companyId, bankAccountId: $bankAccountId, date: $date, amount: $amount, type: $type, contractorName: $contractorName, contractorInn: $contractorInn, comment: $comment, transactionNumber: $transactionNumber, isImported: $isImported, linkedTransactionId: $linkedTransactionId, operationHash: $operationHash)';
}


}

/// @nodoc
abstract mixin class _$BankStatementEntryCopyWith<$Res> implements $BankStatementEntryCopyWith<$Res> {
  factory _$BankStatementEntryCopyWith(_BankStatementEntry value, $Res Function(_BankStatementEntry) _then) = __$BankStatementEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String bankAccountId, DateTime date, double amount, CashFlowType type, String? contractorName, String? contractorInn, String? comment, String? transactionNumber, bool isImported, String? linkedTransactionId, String? operationHash
});




}
/// @nodoc
class __$BankStatementEntryCopyWithImpl<$Res>
    implements _$BankStatementEntryCopyWith<$Res> {
  __$BankStatementEntryCopyWithImpl(this._self, this._then);

  final _BankStatementEntry _self;
  final $Res Function(_BankStatementEntry) _then;

/// Create a copy of BankStatementEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? bankAccountId = null,Object? date = null,Object? amount = null,Object? type = null,Object? contractorName = freezed,Object? contractorInn = freezed,Object? comment = freezed,Object? transactionNumber = freezed,Object? isImported = null,Object? linkedTransactionId = freezed,Object? operationHash = freezed,}) {
  return _then(_BankStatementEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,bankAccountId: null == bankAccountId ? _self.bankAccountId : bankAccountId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CashFlowType,contractorName: freezed == contractorName ? _self.contractorName : contractorName // ignore: cast_nullable_to_non_nullable
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
