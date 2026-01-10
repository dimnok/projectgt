// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cash_flow_transaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CashFlowTransaction {

/// Уникальный идентификатор операции.
 String get id;/// Идентификатор компании, которой принадлежит операция.
 String get companyId;/// Дата платежа.
 DateTime get date;/// Тип операции (приход/расход).
 CashFlowType get type;/// Сумма операции.
 double get amount;/// Идентификатор объекта (необязательно).
 String? get objectId;/// Наименование объекта (подгружается для отображения).
 String? get objectName;/// Идентификатор договора (необязательно).
 String? get contractId;/// Номер договора (подгружается для отображения).
 String? get contractNumber;/// Идентификатор контрагента (необязательно).
 String? get contractorId;/// Наименование контрагента (подгружается для отображения или хранится текстом).
 String? get contractorName;/// ИНН контрагента (для импортированных транзакций).
 String? get contractorInn;/// Идентификатор статьи ДДС (необязательно).
 String? get categoryId;/// Наименование статьи ДДС (подгружается для отображения).
 String? get categoryName;/// Дата создания записи.
 DateTime? get createdAt;/// Идентификатор создателя (профиль).
 String? get createdBy;/// Имя создателя (подгружается для отображения).
 String? get createdByName;/// Комментарий к операции.
 String? get comment;/// Уникальный хеш операции для дедупликации (при импорте из банка).
 String? get operationHash;
/// Create a copy of CashFlowTransaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CashFlowTransactionCopyWith<CashFlowTransaction> get copyWith => _$CashFlowTransactionCopyWithImpl<CashFlowTransaction>(this as CashFlowTransaction, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CashFlowTransaction&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.date, date) || other.date == date)&&(identical(other.type, type) || other.type == type)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.objectName, objectName) || other.objectName == objectName)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.contractNumber, contractNumber) || other.contractNumber == contractNumber)&&(identical(other.contractorId, contractorId) || other.contractorId == contractorId)&&(identical(other.contractorName, contractorName) || other.contractorName == contractorName)&&(identical(other.contractorInn, contractorInn) || other.contractorInn == contractorInn)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdByName, createdByName) || other.createdByName == createdByName)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.operationHash, operationHash) || other.operationHash == operationHash));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,date,type,amount,objectId,objectName,contractId,contractNumber,contractorId,contractorName,contractorInn,categoryId,categoryName,createdAt,createdBy,createdByName,comment,operationHash]);

@override
String toString() {
  return 'CashFlowTransaction(id: $id, companyId: $companyId, date: $date, type: $type, amount: $amount, objectId: $objectId, objectName: $objectName, contractId: $contractId, contractNumber: $contractNumber, contractorId: $contractorId, contractorName: $contractorName, contractorInn: $contractorInn, categoryId: $categoryId, categoryName: $categoryName, createdAt: $createdAt, createdBy: $createdBy, createdByName: $createdByName, comment: $comment, operationHash: $operationHash)';
}


}

/// @nodoc
abstract mixin class $CashFlowTransactionCopyWith<$Res>  {
  factory $CashFlowTransactionCopyWith(CashFlowTransaction value, $Res Function(CashFlowTransaction) _then) = _$CashFlowTransactionCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, DateTime date, CashFlowType type, double amount, String? objectId, String? objectName, String? contractId, String? contractNumber, String? contractorId, String? contractorName, String? contractorInn, String? categoryId, String? categoryName, DateTime? createdAt, String? createdBy, String? createdByName, String? comment, String? operationHash
});




}
/// @nodoc
class _$CashFlowTransactionCopyWithImpl<$Res>
    implements $CashFlowTransactionCopyWith<$Res> {
  _$CashFlowTransactionCopyWithImpl(this._self, this._then);

  final CashFlowTransaction _self;
  final $Res Function(CashFlowTransaction) _then;

/// Create a copy of CashFlowTransaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? date = null,Object? type = null,Object? amount = null,Object? objectId = freezed,Object? objectName = freezed,Object? contractId = freezed,Object? contractNumber = freezed,Object? contractorId = freezed,Object? contractorName = freezed,Object? contractorInn = freezed,Object? categoryId = freezed,Object? categoryName = freezed,Object? createdAt = freezed,Object? createdBy = freezed,Object? createdByName = freezed,Object? comment = freezed,Object? operationHash = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CashFlowType,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,objectId: freezed == objectId ? _self.objectId : objectId // ignore: cast_nullable_to_non_nullable
as String?,objectName: freezed == objectName ? _self.objectName : objectName // ignore: cast_nullable_to_non_nullable
as String?,contractId: freezed == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String?,contractNumber: freezed == contractNumber ? _self.contractNumber : contractNumber // ignore: cast_nullable_to_non_nullable
as String?,contractorId: freezed == contractorId ? _self.contractorId : contractorId // ignore: cast_nullable_to_non_nullable
as String?,contractorName: freezed == contractorName ? _self.contractorName : contractorName // ignore: cast_nullable_to_non_nullable
as String?,contractorInn: freezed == contractorInn ? _self.contractorInn : contractorInn // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,createdByName: freezed == createdByName ? _self.createdByName : createdByName // ignore: cast_nullable_to_non_nullable
as String?,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,operationHash: freezed == operationHash ? _self.operationHash : operationHash // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc


class _CashFlowTransaction extends CashFlowTransaction {
  const _CashFlowTransaction({required this.id, required this.companyId, required this.date, required this.type, required this.amount, this.objectId, this.objectName, this.contractId, this.contractNumber, this.contractorId, this.contractorName, this.contractorInn, this.categoryId, this.categoryName, this.createdAt, this.createdBy, this.createdByName, this.comment, this.operationHash}): super._();
  

/// Уникальный идентификатор операции.
@override final  String id;
/// Идентификатор компании, которой принадлежит операция.
@override final  String companyId;
/// Дата платежа.
@override final  DateTime date;
/// Тип операции (приход/расход).
@override final  CashFlowType type;
/// Сумма операции.
@override final  double amount;
/// Идентификатор объекта (необязательно).
@override final  String? objectId;
/// Наименование объекта (подгружается для отображения).
@override final  String? objectName;
/// Идентификатор договора (необязательно).
@override final  String? contractId;
/// Номер договора (подгружается для отображения).
@override final  String? contractNumber;
/// Идентификатор контрагента (необязательно).
@override final  String? contractorId;
/// Наименование контрагента (подгружается для отображения или хранится текстом).
@override final  String? contractorName;
/// ИНН контрагента (для импортированных транзакций).
@override final  String? contractorInn;
/// Идентификатор статьи ДДС (необязательно).
@override final  String? categoryId;
/// Наименование статьи ДДС (подгружается для отображения).
@override final  String? categoryName;
/// Дата создания записи.
@override final  DateTime? createdAt;
/// Идентификатор создателя (профиль).
@override final  String? createdBy;
/// Имя создателя (подгружается для отображения).
@override final  String? createdByName;
/// Комментарий к операции.
@override final  String? comment;
/// Уникальный хеш операции для дедупликации (при импорте из банка).
@override final  String? operationHash;

/// Create a copy of CashFlowTransaction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CashFlowTransactionCopyWith<_CashFlowTransaction> get copyWith => __$CashFlowTransactionCopyWithImpl<_CashFlowTransaction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CashFlowTransaction&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.date, date) || other.date == date)&&(identical(other.type, type) || other.type == type)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.objectName, objectName) || other.objectName == objectName)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.contractNumber, contractNumber) || other.contractNumber == contractNumber)&&(identical(other.contractorId, contractorId) || other.contractorId == contractorId)&&(identical(other.contractorName, contractorName) || other.contractorName == contractorName)&&(identical(other.contractorInn, contractorInn) || other.contractorInn == contractorInn)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdByName, createdByName) || other.createdByName == createdByName)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.operationHash, operationHash) || other.operationHash == operationHash));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,date,type,amount,objectId,objectName,contractId,contractNumber,contractorId,contractorName,contractorInn,categoryId,categoryName,createdAt,createdBy,createdByName,comment,operationHash]);

@override
String toString() {
  return 'CashFlowTransaction(id: $id, companyId: $companyId, date: $date, type: $type, amount: $amount, objectId: $objectId, objectName: $objectName, contractId: $contractId, contractNumber: $contractNumber, contractorId: $contractorId, contractorName: $contractorName, contractorInn: $contractorInn, categoryId: $categoryId, categoryName: $categoryName, createdAt: $createdAt, createdBy: $createdBy, createdByName: $createdByName, comment: $comment, operationHash: $operationHash)';
}


}

/// @nodoc
abstract mixin class _$CashFlowTransactionCopyWith<$Res> implements $CashFlowTransactionCopyWith<$Res> {
  factory _$CashFlowTransactionCopyWith(_CashFlowTransaction value, $Res Function(_CashFlowTransaction) _then) = __$CashFlowTransactionCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, DateTime date, CashFlowType type, double amount, String? objectId, String? objectName, String? contractId, String? contractNumber, String? contractorId, String? contractorName, String? contractorInn, String? categoryId, String? categoryName, DateTime? createdAt, String? createdBy, String? createdByName, String? comment, String? operationHash
});




}
/// @nodoc
class __$CashFlowTransactionCopyWithImpl<$Res>
    implements _$CashFlowTransactionCopyWith<$Res> {
  __$CashFlowTransactionCopyWithImpl(this._self, this._then);

  final _CashFlowTransaction _self;
  final $Res Function(_CashFlowTransaction) _then;

/// Create a copy of CashFlowTransaction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? date = null,Object? type = null,Object? amount = null,Object? objectId = freezed,Object? objectName = freezed,Object? contractId = freezed,Object? contractNumber = freezed,Object? contractorId = freezed,Object? contractorName = freezed,Object? contractorInn = freezed,Object? categoryId = freezed,Object? categoryName = freezed,Object? createdAt = freezed,Object? createdBy = freezed,Object? createdByName = freezed,Object? comment = freezed,Object? operationHash = freezed,}) {
  return _then(_CashFlowTransaction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CashFlowType,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,objectId: freezed == objectId ? _self.objectId : objectId // ignore: cast_nullable_to_non_nullable
as String?,objectName: freezed == objectName ? _self.objectName : objectName // ignore: cast_nullable_to_non_nullable
as String?,contractId: freezed == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String?,contractNumber: freezed == contractNumber ? _self.contractNumber : contractNumber // ignore: cast_nullable_to_non_nullable
as String?,contractorId: freezed == contractorId ? _self.contractorId : contractorId // ignore: cast_nullable_to_non_nullable
as String?,contractorName: freezed == contractorName ? _self.contractorName : contractorName // ignore: cast_nullable_to_non_nullable
as String?,contractorInn: freezed == contractorInn ? _self.contractorInn : contractorInn // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,createdByName: freezed == createdByName ? _self.createdByName : createdByName // ignore: cast_nullable_to_non_nullable
as String?,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,operationHash: freezed == operationHash ? _self.operationHash : operationHash // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
