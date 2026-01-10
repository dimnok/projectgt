// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cash_flow_transaction_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CashFlowTransactionModel {

 String get id; String get companyId;@JsonKey(toJson: _dateOnlyToJson) DateTime get date; CashFlowType get type; double get amount; String? get objectId; String? get contractId; String? get contractorId; String? get contractorName; String? get contractorInn; String? get categoryId; String? get comment; DateTime? get createdAt; String? get createdBy; String? get operationHash;// Поля из join-запросов (не для записи в БД)
@JsonKey(includeToJson: false) String? get objectName;@JsonKey(includeToJson: false) String? get contractNumber;@JsonKey(includeToJson: false) String? get categoryName;@JsonKey(includeToJson: false) String? get createdByName;
/// Create a copy of CashFlowTransactionModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CashFlowTransactionModelCopyWith<CashFlowTransactionModel> get copyWith => _$CashFlowTransactionModelCopyWithImpl<CashFlowTransactionModel>(this as CashFlowTransactionModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CashFlowTransactionModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.date, date) || other.date == date)&&(identical(other.type, type) || other.type == type)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.contractorId, contractorId) || other.contractorId == contractorId)&&(identical(other.contractorName, contractorName) || other.contractorName == contractorName)&&(identical(other.contractorInn, contractorInn) || other.contractorInn == contractorInn)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.operationHash, operationHash) || other.operationHash == operationHash)&&(identical(other.objectName, objectName) || other.objectName == objectName)&&(identical(other.contractNumber, contractNumber) || other.contractNumber == contractNumber)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.createdByName, createdByName) || other.createdByName == createdByName));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,date,type,amount,objectId,contractId,contractorId,contractorName,contractorInn,categoryId,comment,createdAt,createdBy,operationHash,objectName,contractNumber,categoryName,createdByName]);

@override
String toString() {
  return 'CashFlowTransactionModel(id: $id, companyId: $companyId, date: $date, type: $type, amount: $amount, objectId: $objectId, contractId: $contractId, contractorId: $contractorId, contractorName: $contractorName, contractorInn: $contractorInn, categoryId: $categoryId, comment: $comment, createdAt: $createdAt, createdBy: $createdBy, operationHash: $operationHash, objectName: $objectName, contractNumber: $contractNumber, categoryName: $categoryName, createdByName: $createdByName)';
}


}

/// @nodoc
abstract mixin class $CashFlowTransactionModelCopyWith<$Res>  {
  factory $CashFlowTransactionModelCopyWith(CashFlowTransactionModel value, $Res Function(CashFlowTransactionModel) _then) = _$CashFlowTransactionModelCopyWithImpl;
@useResult
$Res call({
 String id, String companyId,@JsonKey(toJson: _dateOnlyToJson) DateTime date, CashFlowType type, double amount, String? objectId, String? contractId, String? contractorId, String? contractorName, String? contractorInn, String? categoryId, String? comment, DateTime? createdAt, String? createdBy, String? operationHash,@JsonKey(includeToJson: false) String? objectName,@JsonKey(includeToJson: false) String? contractNumber,@JsonKey(includeToJson: false) String? categoryName,@JsonKey(includeToJson: false) String? createdByName
});




}
/// @nodoc
class _$CashFlowTransactionModelCopyWithImpl<$Res>
    implements $CashFlowTransactionModelCopyWith<$Res> {
  _$CashFlowTransactionModelCopyWithImpl(this._self, this._then);

  final CashFlowTransactionModel _self;
  final $Res Function(CashFlowTransactionModel) _then;

/// Create a copy of CashFlowTransactionModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? date = null,Object? type = null,Object? amount = null,Object? objectId = freezed,Object? contractId = freezed,Object? contractorId = freezed,Object? contractorName = freezed,Object? contractorInn = freezed,Object? categoryId = freezed,Object? comment = freezed,Object? createdAt = freezed,Object? createdBy = freezed,Object? operationHash = freezed,Object? objectName = freezed,Object? contractNumber = freezed,Object? categoryName = freezed,Object? createdByName = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CashFlowType,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,objectId: freezed == objectId ? _self.objectId : objectId // ignore: cast_nullable_to_non_nullable
as String?,contractId: freezed == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String?,contractorId: freezed == contractorId ? _self.contractorId : contractorId // ignore: cast_nullable_to_non_nullable
as String?,contractorName: freezed == contractorName ? _self.contractorName : contractorName // ignore: cast_nullable_to_non_nullable
as String?,contractorInn: freezed == contractorInn ? _self.contractorInn : contractorInn // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,operationHash: freezed == operationHash ? _self.operationHash : operationHash // ignore: cast_nullable_to_non_nullable
as String?,objectName: freezed == objectName ? _self.objectName : objectName // ignore: cast_nullable_to_non_nullable
as String?,contractNumber: freezed == contractNumber ? _self.contractNumber : contractNumber // ignore: cast_nullable_to_non_nullable
as String?,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,createdByName: freezed == createdByName ? _self.createdByName : createdByName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _CashFlowTransactionModel extends CashFlowTransactionModel {
  const _CashFlowTransactionModel({required this.id, required this.companyId, @JsonKey(toJson: _dateOnlyToJson) required this.date, required this.type, required this.amount, this.objectId, this.contractId, this.contractorId, this.contractorName, this.contractorInn, this.categoryId, this.comment, this.createdAt, this.createdBy, this.operationHash, @JsonKey(includeToJson: false) this.objectName, @JsonKey(includeToJson: false) this.contractNumber, @JsonKey(includeToJson: false) this.categoryName, @JsonKey(includeToJson: false) this.createdByName}): super._();
  

@override final  String id;
@override final  String companyId;
@override@JsonKey(toJson: _dateOnlyToJson) final  DateTime date;
@override final  CashFlowType type;
@override final  double amount;
@override final  String? objectId;
@override final  String? contractId;
@override final  String? contractorId;
@override final  String? contractorName;
@override final  String? contractorInn;
@override final  String? categoryId;
@override final  String? comment;
@override final  DateTime? createdAt;
@override final  String? createdBy;
@override final  String? operationHash;
// Поля из join-запросов (не для записи в БД)
@override@JsonKey(includeToJson: false) final  String? objectName;
@override@JsonKey(includeToJson: false) final  String? contractNumber;
@override@JsonKey(includeToJson: false) final  String? categoryName;
@override@JsonKey(includeToJson: false) final  String? createdByName;

/// Create a copy of CashFlowTransactionModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CashFlowTransactionModelCopyWith<_CashFlowTransactionModel> get copyWith => __$CashFlowTransactionModelCopyWithImpl<_CashFlowTransactionModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CashFlowTransactionModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.date, date) || other.date == date)&&(identical(other.type, type) || other.type == type)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.contractorId, contractorId) || other.contractorId == contractorId)&&(identical(other.contractorName, contractorName) || other.contractorName == contractorName)&&(identical(other.contractorInn, contractorInn) || other.contractorInn == contractorInn)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.operationHash, operationHash) || other.operationHash == operationHash)&&(identical(other.objectName, objectName) || other.objectName == objectName)&&(identical(other.contractNumber, contractNumber) || other.contractNumber == contractNumber)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.createdByName, createdByName) || other.createdByName == createdByName));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,date,type,amount,objectId,contractId,contractorId,contractorName,contractorInn,categoryId,comment,createdAt,createdBy,operationHash,objectName,contractNumber,categoryName,createdByName]);

@override
String toString() {
  return 'CashFlowTransactionModel(id: $id, companyId: $companyId, date: $date, type: $type, amount: $amount, objectId: $objectId, contractId: $contractId, contractorId: $contractorId, contractorName: $contractorName, contractorInn: $contractorInn, categoryId: $categoryId, comment: $comment, createdAt: $createdAt, createdBy: $createdBy, operationHash: $operationHash, objectName: $objectName, contractNumber: $contractNumber, categoryName: $categoryName, createdByName: $createdByName)';
}


}

/// @nodoc
abstract mixin class _$CashFlowTransactionModelCopyWith<$Res> implements $CashFlowTransactionModelCopyWith<$Res> {
  factory _$CashFlowTransactionModelCopyWith(_CashFlowTransactionModel value, $Res Function(_CashFlowTransactionModel) _then) = __$CashFlowTransactionModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId,@JsonKey(toJson: _dateOnlyToJson) DateTime date, CashFlowType type, double amount, String? objectId, String? contractId, String? contractorId, String? contractorName, String? contractorInn, String? categoryId, String? comment, DateTime? createdAt, String? createdBy, String? operationHash,@JsonKey(includeToJson: false) String? objectName,@JsonKey(includeToJson: false) String? contractNumber,@JsonKey(includeToJson: false) String? categoryName,@JsonKey(includeToJson: false) String? createdByName
});




}
/// @nodoc
class __$CashFlowTransactionModelCopyWithImpl<$Res>
    implements _$CashFlowTransactionModelCopyWith<$Res> {
  __$CashFlowTransactionModelCopyWithImpl(this._self, this._then);

  final _CashFlowTransactionModel _self;
  final $Res Function(_CashFlowTransactionModel) _then;

/// Create a copy of CashFlowTransactionModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? date = null,Object? type = null,Object? amount = null,Object? objectId = freezed,Object? contractId = freezed,Object? contractorId = freezed,Object? contractorName = freezed,Object? contractorInn = freezed,Object? categoryId = freezed,Object? comment = freezed,Object? createdAt = freezed,Object? createdBy = freezed,Object? operationHash = freezed,Object? objectName = freezed,Object? contractNumber = freezed,Object? categoryName = freezed,Object? createdByName = freezed,}) {
  return _then(_CashFlowTransactionModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CashFlowType,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,objectId: freezed == objectId ? _self.objectId : objectId // ignore: cast_nullable_to_non_nullable
as String?,contractId: freezed == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String?,contractorId: freezed == contractorId ? _self.contractorId : contractorId // ignore: cast_nullable_to_non_nullable
as String?,contractorName: freezed == contractorName ? _self.contractorName : contractorName // ignore: cast_nullable_to_non_nullable
as String?,contractorInn: freezed == contractorInn ? _self.contractorInn : contractorInn // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,operationHash: freezed == operationHash ? _self.operationHash : operationHash // ignore: cast_nullable_to_non_nullable
as String?,objectName: freezed == objectName ? _self.objectName : objectName // ignore: cast_nullable_to_non_nullable
as String?,contractNumber: freezed == contractNumber ? _self.contractNumber : contractNumber // ignore: cast_nullable_to_non_nullable
as String?,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,createdByName: freezed == createdByName ? _self.createdByName : createdByName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
