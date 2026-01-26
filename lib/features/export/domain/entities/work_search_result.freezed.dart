// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'work_search_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WorkSearchResult {

/// Дата смены.
 DateTime get workDate;/// Название объекта.
 String get objectName;/// Система.
 String get system;/// Подсистема.
 String get subsystem;/// Секция (модуль).
 String get section;/// Этаж.
 String get floor;/// Наименование работы.
 String get workName;/// Наименование работы (для совместимости с интерфейсом).
 String get materialName;/// Единица измерения.
 String get unit;/// Количество.
 num get quantity;/// Идентификатор записи work_item.
 String? get workItemId;/// Идентификатор смены.
 String? get workId;/// Идентификатор объекта.
 String? get objectId;/// Статус смены (open/closed).
 String? get workStatus;/// Идентификатор сметы.
 String? get estimateId;/// Цена за единицу.
 double? get price;/// Итоговая сумма.
 double? get total;/// Номер позиции в смете.
 String? get positionNumber;/// Номер договора.
 String? get contractNumber;/// Наименование по М-15 (из накладных).
 String? get m15Name;
/// Create a copy of WorkSearchResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkSearchResultCopyWith<WorkSearchResult> get copyWith => _$WorkSearchResultCopyWithImpl<WorkSearchResult>(this as WorkSearchResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkSearchResult&&(identical(other.workDate, workDate) || other.workDate == workDate)&&(identical(other.objectName, objectName) || other.objectName == objectName)&&(identical(other.system, system) || other.system == system)&&(identical(other.subsystem, subsystem) || other.subsystem == subsystem)&&(identical(other.section, section) || other.section == section)&&(identical(other.floor, floor) || other.floor == floor)&&(identical(other.workName, workName) || other.workName == workName)&&(identical(other.materialName, materialName) || other.materialName == materialName)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.workItemId, workItemId) || other.workItemId == workItemId)&&(identical(other.workId, workId) || other.workId == workId)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.workStatus, workStatus) || other.workStatus == workStatus)&&(identical(other.estimateId, estimateId) || other.estimateId == estimateId)&&(identical(other.price, price) || other.price == price)&&(identical(other.total, total) || other.total == total)&&(identical(other.positionNumber, positionNumber) || other.positionNumber == positionNumber)&&(identical(other.contractNumber, contractNumber) || other.contractNumber == contractNumber)&&(identical(other.m15Name, m15Name) || other.m15Name == m15Name));
}


@override
int get hashCode => Object.hashAll([runtimeType,workDate,objectName,system,subsystem,section,floor,workName,materialName,unit,quantity,workItemId,workId,objectId,workStatus,estimateId,price,total,positionNumber,contractNumber,m15Name]);

@override
String toString() {
  return 'WorkSearchResult(workDate: $workDate, objectName: $objectName, system: $system, subsystem: $subsystem, section: $section, floor: $floor, workName: $workName, materialName: $materialName, unit: $unit, quantity: $quantity, workItemId: $workItemId, workId: $workId, objectId: $objectId, workStatus: $workStatus, estimateId: $estimateId, price: $price, total: $total, positionNumber: $positionNumber, contractNumber: $contractNumber, m15Name: $m15Name)';
}


}

/// @nodoc
abstract mixin class $WorkSearchResultCopyWith<$Res>  {
  factory $WorkSearchResultCopyWith(WorkSearchResult value, $Res Function(WorkSearchResult) _then) = _$WorkSearchResultCopyWithImpl;
@useResult
$Res call({
 DateTime workDate, String objectName, String system, String subsystem, String section, String floor, String workName, String materialName, String unit, num quantity, String? workItemId, String? workId, String? objectId, String? workStatus, String? estimateId, double? price, double? total, String? positionNumber, String? contractNumber, String? m15Name
});




}
/// @nodoc
class _$WorkSearchResultCopyWithImpl<$Res>
    implements $WorkSearchResultCopyWith<$Res> {
  _$WorkSearchResultCopyWithImpl(this._self, this._then);

  final WorkSearchResult _self;
  final $Res Function(WorkSearchResult) _then;

/// Create a copy of WorkSearchResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? workDate = null,Object? objectName = null,Object? system = null,Object? subsystem = null,Object? section = null,Object? floor = null,Object? workName = null,Object? materialName = null,Object? unit = null,Object? quantity = null,Object? workItemId = freezed,Object? workId = freezed,Object? objectId = freezed,Object? workStatus = freezed,Object? estimateId = freezed,Object? price = freezed,Object? total = freezed,Object? positionNumber = freezed,Object? contractNumber = freezed,Object? m15Name = freezed,}) {
  return _then(_self.copyWith(
workDate: null == workDate ? _self.workDate : workDate // ignore: cast_nullable_to_non_nullable
as DateTime,objectName: null == objectName ? _self.objectName : objectName // ignore: cast_nullable_to_non_nullable
as String,system: null == system ? _self.system : system // ignore: cast_nullable_to_non_nullable
as String,subsystem: null == subsystem ? _self.subsystem : subsystem // ignore: cast_nullable_to_non_nullable
as String,section: null == section ? _self.section : section // ignore: cast_nullable_to_non_nullable
as String,floor: null == floor ? _self.floor : floor // ignore: cast_nullable_to_non_nullable
as String,workName: null == workName ? _self.workName : workName // ignore: cast_nullable_to_non_nullable
as String,materialName: null == materialName ? _self.materialName : materialName // ignore: cast_nullable_to_non_nullable
as String,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as num,workItemId: freezed == workItemId ? _self.workItemId : workItemId // ignore: cast_nullable_to_non_nullable
as String?,workId: freezed == workId ? _self.workId : workId // ignore: cast_nullable_to_non_nullable
as String?,objectId: freezed == objectId ? _self.objectId : objectId // ignore: cast_nullable_to_non_nullable
as String?,workStatus: freezed == workStatus ? _self.workStatus : workStatus // ignore: cast_nullable_to_non_nullable
as String?,estimateId: freezed == estimateId ? _self.estimateId : estimateId // ignore: cast_nullable_to_non_nullable
as String?,price: freezed == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double?,total: freezed == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as double?,positionNumber: freezed == positionNumber ? _self.positionNumber : positionNumber // ignore: cast_nullable_to_non_nullable
as String?,contractNumber: freezed == contractNumber ? _self.contractNumber : contractNumber // ignore: cast_nullable_to_non_nullable
as String?,m15Name: freezed == m15Name ? _self.m15Name : m15Name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc


class _WorkSearchResult implements WorkSearchResult {
  const _WorkSearchResult({required this.workDate, required this.objectName, required this.system, required this.subsystem, required this.section, required this.floor, required this.workName, required this.materialName, required this.unit, required this.quantity, this.workItemId, this.workId, this.objectId, this.workStatus, this.estimateId, this.price, this.total, this.positionNumber, this.contractNumber, this.m15Name});
  

/// Дата смены.
@override final  DateTime workDate;
/// Название объекта.
@override final  String objectName;
/// Система.
@override final  String system;
/// Подсистема.
@override final  String subsystem;
/// Секция (модуль).
@override final  String section;
/// Этаж.
@override final  String floor;
/// Наименование работы.
@override final  String workName;
/// Наименование работы (для совместимости с интерфейсом).
@override final  String materialName;
/// Единица измерения.
@override final  String unit;
/// Количество.
@override final  num quantity;
/// Идентификатор записи work_item.
@override final  String? workItemId;
/// Идентификатор смены.
@override final  String? workId;
/// Идентификатор объекта.
@override final  String? objectId;
/// Статус смены (open/closed).
@override final  String? workStatus;
/// Идентификатор сметы.
@override final  String? estimateId;
/// Цена за единицу.
@override final  double? price;
/// Итоговая сумма.
@override final  double? total;
/// Номер позиции в смете.
@override final  String? positionNumber;
/// Номер договора.
@override final  String? contractNumber;
/// Наименование по М-15 (из накладных).
@override final  String? m15Name;

/// Create a copy of WorkSearchResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkSearchResultCopyWith<_WorkSearchResult> get copyWith => __$WorkSearchResultCopyWithImpl<_WorkSearchResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkSearchResult&&(identical(other.workDate, workDate) || other.workDate == workDate)&&(identical(other.objectName, objectName) || other.objectName == objectName)&&(identical(other.system, system) || other.system == system)&&(identical(other.subsystem, subsystem) || other.subsystem == subsystem)&&(identical(other.section, section) || other.section == section)&&(identical(other.floor, floor) || other.floor == floor)&&(identical(other.workName, workName) || other.workName == workName)&&(identical(other.materialName, materialName) || other.materialName == materialName)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.workItemId, workItemId) || other.workItemId == workItemId)&&(identical(other.workId, workId) || other.workId == workId)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.workStatus, workStatus) || other.workStatus == workStatus)&&(identical(other.estimateId, estimateId) || other.estimateId == estimateId)&&(identical(other.price, price) || other.price == price)&&(identical(other.total, total) || other.total == total)&&(identical(other.positionNumber, positionNumber) || other.positionNumber == positionNumber)&&(identical(other.contractNumber, contractNumber) || other.contractNumber == contractNumber)&&(identical(other.m15Name, m15Name) || other.m15Name == m15Name));
}


@override
int get hashCode => Object.hashAll([runtimeType,workDate,objectName,system,subsystem,section,floor,workName,materialName,unit,quantity,workItemId,workId,objectId,workStatus,estimateId,price,total,positionNumber,contractNumber,m15Name]);

@override
String toString() {
  return 'WorkSearchResult(workDate: $workDate, objectName: $objectName, system: $system, subsystem: $subsystem, section: $section, floor: $floor, workName: $workName, materialName: $materialName, unit: $unit, quantity: $quantity, workItemId: $workItemId, workId: $workId, objectId: $objectId, workStatus: $workStatus, estimateId: $estimateId, price: $price, total: $total, positionNumber: $positionNumber, contractNumber: $contractNumber, m15Name: $m15Name)';
}


}

/// @nodoc
abstract mixin class _$WorkSearchResultCopyWith<$Res> implements $WorkSearchResultCopyWith<$Res> {
  factory _$WorkSearchResultCopyWith(_WorkSearchResult value, $Res Function(_WorkSearchResult) _then) = __$WorkSearchResultCopyWithImpl;
@override @useResult
$Res call({
 DateTime workDate, String objectName, String system, String subsystem, String section, String floor, String workName, String materialName, String unit, num quantity, String? workItemId, String? workId, String? objectId, String? workStatus, String? estimateId, double? price, double? total, String? positionNumber, String? contractNumber, String? m15Name
});




}
/// @nodoc
class __$WorkSearchResultCopyWithImpl<$Res>
    implements _$WorkSearchResultCopyWith<$Res> {
  __$WorkSearchResultCopyWithImpl(this._self, this._then);

  final _WorkSearchResult _self;
  final $Res Function(_WorkSearchResult) _then;

/// Create a copy of WorkSearchResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? workDate = null,Object? objectName = null,Object? system = null,Object? subsystem = null,Object? section = null,Object? floor = null,Object? workName = null,Object? materialName = null,Object? unit = null,Object? quantity = null,Object? workItemId = freezed,Object? workId = freezed,Object? objectId = freezed,Object? workStatus = freezed,Object? estimateId = freezed,Object? price = freezed,Object? total = freezed,Object? positionNumber = freezed,Object? contractNumber = freezed,Object? m15Name = freezed,}) {
  return _then(_WorkSearchResult(
workDate: null == workDate ? _self.workDate : workDate // ignore: cast_nullable_to_non_nullable
as DateTime,objectName: null == objectName ? _self.objectName : objectName // ignore: cast_nullable_to_non_nullable
as String,system: null == system ? _self.system : system // ignore: cast_nullable_to_non_nullable
as String,subsystem: null == subsystem ? _self.subsystem : subsystem // ignore: cast_nullable_to_non_nullable
as String,section: null == section ? _self.section : section // ignore: cast_nullable_to_non_nullable
as String,floor: null == floor ? _self.floor : floor // ignore: cast_nullable_to_non_nullable
as String,workName: null == workName ? _self.workName : workName // ignore: cast_nullable_to_non_nullable
as String,materialName: null == materialName ? _self.materialName : materialName // ignore: cast_nullable_to_non_nullable
as String,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as num,workItemId: freezed == workItemId ? _self.workItemId : workItemId // ignore: cast_nullable_to_non_nullable
as String?,workId: freezed == workId ? _self.workId : workId // ignore: cast_nullable_to_non_nullable
as String?,objectId: freezed == objectId ? _self.objectId : objectId // ignore: cast_nullable_to_non_nullable
as String?,workStatus: freezed == workStatus ? _self.workStatus : workStatus // ignore: cast_nullable_to_non_nullable
as String?,estimateId: freezed == estimateId ? _self.estimateId : estimateId // ignore: cast_nullable_to_non_nullable
as String?,price: freezed == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double?,total: freezed == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as double?,positionNumber: freezed == positionNumber ? _self.positionNumber : positionNumber // ignore: cast_nullable_to_non_nullable
as String?,contractNumber: freezed == contractNumber ? _self.contractNumber : contractNumber // ignore: cast_nullable_to_non_nullable
as String?,m15Name: freezed == m15Name ? _self.m15Name : m15Name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
