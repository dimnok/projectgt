// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'work_plan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WorkPlan {

/// Уникальный идентификатор плана работ.
 String? get id;/// ID компании.
 String get companyId;/// Дата создания плана работ.
 DateTime get createdAt;/// Дата последнего обновления плана работ.
 DateTime get updatedAt;/// ID пользователя, создавшего план работ.
 String get createdBy;/// Дата выполнения плана работ.
 DateTime get date;/// ID объекта, для которого создается план работ.
 String get objectId;/// Название объекта (для отображения).
 String? get objectName;/// Адрес объекта (для отображения).
 String? get objectAddress;/// Список блоков работ.
 List<WorkBlock> get workBlocks;
/// Create a copy of WorkPlan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkPlanCopyWith<WorkPlan> get copyWith => _$WorkPlanCopyWithImpl<WorkPlan>(this as WorkPlan, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkPlan&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.date, date) || other.date == date)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.objectName, objectName) || other.objectName == objectName)&&(identical(other.objectAddress, objectAddress) || other.objectAddress == objectAddress)&&const DeepCollectionEquality().equals(other.workBlocks, workBlocks));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,createdAt,updatedAt,createdBy,date,objectId,objectName,objectAddress,const DeepCollectionEquality().hash(workBlocks));

@override
String toString() {
  return 'WorkPlan(id: $id, companyId: $companyId, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, date: $date, objectId: $objectId, objectName: $objectName, objectAddress: $objectAddress, workBlocks: $workBlocks)';
}


}

/// @nodoc
abstract mixin class $WorkPlanCopyWith<$Res>  {
  factory $WorkPlanCopyWith(WorkPlan value, $Res Function(WorkPlan) _then) = _$WorkPlanCopyWithImpl;
@useResult
$Res call({
 String? id, String companyId, DateTime createdAt, DateTime updatedAt, String createdBy, DateTime date, String objectId, String? objectName, String? objectAddress, List<WorkBlock> workBlocks
});




}
/// @nodoc
class _$WorkPlanCopyWithImpl<$Res>
    implements $WorkPlanCopyWith<$Res> {
  _$WorkPlanCopyWithImpl(this._self, this._then);

  final WorkPlan _self;
  final $Res Function(WorkPlan) _then;

/// Create a copy of WorkPlan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? companyId = null,Object? createdAt = null,Object? updatedAt = null,Object? createdBy = null,Object? date = null,Object? objectId = null,Object? objectName = freezed,Object? objectAddress = freezed,Object? workBlocks = null,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,objectId: null == objectId ? _self.objectId : objectId // ignore: cast_nullable_to_non_nullable
as String,objectName: freezed == objectName ? _self.objectName : objectName // ignore: cast_nullable_to_non_nullable
as String?,objectAddress: freezed == objectAddress ? _self.objectAddress : objectAddress // ignore: cast_nullable_to_non_nullable
as String?,workBlocks: null == workBlocks ? _self.workBlocks : workBlocks // ignore: cast_nullable_to_non_nullable
as List<WorkBlock>,
  ));
}

}


/// @nodoc


class _WorkPlan extends WorkPlan {
  const _WorkPlan({this.id, required this.companyId, required this.createdAt, required this.updatedAt, required this.createdBy, required this.date, required this.objectId, this.objectName, this.objectAddress, final  List<WorkBlock> workBlocks = const []}): _workBlocks = workBlocks,super._();
  

/// Уникальный идентификатор плана работ.
@override final  String? id;
/// ID компании.
@override final  String companyId;
/// Дата создания плана работ.
@override final  DateTime createdAt;
/// Дата последнего обновления плана работ.
@override final  DateTime updatedAt;
/// ID пользователя, создавшего план работ.
@override final  String createdBy;
/// Дата выполнения плана работ.
@override final  DateTime date;
/// ID объекта, для которого создается план работ.
@override final  String objectId;
/// Название объекта (для отображения).
@override final  String? objectName;
/// Адрес объекта (для отображения).
@override final  String? objectAddress;
/// Список блоков работ.
 final  List<WorkBlock> _workBlocks;
/// Список блоков работ.
@override@JsonKey() List<WorkBlock> get workBlocks {
  if (_workBlocks is EqualUnmodifiableListView) return _workBlocks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_workBlocks);
}


/// Create a copy of WorkPlan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkPlanCopyWith<_WorkPlan> get copyWith => __$WorkPlanCopyWithImpl<_WorkPlan>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkPlan&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.date, date) || other.date == date)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.objectName, objectName) || other.objectName == objectName)&&(identical(other.objectAddress, objectAddress) || other.objectAddress == objectAddress)&&const DeepCollectionEquality().equals(other._workBlocks, _workBlocks));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,createdAt,updatedAt,createdBy,date,objectId,objectName,objectAddress,const DeepCollectionEquality().hash(_workBlocks));

@override
String toString() {
  return 'WorkPlan(id: $id, companyId: $companyId, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, date: $date, objectId: $objectId, objectName: $objectName, objectAddress: $objectAddress, workBlocks: $workBlocks)';
}


}

/// @nodoc
abstract mixin class _$WorkPlanCopyWith<$Res> implements $WorkPlanCopyWith<$Res> {
  factory _$WorkPlanCopyWith(_WorkPlan value, $Res Function(_WorkPlan) _then) = __$WorkPlanCopyWithImpl;
@override @useResult
$Res call({
 String? id, String companyId, DateTime createdAt, DateTime updatedAt, String createdBy, DateTime date, String objectId, String? objectName, String? objectAddress, List<WorkBlock> workBlocks
});




}
/// @nodoc
class __$WorkPlanCopyWithImpl<$Res>
    implements _$WorkPlanCopyWith<$Res> {
  __$WorkPlanCopyWithImpl(this._self, this._then);

  final _WorkPlan _self;
  final $Res Function(_WorkPlan) _then;

/// Create a copy of WorkPlan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? companyId = null,Object? createdAt = null,Object? updatedAt = null,Object? createdBy = null,Object? date = null,Object? objectId = null,Object? objectName = freezed,Object? objectAddress = freezed,Object? workBlocks = null,}) {
  return _then(_WorkPlan(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,objectId: null == objectId ? _self.objectId : objectId // ignore: cast_nullable_to_non_nullable
as String,objectName: freezed == objectName ? _self.objectName : objectName // ignore: cast_nullable_to_non_nullable
as String?,objectAddress: freezed == objectAddress ? _self.objectAddress : objectAddress // ignore: cast_nullable_to_non_nullable
as String?,workBlocks: null == workBlocks ? _self._workBlocks : workBlocks // ignore: cast_nullable_to_non_nullable
as List<WorkBlock>,
  ));
}


}

/// @nodoc
mixin _$WorkBlock {

/// Уникальный идентификатор блока работ.
 String? get id;/// ID компании.
 String get companyId;/// ID ответственного сотрудника за блок.
 String? get responsibleId;/// Список ID работников, назначенных на блок.
 List<String> get workerIds;/// Участок объекта для данного блока.
 String? get section;/// Этаж объекта для данного блока.
 String? get floor;/// Система работ (обязательное поле).
 String get system;/// Список работ в блоке с объемами.
 List<WorkPlanItem> get selectedWorks;
/// Create a copy of WorkBlock
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkBlockCopyWith<WorkBlock> get copyWith => _$WorkBlockCopyWithImpl<WorkBlock>(this as WorkBlock, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkBlock&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.responsibleId, responsibleId) || other.responsibleId == responsibleId)&&const DeepCollectionEquality().equals(other.workerIds, workerIds)&&(identical(other.section, section) || other.section == section)&&(identical(other.floor, floor) || other.floor == floor)&&(identical(other.system, system) || other.system == system)&&const DeepCollectionEquality().equals(other.selectedWorks, selectedWorks));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,responsibleId,const DeepCollectionEquality().hash(workerIds),section,floor,system,const DeepCollectionEquality().hash(selectedWorks));

@override
String toString() {
  return 'WorkBlock(id: $id, companyId: $companyId, responsibleId: $responsibleId, workerIds: $workerIds, section: $section, floor: $floor, system: $system, selectedWorks: $selectedWorks)';
}


}

/// @nodoc
abstract mixin class $WorkBlockCopyWith<$Res>  {
  factory $WorkBlockCopyWith(WorkBlock value, $Res Function(WorkBlock) _then) = _$WorkBlockCopyWithImpl;
@useResult
$Res call({
 String? id, String companyId, String? responsibleId, List<String> workerIds, String? section, String? floor, String system, List<WorkPlanItem> selectedWorks
});




}
/// @nodoc
class _$WorkBlockCopyWithImpl<$Res>
    implements $WorkBlockCopyWith<$Res> {
  _$WorkBlockCopyWithImpl(this._self, this._then);

  final WorkBlock _self;
  final $Res Function(WorkBlock) _then;

/// Create a copy of WorkBlock
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? companyId = null,Object? responsibleId = freezed,Object? workerIds = null,Object? section = freezed,Object? floor = freezed,Object? system = null,Object? selectedWorks = null,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,responsibleId: freezed == responsibleId ? _self.responsibleId : responsibleId // ignore: cast_nullable_to_non_nullable
as String?,workerIds: null == workerIds ? _self.workerIds : workerIds // ignore: cast_nullable_to_non_nullable
as List<String>,section: freezed == section ? _self.section : section // ignore: cast_nullable_to_non_nullable
as String?,floor: freezed == floor ? _self.floor : floor // ignore: cast_nullable_to_non_nullable
as String?,system: null == system ? _self.system : system // ignore: cast_nullable_to_non_nullable
as String,selectedWorks: null == selectedWorks ? _self.selectedWorks : selectedWorks // ignore: cast_nullable_to_non_nullable
as List<WorkPlanItem>,
  ));
}

}


/// @nodoc


class _WorkBlock extends WorkBlock {
  const _WorkBlock({this.id, required this.companyId, this.responsibleId, final  List<String> workerIds = const [], this.section, this.floor, required this.system, final  List<WorkPlanItem> selectedWorks = const []}): _workerIds = workerIds,_selectedWorks = selectedWorks,super._();
  

/// Уникальный идентификатор блока работ.
@override final  String? id;
/// ID компании.
@override final  String companyId;
/// ID ответственного сотрудника за блок.
@override final  String? responsibleId;
/// Список ID работников, назначенных на блок.
 final  List<String> _workerIds;
/// Список ID работников, назначенных на блок.
@override@JsonKey() List<String> get workerIds {
  if (_workerIds is EqualUnmodifiableListView) return _workerIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_workerIds);
}

/// Участок объекта для данного блока.
@override final  String? section;
/// Этаж объекта для данного блока.
@override final  String? floor;
/// Система работ (обязательное поле).
@override final  String system;
/// Список работ в блоке с объемами.
 final  List<WorkPlanItem> _selectedWorks;
/// Список работ в блоке с объемами.
@override@JsonKey() List<WorkPlanItem> get selectedWorks {
  if (_selectedWorks is EqualUnmodifiableListView) return _selectedWorks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selectedWorks);
}


/// Create a copy of WorkBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkBlockCopyWith<_WorkBlock> get copyWith => __$WorkBlockCopyWithImpl<_WorkBlock>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkBlock&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.responsibleId, responsibleId) || other.responsibleId == responsibleId)&&const DeepCollectionEquality().equals(other._workerIds, _workerIds)&&(identical(other.section, section) || other.section == section)&&(identical(other.floor, floor) || other.floor == floor)&&(identical(other.system, system) || other.system == system)&&const DeepCollectionEquality().equals(other._selectedWorks, _selectedWorks));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,responsibleId,const DeepCollectionEquality().hash(_workerIds),section,floor,system,const DeepCollectionEquality().hash(_selectedWorks));

@override
String toString() {
  return 'WorkBlock(id: $id, companyId: $companyId, responsibleId: $responsibleId, workerIds: $workerIds, section: $section, floor: $floor, system: $system, selectedWorks: $selectedWorks)';
}


}

/// @nodoc
abstract mixin class _$WorkBlockCopyWith<$Res> implements $WorkBlockCopyWith<$Res> {
  factory _$WorkBlockCopyWith(_WorkBlock value, $Res Function(_WorkBlock) _then) = __$WorkBlockCopyWithImpl;
@override @useResult
$Res call({
 String? id, String companyId, String? responsibleId, List<String> workerIds, String? section, String? floor, String system, List<WorkPlanItem> selectedWorks
});




}
/// @nodoc
class __$WorkBlockCopyWithImpl<$Res>
    implements _$WorkBlockCopyWith<$Res> {
  __$WorkBlockCopyWithImpl(this._self, this._then);

  final _WorkBlock _self;
  final $Res Function(_WorkBlock) _then;

/// Create a copy of WorkBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? companyId = null,Object? responsibleId = freezed,Object? workerIds = null,Object? section = freezed,Object? floor = freezed,Object? system = null,Object? selectedWorks = null,}) {
  return _then(_WorkBlock(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,responsibleId: freezed == responsibleId ? _self.responsibleId : responsibleId // ignore: cast_nullable_to_non_nullable
as String?,workerIds: null == workerIds ? _self._workerIds : workerIds // ignore: cast_nullable_to_non_nullable
as List<String>,section: freezed == section ? _self.section : section // ignore: cast_nullable_to_non_nullable
as String?,floor: freezed == floor ? _self.floor : floor // ignore: cast_nullable_to_non_nullable
as String?,system: null == system ? _self.system : system // ignore: cast_nullable_to_non_nullable
as String,selectedWorks: null == selectedWorks ? _self._selectedWorks : selectedWorks // ignore: cast_nullable_to_non_nullable
as List<WorkPlanItem>,
  ));
}


}

/// @nodoc
mixin _$WorkPlanItem {

/// ID компании.
 String get companyId;/// ID работы из таблицы estimates.
 String get estimateId;/// Название работы.
 String get name;/// Единица измерения.
 String get unit;/// Цена за единицу.
 double get price;/// Запланированное количество.
 double get plannedQuantity;/// Фактическое выполненное количество.
 double get actualQuantity;
/// Create a copy of WorkPlanItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkPlanItemCopyWith<WorkPlanItem> get copyWith => _$WorkPlanItemCopyWithImpl<WorkPlanItem>(this as WorkPlanItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkPlanItem&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.estimateId, estimateId) || other.estimateId == estimateId)&&(identical(other.name, name) || other.name == name)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.price, price) || other.price == price)&&(identical(other.plannedQuantity, plannedQuantity) || other.plannedQuantity == plannedQuantity)&&(identical(other.actualQuantity, actualQuantity) || other.actualQuantity == actualQuantity));
}


@override
int get hashCode => Object.hash(runtimeType,companyId,estimateId,name,unit,price,plannedQuantity,actualQuantity);

@override
String toString() {
  return 'WorkPlanItem(companyId: $companyId, estimateId: $estimateId, name: $name, unit: $unit, price: $price, plannedQuantity: $plannedQuantity, actualQuantity: $actualQuantity)';
}


}

/// @nodoc
abstract mixin class $WorkPlanItemCopyWith<$Res>  {
  factory $WorkPlanItemCopyWith(WorkPlanItem value, $Res Function(WorkPlanItem) _then) = _$WorkPlanItemCopyWithImpl;
@useResult
$Res call({
 String companyId, String estimateId, String name, String unit, double price, double plannedQuantity, double actualQuantity
});




}
/// @nodoc
class _$WorkPlanItemCopyWithImpl<$Res>
    implements $WorkPlanItemCopyWith<$Res> {
  _$WorkPlanItemCopyWithImpl(this._self, this._then);

  final WorkPlanItem _self;
  final $Res Function(WorkPlanItem) _then;

/// Create a copy of WorkPlanItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? companyId = null,Object? estimateId = null,Object? name = null,Object? unit = null,Object? price = null,Object? plannedQuantity = null,Object? actualQuantity = null,}) {
  return _then(_self.copyWith(
companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,estimateId: null == estimateId ? _self.estimateId : estimateId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,plannedQuantity: null == plannedQuantity ? _self.plannedQuantity : plannedQuantity // ignore: cast_nullable_to_non_nullable
as double,actualQuantity: null == actualQuantity ? _self.actualQuantity : actualQuantity // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// @nodoc


class _WorkPlanItem extends WorkPlanItem {
  const _WorkPlanItem({required this.companyId, required this.estimateId, required this.name, required this.unit, required this.price, this.plannedQuantity = 0, this.actualQuantity = 0}): super._();
  

/// ID компании.
@override final  String companyId;
/// ID работы из таблицы estimates.
@override final  String estimateId;
/// Название работы.
@override final  String name;
/// Единица измерения.
@override final  String unit;
/// Цена за единицу.
@override final  double price;
/// Запланированное количество.
@override@JsonKey() final  double plannedQuantity;
/// Фактическое выполненное количество.
@override@JsonKey() final  double actualQuantity;

/// Create a copy of WorkPlanItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkPlanItemCopyWith<_WorkPlanItem> get copyWith => __$WorkPlanItemCopyWithImpl<_WorkPlanItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkPlanItem&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.estimateId, estimateId) || other.estimateId == estimateId)&&(identical(other.name, name) || other.name == name)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.price, price) || other.price == price)&&(identical(other.plannedQuantity, plannedQuantity) || other.plannedQuantity == plannedQuantity)&&(identical(other.actualQuantity, actualQuantity) || other.actualQuantity == actualQuantity));
}


@override
int get hashCode => Object.hash(runtimeType,companyId,estimateId,name,unit,price,plannedQuantity,actualQuantity);

@override
String toString() {
  return 'WorkPlanItem(companyId: $companyId, estimateId: $estimateId, name: $name, unit: $unit, price: $price, plannedQuantity: $plannedQuantity, actualQuantity: $actualQuantity)';
}


}

/// @nodoc
abstract mixin class _$WorkPlanItemCopyWith<$Res> implements $WorkPlanItemCopyWith<$Res> {
  factory _$WorkPlanItemCopyWith(_WorkPlanItem value, $Res Function(_WorkPlanItem) _then) = __$WorkPlanItemCopyWithImpl;
@override @useResult
$Res call({
 String companyId, String estimateId, String name, String unit, double price, double plannedQuantity, double actualQuantity
});




}
/// @nodoc
class __$WorkPlanItemCopyWithImpl<$Res>
    implements _$WorkPlanItemCopyWith<$Res> {
  __$WorkPlanItemCopyWithImpl(this._self, this._then);

  final _WorkPlanItem _self;
  final $Res Function(_WorkPlanItem) _then;

/// Create a copy of WorkPlanItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? companyId = null,Object? estimateId = null,Object? name = null,Object? unit = null,Object? price = null,Object? plannedQuantity = null,Object? actualQuantity = null,}) {
  return _then(_WorkPlanItem(
companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,estimateId: null == estimateId ? _self.estimateId : estimateId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,plannedQuantity: null == plannedQuantity ? _self.plannedQuantity : plannedQuantity // ignore: cast_nullable_to_non_nullable
as double,actualQuantity: null == actualQuantity ? _self.actualQuantity : actualQuantity // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
