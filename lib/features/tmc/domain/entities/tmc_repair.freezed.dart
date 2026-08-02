// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tmc_repair.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TmcRepair {

/// Идентификатор записи.
 String get id;/// Компания-владелец.
 String get companyId;/// Позиция каталога.
 String get itemId;/// Единица.
 String? get unitId;/// Дата отправки в ремонт.
 DateTime get sentAt;/// Причина.
 String? get reason;/// Описание неисправности.
 String? get faultDescription;/// Название ремонтной организации.
 String? get repairOrgName;/// Ответственный сотрудник.
 String? get responsibleEmployeeId;/// Ориентировочная стоимость.
 double? get estimatedCost;/// Фактическая стоимость.
 double? get actualCost;/// Дата завершения.
 DateTime? get completedAt;/// Результат ремонта.
 String? get result;/// Состояние после ремонта.
 String? get conditionAfterId;/// Гарантия на ремонт до.
 DateTime? get repairWarrantyUntil;/// Статус ремонта.
 TmcRepairStatus get status;/// Операция отправки.
 String? get sendOperationId;/// Операция возврата.
 String? get returnOperationId;/// Дата создания.
 DateTime? get createdAt;/// Дата обновления.
 DateTime? get updatedAt;/// Автор создания.
 String? get createdBy;/// Наименование позиции (join).
 String? get itemName;/// Инвентарный номер (join).
 String? get inventoryNumber;
/// Create a copy of TmcRepair
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TmcRepairCopyWith<TmcRepair> get copyWith => _$TmcRepairCopyWithImpl<TmcRepair>(this as TmcRepair, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TmcRepair&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.faultDescription, faultDescription) || other.faultDescription == faultDescription)&&(identical(other.repairOrgName, repairOrgName) || other.repairOrgName == repairOrgName)&&(identical(other.responsibleEmployeeId, responsibleEmployeeId) || other.responsibleEmployeeId == responsibleEmployeeId)&&(identical(other.estimatedCost, estimatedCost) || other.estimatedCost == estimatedCost)&&(identical(other.actualCost, actualCost) || other.actualCost == actualCost)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.result, result) || other.result == result)&&(identical(other.conditionAfterId, conditionAfterId) || other.conditionAfterId == conditionAfterId)&&(identical(other.repairWarrantyUntil, repairWarrantyUntil) || other.repairWarrantyUntil == repairWarrantyUntil)&&(identical(other.status, status) || other.status == status)&&(identical(other.sendOperationId, sendOperationId) || other.sendOperationId == sendOperationId)&&(identical(other.returnOperationId, returnOperationId) || other.returnOperationId == returnOperationId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.itemName, itemName) || other.itemName == itemName)&&(identical(other.inventoryNumber, inventoryNumber) || other.inventoryNumber == inventoryNumber));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,itemId,unitId,sentAt,reason,faultDescription,repairOrgName,responsibleEmployeeId,estimatedCost,actualCost,completedAt,result,conditionAfterId,repairWarrantyUntil,status,sendOperationId,returnOperationId,createdAt,updatedAt,createdBy,itemName,inventoryNumber]);

@override
String toString() {
  return 'TmcRepair(id: $id, companyId: $companyId, itemId: $itemId, unitId: $unitId, sentAt: $sentAt, reason: $reason, faultDescription: $faultDescription, repairOrgName: $repairOrgName, responsibleEmployeeId: $responsibleEmployeeId, estimatedCost: $estimatedCost, actualCost: $actualCost, completedAt: $completedAt, result: $result, conditionAfterId: $conditionAfterId, repairWarrantyUntil: $repairWarrantyUntil, status: $status, sendOperationId: $sendOperationId, returnOperationId: $returnOperationId, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, itemName: $itemName, inventoryNumber: $inventoryNumber)';
}


}

/// @nodoc
abstract mixin class $TmcRepairCopyWith<$Res>  {
  factory $TmcRepairCopyWith(TmcRepair value, $Res Function(TmcRepair) _then) = _$TmcRepairCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String itemId, String? unitId, DateTime sentAt, String? reason, String? faultDescription, String? repairOrgName, String? responsibleEmployeeId, double? estimatedCost, double? actualCost, DateTime? completedAt, String? result, String? conditionAfterId, DateTime? repairWarrantyUntil, TmcRepairStatus status, String? sendOperationId, String? returnOperationId, DateTime? createdAt, DateTime? updatedAt, String? createdBy, String? itemName, String? inventoryNumber
});




}
/// @nodoc
class _$TmcRepairCopyWithImpl<$Res>
    implements $TmcRepairCopyWith<$Res> {
  _$TmcRepairCopyWithImpl(this._self, this._then);

  final TmcRepair _self;
  final $Res Function(TmcRepair) _then;

/// Create a copy of TmcRepair
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


class _TmcRepair implements TmcRepair {
  const _TmcRepair({required this.id, required this.companyId, required this.itemId, this.unitId, required this.sentAt, this.reason, this.faultDescription, this.repairOrgName, this.responsibleEmployeeId, this.estimatedCost, this.actualCost, this.completedAt, this.result, this.conditionAfterId, this.repairWarrantyUntil, this.status = TmcRepairStatus.open, this.sendOperationId, this.returnOperationId, this.createdAt, this.updatedAt, this.createdBy, this.itemName, this.inventoryNumber});
  

/// Идентификатор записи.
@override final  String id;
/// Компания-владелец.
@override final  String companyId;
/// Позиция каталога.
@override final  String itemId;
/// Единица.
@override final  String? unitId;
/// Дата отправки в ремонт.
@override final  DateTime sentAt;
/// Причина.
@override final  String? reason;
/// Описание неисправности.
@override final  String? faultDescription;
/// Название ремонтной организации.
@override final  String? repairOrgName;
/// Ответственный сотрудник.
@override final  String? responsibleEmployeeId;
/// Ориентировочная стоимость.
@override final  double? estimatedCost;
/// Фактическая стоимость.
@override final  double? actualCost;
/// Дата завершения.
@override final  DateTime? completedAt;
/// Результат ремонта.
@override final  String? result;
/// Состояние после ремонта.
@override final  String? conditionAfterId;
/// Гарантия на ремонт до.
@override final  DateTime? repairWarrantyUntil;
/// Статус ремонта.
@override@JsonKey() final  TmcRepairStatus status;
/// Операция отправки.
@override final  String? sendOperationId;
/// Операция возврата.
@override final  String? returnOperationId;
/// Дата создания.
@override final  DateTime? createdAt;
/// Дата обновления.
@override final  DateTime? updatedAt;
/// Автор создания.
@override final  String? createdBy;
/// Наименование позиции (join).
@override final  String? itemName;
/// Инвентарный номер (join).
@override final  String? inventoryNumber;

/// Create a copy of TmcRepair
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TmcRepairCopyWith<_TmcRepair> get copyWith => __$TmcRepairCopyWithImpl<_TmcRepair>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TmcRepair&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.faultDescription, faultDescription) || other.faultDescription == faultDescription)&&(identical(other.repairOrgName, repairOrgName) || other.repairOrgName == repairOrgName)&&(identical(other.responsibleEmployeeId, responsibleEmployeeId) || other.responsibleEmployeeId == responsibleEmployeeId)&&(identical(other.estimatedCost, estimatedCost) || other.estimatedCost == estimatedCost)&&(identical(other.actualCost, actualCost) || other.actualCost == actualCost)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.result, result) || other.result == result)&&(identical(other.conditionAfterId, conditionAfterId) || other.conditionAfterId == conditionAfterId)&&(identical(other.repairWarrantyUntil, repairWarrantyUntil) || other.repairWarrantyUntil == repairWarrantyUntil)&&(identical(other.status, status) || other.status == status)&&(identical(other.sendOperationId, sendOperationId) || other.sendOperationId == sendOperationId)&&(identical(other.returnOperationId, returnOperationId) || other.returnOperationId == returnOperationId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.itemName, itemName) || other.itemName == itemName)&&(identical(other.inventoryNumber, inventoryNumber) || other.inventoryNumber == inventoryNumber));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,itemId,unitId,sentAt,reason,faultDescription,repairOrgName,responsibleEmployeeId,estimatedCost,actualCost,completedAt,result,conditionAfterId,repairWarrantyUntil,status,sendOperationId,returnOperationId,createdAt,updatedAt,createdBy,itemName,inventoryNumber]);

@override
String toString() {
  return 'TmcRepair(id: $id, companyId: $companyId, itemId: $itemId, unitId: $unitId, sentAt: $sentAt, reason: $reason, faultDescription: $faultDescription, repairOrgName: $repairOrgName, responsibleEmployeeId: $responsibleEmployeeId, estimatedCost: $estimatedCost, actualCost: $actualCost, completedAt: $completedAt, result: $result, conditionAfterId: $conditionAfterId, repairWarrantyUntil: $repairWarrantyUntil, status: $status, sendOperationId: $sendOperationId, returnOperationId: $returnOperationId, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, itemName: $itemName, inventoryNumber: $inventoryNumber)';
}


}

/// @nodoc
abstract mixin class _$TmcRepairCopyWith<$Res> implements $TmcRepairCopyWith<$Res> {
  factory _$TmcRepairCopyWith(_TmcRepair value, $Res Function(_TmcRepair) _then) = __$TmcRepairCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String itemId, String? unitId, DateTime sentAt, String? reason, String? faultDescription, String? repairOrgName, String? responsibleEmployeeId, double? estimatedCost, double? actualCost, DateTime? completedAt, String? result, String? conditionAfterId, DateTime? repairWarrantyUntil, TmcRepairStatus status, String? sendOperationId, String? returnOperationId, DateTime? createdAt, DateTime? updatedAt, String? createdBy, String? itemName, String? inventoryNumber
});




}
/// @nodoc
class __$TmcRepairCopyWithImpl<$Res>
    implements _$TmcRepairCopyWith<$Res> {
  __$TmcRepairCopyWithImpl(this._self, this._then);

  final _TmcRepair _self;
  final $Res Function(_TmcRepair) _then;

/// Create a copy of TmcRepair
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? itemId = null,Object? unitId = freezed,Object? sentAt = null,Object? reason = freezed,Object? faultDescription = freezed,Object? repairOrgName = freezed,Object? responsibleEmployeeId = freezed,Object? estimatedCost = freezed,Object? actualCost = freezed,Object? completedAt = freezed,Object? result = freezed,Object? conditionAfterId = freezed,Object? repairWarrantyUntil = freezed,Object? status = null,Object? sendOperationId = freezed,Object? returnOperationId = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,Object? itemName = freezed,Object? inventoryNumber = freezed,}) {
  return _then(_TmcRepair(
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
