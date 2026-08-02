// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tmc_repair_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TmcRepairModel {

 String get id; String get companyId; String get itemId; String? get unitId;@JsonKey(fromJson: tmcParseRequiredDate, toJson: tmcDateOnlyToJson) DateTime get sentAt; String? get reason; String? get faultDescription; String? get repairOrgName; String? get responsibleEmployeeId; double? get estimatedCost; double? get actualCost;@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) DateTime? get completedAt; String? get result; String? get conditionAfterId;@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) DateTime? get repairWarrantyUntil; TmcRepairStatus get status; String? get sendOperationId; String? get returnOperationId; DateTime? get createdAt; DateTime? get updatedAt; String? get createdBy;@JsonKey(includeToJson: false) String? get itemName;@JsonKey(includeToJson: false) String? get inventoryNumber;
/// Create a copy of TmcRepairModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TmcRepairModelCopyWith<TmcRepairModel> get copyWith => _$TmcRepairModelCopyWithImpl<TmcRepairModel>(this as TmcRepairModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TmcRepairModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.faultDescription, faultDescription) || other.faultDescription == faultDescription)&&(identical(other.repairOrgName, repairOrgName) || other.repairOrgName == repairOrgName)&&(identical(other.responsibleEmployeeId, responsibleEmployeeId) || other.responsibleEmployeeId == responsibleEmployeeId)&&(identical(other.estimatedCost, estimatedCost) || other.estimatedCost == estimatedCost)&&(identical(other.actualCost, actualCost) || other.actualCost == actualCost)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.result, result) || other.result == result)&&(identical(other.conditionAfterId, conditionAfterId) || other.conditionAfterId == conditionAfterId)&&(identical(other.repairWarrantyUntil, repairWarrantyUntil) || other.repairWarrantyUntil == repairWarrantyUntil)&&(identical(other.status, status) || other.status == status)&&(identical(other.sendOperationId, sendOperationId) || other.sendOperationId == sendOperationId)&&(identical(other.returnOperationId, returnOperationId) || other.returnOperationId == returnOperationId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.itemName, itemName) || other.itemName == itemName)&&(identical(other.inventoryNumber, inventoryNumber) || other.inventoryNumber == inventoryNumber));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,itemId,unitId,sentAt,reason,faultDescription,repairOrgName,responsibleEmployeeId,estimatedCost,actualCost,completedAt,result,conditionAfterId,repairWarrantyUntil,status,sendOperationId,returnOperationId,createdAt,updatedAt,createdBy,itemName,inventoryNumber]);

@override
String toString() {
  return 'TmcRepairModel(id: $id, companyId: $companyId, itemId: $itemId, unitId: $unitId, sentAt: $sentAt, reason: $reason, faultDescription: $faultDescription, repairOrgName: $repairOrgName, responsibleEmployeeId: $responsibleEmployeeId, estimatedCost: $estimatedCost, actualCost: $actualCost, completedAt: $completedAt, result: $result, conditionAfterId: $conditionAfterId, repairWarrantyUntil: $repairWarrantyUntil, status: $status, sendOperationId: $sendOperationId, returnOperationId: $returnOperationId, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, itemName: $itemName, inventoryNumber: $inventoryNumber)';
}


}

/// @nodoc
abstract mixin class $TmcRepairModelCopyWith<$Res>  {
  factory $TmcRepairModelCopyWith(TmcRepairModel value, $Res Function(TmcRepairModel) _then) = _$TmcRepairModelCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String itemId, String? unitId,@JsonKey(fromJson: tmcParseRequiredDate, toJson: tmcDateOnlyToJson) DateTime sentAt, String? reason, String? faultDescription, String? repairOrgName, String? responsibleEmployeeId, double? estimatedCost, double? actualCost,@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) DateTime? completedAt, String? result, String? conditionAfterId,@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) DateTime? repairWarrantyUntil, TmcRepairStatus status, String? sendOperationId, String? returnOperationId, DateTime? createdAt, DateTime? updatedAt, String? createdBy,@JsonKey(includeToJson: false) String? itemName,@JsonKey(includeToJson: false) String? inventoryNumber
});




}
/// @nodoc
class _$TmcRepairModelCopyWithImpl<$Res>
    implements $TmcRepairModelCopyWith<$Res> {
  _$TmcRepairModelCopyWithImpl(this._self, this._then);

  final TmcRepairModel _self;
  final $Res Function(TmcRepairModel) _then;

/// Create a copy of TmcRepairModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? itemId = null,Object? unitId = freezed,Object? sentAt = null,Object? reason = freezed,Object? faultDescription = freezed,Object? repairOrgName = freezed,Object? responsibleEmployeeId = freezed,Object? estimatedCost = freezed,Object? actualCost = freezed,Object? completedAt = freezed,Object? result = freezed,Object? conditionAfterId = freezed,Object? repairWarrantyUntil = freezed,Object? status = null,Object? sendOperationId = freezed,Object? returnOperationId = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,Object? itemName = freezed,Object? inventoryNumber = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,unitId: freezed == unitId ? _self.unitId : unitId // ignore: cast_nullable_to_non_nullable
as String?,sentAt: null == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,faultDescription: freezed == faultDescription ? _self.faultDescription : faultDescription // ignore: cast_nullable_to_non_nullable
as String?,repairOrgName: freezed == repairOrgName ? _self.repairOrgName : repairOrgName // ignore: cast_nullable_to_non_nullable
as String?,responsibleEmployeeId: freezed == responsibleEmployeeId ? _self.responsibleEmployeeId : responsibleEmployeeId // ignore: cast_nullable_to_non_nullable
as String?,estimatedCost: freezed == estimatedCost ? _self.estimatedCost : estimatedCost // ignore: cast_nullable_to_non_nullable
as double?,actualCost: freezed == actualCost ? _self.actualCost : actualCost // ignore: cast_nullable_to_non_nullable
as double?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String?,conditionAfterId: freezed == conditionAfterId ? _self.conditionAfterId : conditionAfterId // ignore: cast_nullable_to_non_nullable
as String?,repairWarrantyUntil: freezed == repairWarrantyUntil ? _self.repairWarrantyUntil : repairWarrantyUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TmcRepairStatus,sendOperationId: freezed == sendOperationId ? _self.sendOperationId : sendOperationId // ignore: cast_nullable_to_non_nullable
as String?,returnOperationId: freezed == returnOperationId ? _self.returnOperationId : returnOperationId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,itemName: freezed == itemName ? _self.itemName : itemName // ignore: cast_nullable_to_non_nullable
as String?,inventoryNumber: freezed == inventoryNumber ? _self.inventoryNumber : inventoryNumber // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _TmcRepairModel extends TmcRepairModel {
  const _TmcRepairModel({required this.id, required this.companyId, required this.itemId, this.unitId, @JsonKey(fromJson: tmcParseRequiredDate, toJson: tmcDateOnlyToJson) required this.sentAt, this.reason, this.faultDescription, this.repairOrgName, this.responsibleEmployeeId, this.estimatedCost, this.actualCost, @JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) this.completedAt, this.result, this.conditionAfterId, @JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) this.repairWarrantyUntil, this.status = TmcRepairStatus.open, this.sendOperationId, this.returnOperationId, this.createdAt, this.updatedAt, this.createdBy, @JsonKey(includeToJson: false) this.itemName, @JsonKey(includeToJson: false) this.inventoryNumber}): super._();
  

@override final  String id;
@override final  String companyId;
@override final  String itemId;
@override final  String? unitId;
@override@JsonKey(fromJson: tmcParseRequiredDate, toJson: tmcDateOnlyToJson) final  DateTime sentAt;
@override final  String? reason;
@override final  String? faultDescription;
@override final  String? repairOrgName;
@override final  String? responsibleEmployeeId;
@override final  double? estimatedCost;
@override final  double? actualCost;
@override@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) final  DateTime? completedAt;
@override final  String? result;
@override final  String? conditionAfterId;
@override@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) final  DateTime? repairWarrantyUntil;
@override@JsonKey() final  TmcRepairStatus status;
@override final  String? sendOperationId;
@override final  String? returnOperationId;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;
@override final  String? createdBy;
@override@JsonKey(includeToJson: false) final  String? itemName;
@override@JsonKey(includeToJson: false) final  String? inventoryNumber;

/// Create a copy of TmcRepairModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TmcRepairModelCopyWith<_TmcRepairModel> get copyWith => __$TmcRepairModelCopyWithImpl<_TmcRepairModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TmcRepairModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.faultDescription, faultDescription) || other.faultDescription == faultDescription)&&(identical(other.repairOrgName, repairOrgName) || other.repairOrgName == repairOrgName)&&(identical(other.responsibleEmployeeId, responsibleEmployeeId) || other.responsibleEmployeeId == responsibleEmployeeId)&&(identical(other.estimatedCost, estimatedCost) || other.estimatedCost == estimatedCost)&&(identical(other.actualCost, actualCost) || other.actualCost == actualCost)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.result, result) || other.result == result)&&(identical(other.conditionAfterId, conditionAfterId) || other.conditionAfterId == conditionAfterId)&&(identical(other.repairWarrantyUntil, repairWarrantyUntil) || other.repairWarrantyUntil == repairWarrantyUntil)&&(identical(other.status, status) || other.status == status)&&(identical(other.sendOperationId, sendOperationId) || other.sendOperationId == sendOperationId)&&(identical(other.returnOperationId, returnOperationId) || other.returnOperationId == returnOperationId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.itemName, itemName) || other.itemName == itemName)&&(identical(other.inventoryNumber, inventoryNumber) || other.inventoryNumber == inventoryNumber));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,itemId,unitId,sentAt,reason,faultDescription,repairOrgName,responsibleEmployeeId,estimatedCost,actualCost,completedAt,result,conditionAfterId,repairWarrantyUntil,status,sendOperationId,returnOperationId,createdAt,updatedAt,createdBy,itemName,inventoryNumber]);

@override
String toString() {
  return 'TmcRepairModel(id: $id, companyId: $companyId, itemId: $itemId, unitId: $unitId, sentAt: $sentAt, reason: $reason, faultDescription: $faultDescription, repairOrgName: $repairOrgName, responsibleEmployeeId: $responsibleEmployeeId, estimatedCost: $estimatedCost, actualCost: $actualCost, completedAt: $completedAt, result: $result, conditionAfterId: $conditionAfterId, repairWarrantyUntil: $repairWarrantyUntil, status: $status, sendOperationId: $sendOperationId, returnOperationId: $returnOperationId, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, itemName: $itemName, inventoryNumber: $inventoryNumber)';
}


}

/// @nodoc
abstract mixin class _$TmcRepairModelCopyWith<$Res> implements $TmcRepairModelCopyWith<$Res> {
  factory _$TmcRepairModelCopyWith(_TmcRepairModel value, $Res Function(_TmcRepairModel) _then) = __$TmcRepairModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String itemId, String? unitId,@JsonKey(fromJson: tmcParseRequiredDate, toJson: tmcDateOnlyToJson) DateTime sentAt, String? reason, String? faultDescription, String? repairOrgName, String? responsibleEmployeeId, double? estimatedCost, double? actualCost,@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) DateTime? completedAt, String? result, String? conditionAfterId,@JsonKey(fromJson: tmcParseDate, toJson: tmcDateOnlyToJson) DateTime? repairWarrantyUntil, TmcRepairStatus status, String? sendOperationId, String? returnOperationId, DateTime? createdAt, DateTime? updatedAt, String? createdBy,@JsonKey(includeToJson: false) String? itemName,@JsonKey(includeToJson: false) String? inventoryNumber
});




}
/// @nodoc
class __$TmcRepairModelCopyWithImpl<$Res>
    implements _$TmcRepairModelCopyWith<$Res> {
  __$TmcRepairModelCopyWithImpl(this._self, this._then);

  final _TmcRepairModel _self;
  final $Res Function(_TmcRepairModel) _then;

/// Create a copy of TmcRepairModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? itemId = null,Object? unitId = freezed,Object? sentAt = null,Object? reason = freezed,Object? faultDescription = freezed,Object? repairOrgName = freezed,Object? responsibleEmployeeId = freezed,Object? estimatedCost = freezed,Object? actualCost = freezed,Object? completedAt = freezed,Object? result = freezed,Object? conditionAfterId = freezed,Object? repairWarrantyUntil = freezed,Object? status = null,Object? sendOperationId = freezed,Object? returnOperationId = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,Object? itemName = freezed,Object? inventoryNumber = freezed,}) {
  return _then(_TmcRepairModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,unitId: freezed == unitId ? _self.unitId : unitId // ignore: cast_nullable_to_non_nullable
as String?,sentAt: null == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,faultDescription: freezed == faultDescription ? _self.faultDescription : faultDescription // ignore: cast_nullable_to_non_nullable
as String?,repairOrgName: freezed == repairOrgName ? _self.repairOrgName : repairOrgName // ignore: cast_nullable_to_non_nullable
as String?,responsibleEmployeeId: freezed == responsibleEmployeeId ? _self.responsibleEmployeeId : responsibleEmployeeId // ignore: cast_nullable_to_non_nullable
as String?,estimatedCost: freezed == estimatedCost ? _self.estimatedCost : estimatedCost // ignore: cast_nullable_to_non_nullable
as double?,actualCost: freezed == actualCost ? _self.actualCost : actualCost // ignore: cast_nullable_to_non_nullable
as double?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String?,conditionAfterId: freezed == conditionAfterId ? _self.conditionAfterId : conditionAfterId // ignore: cast_nullable_to_non_nullable
as String?,repairWarrantyUntil: freezed == repairWarrantyUntil ? _self.repairWarrantyUntil : repairWarrantyUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TmcRepairStatus,sendOperationId: freezed == sendOperationId ? _self.sendOperationId : sendOperationId // ignore: cast_nullable_to_non_nullable
as String?,returnOperationId: freezed == returnOperationId ? _self.returnOperationId : returnOperationId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,itemName: freezed == itemName ? _self.itemName : itemName // ignore: cast_nullable_to_non_nullable
as String?,inventoryNumber: freezed == inventoryNumber ? _self.inventoryNumber : inventoryNumber // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
