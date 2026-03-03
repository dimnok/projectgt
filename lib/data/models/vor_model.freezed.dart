// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vor_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VorModel {

/// Идентификатор ведомости.
 String get id;/// Идентификатор компании.
@JsonKey(name: 'company_id') String get companyId;/// Идентификатор договора.
@JsonKey(name: 'contract_id') String get contractId;/// Порядковый номер ведомости.
 String get number;/// Дата начала периода работ.
@JsonKey(name: 'start_date') DateTime get startDate;/// Дата окончания периода работ.
@JsonKey(name: 'end_date') DateTime get endDate;/// Текущий статус ведомости.
 VorStatus get status;/// Путь к Excel файлу.
@JsonKey(name: 'excel_url') String? get excelUrl;/// Путь к PDF файлу.
@JsonKey(name: 'pdf_url') String? get pdfUrl;/// Дата создания.
@JsonKey(name: 'created_at') DateTime get createdAt;/// Кто создал (ID пользователя).
@JsonKey(name: 'created_by') String? get createdBy;/// ФИО создателя (опционально, подтягивается через join).
@JsonKey(includeFromJson: false, includeToJson: false) String? get createdByName;/// Список выбранных систем.
 List<String> get systems;/// История изменений статусов.
 List<VorStatusHistoryModel> get statusHistory;
/// Create a copy of VorModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VorModelCopyWith<VorModel> get copyWith => _$VorModelCopyWithImpl<VorModel>(this as VorModel, _$identity);

  /// Serializes this VorModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VorModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.number, number) || other.number == number)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.excelUrl, excelUrl) || other.excelUrl == excelUrl)&&(identical(other.pdfUrl, pdfUrl) || other.pdfUrl == pdfUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdByName, createdByName) || other.createdByName == createdByName)&&const DeepCollectionEquality().equals(other.systems, systems)&&const DeepCollectionEquality().equals(other.statusHistory, statusHistory));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,contractId,number,startDate,endDate,status,excelUrl,pdfUrl,createdAt,createdBy,createdByName,const DeepCollectionEquality().hash(systems),const DeepCollectionEquality().hash(statusHistory));

@override
String toString() {
  return 'VorModel(id: $id, companyId: $companyId, contractId: $contractId, number: $number, startDate: $startDate, endDate: $endDate, status: $status, excelUrl: $excelUrl, pdfUrl: $pdfUrl, createdAt: $createdAt, createdBy: $createdBy, createdByName: $createdByName, systems: $systems, statusHistory: $statusHistory)';
}


}

/// @nodoc
abstract mixin class $VorModelCopyWith<$Res>  {
  factory $VorModelCopyWith(VorModel value, $Res Function(VorModel) _then) = _$VorModelCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'company_id') String companyId,@JsonKey(name: 'contract_id') String contractId, String number,@JsonKey(name: 'start_date') DateTime startDate,@JsonKey(name: 'end_date') DateTime endDate, VorStatus status,@JsonKey(name: 'excel_url') String? excelUrl,@JsonKey(name: 'pdf_url') String? pdfUrl,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'created_by') String? createdBy,@JsonKey(includeFromJson: false, includeToJson: false) String? createdByName, List<String> systems, List<VorStatusHistoryModel> statusHistory
});




}
/// @nodoc
class _$VorModelCopyWithImpl<$Res>
    implements $VorModelCopyWith<$Res> {
  _$VorModelCopyWithImpl(this._self, this._then);

  final VorModel _self;
  final $Res Function(VorModel) _then;

/// Create a copy of VorModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? contractId = null,Object? number = null,Object? startDate = null,Object? endDate = null,Object? status = null,Object? excelUrl = freezed,Object? pdfUrl = freezed,Object? createdAt = null,Object? createdBy = freezed,Object? createdByName = freezed,Object? systems = null,Object? statusHistory = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,contractId: null == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as VorStatus,excelUrl: freezed == excelUrl ? _self.excelUrl : excelUrl // ignore: cast_nullable_to_non_nullable
as String?,pdfUrl: freezed == pdfUrl ? _self.pdfUrl : pdfUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,createdByName: freezed == createdByName ? _self.createdByName : createdByName // ignore: cast_nullable_to_non_nullable
as String?,systems: null == systems ? _self.systems : systems // ignore: cast_nullable_to_non_nullable
as List<String>,statusHistory: null == statusHistory ? _self.statusHistory : statusHistory // ignore: cast_nullable_to_non_nullable
as List<VorStatusHistoryModel>,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _VorModel extends VorModel {
  const _VorModel({required this.id, @JsonKey(name: 'company_id') required this.companyId, @JsonKey(name: 'contract_id') required this.contractId, required this.number, @JsonKey(name: 'start_date') required this.startDate, @JsonKey(name: 'end_date') required this.endDate, required this.status, @JsonKey(name: 'excel_url') this.excelUrl, @JsonKey(name: 'pdf_url') this.pdfUrl, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'created_by') this.createdBy, @JsonKey(includeFromJson: false, includeToJson: false) this.createdByName, final  List<String> systems = const [], final  List<VorStatusHistoryModel> statusHistory = const []}): _systems = systems,_statusHistory = statusHistory,super._();
  factory _VorModel.fromJson(Map<String, dynamic> json) => _$VorModelFromJson(json);

/// Идентификатор ведомости.
@override final  String id;
/// Идентификатор компании.
@override@JsonKey(name: 'company_id') final  String companyId;
/// Идентификатор договора.
@override@JsonKey(name: 'contract_id') final  String contractId;
/// Порядковый номер ведомости.
@override final  String number;
/// Дата начала периода работ.
@override@JsonKey(name: 'start_date') final  DateTime startDate;
/// Дата окончания периода работ.
@override@JsonKey(name: 'end_date') final  DateTime endDate;
/// Текущий статус ведомости.
@override final  VorStatus status;
/// Путь к Excel файлу.
@override@JsonKey(name: 'excel_url') final  String? excelUrl;
/// Путь к PDF файлу.
@override@JsonKey(name: 'pdf_url') final  String? pdfUrl;
/// Дата создания.
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
/// Кто создал (ID пользователя).
@override@JsonKey(name: 'created_by') final  String? createdBy;
/// ФИО создателя (опционально, подтягивается через join).
@override@JsonKey(includeFromJson: false, includeToJson: false) final  String? createdByName;
/// Список выбранных систем.
 final  List<String> _systems;
/// Список выбранных систем.
@override@JsonKey() List<String> get systems {
  if (_systems is EqualUnmodifiableListView) return _systems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_systems);
}

/// История изменений статусов.
 final  List<VorStatusHistoryModel> _statusHistory;
/// История изменений статусов.
@override@JsonKey() List<VorStatusHistoryModel> get statusHistory {
  if (_statusHistory is EqualUnmodifiableListView) return _statusHistory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_statusHistory);
}


/// Create a copy of VorModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VorModelCopyWith<_VorModel> get copyWith => __$VorModelCopyWithImpl<_VorModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VorModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VorModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.number, number) || other.number == number)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.excelUrl, excelUrl) || other.excelUrl == excelUrl)&&(identical(other.pdfUrl, pdfUrl) || other.pdfUrl == pdfUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdByName, createdByName) || other.createdByName == createdByName)&&const DeepCollectionEquality().equals(other._systems, _systems)&&const DeepCollectionEquality().equals(other._statusHistory, _statusHistory));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,contractId,number,startDate,endDate,status,excelUrl,pdfUrl,createdAt,createdBy,createdByName,const DeepCollectionEquality().hash(_systems),const DeepCollectionEquality().hash(_statusHistory));

@override
String toString() {
  return 'VorModel(id: $id, companyId: $companyId, contractId: $contractId, number: $number, startDate: $startDate, endDate: $endDate, status: $status, excelUrl: $excelUrl, pdfUrl: $pdfUrl, createdAt: $createdAt, createdBy: $createdBy, createdByName: $createdByName, systems: $systems, statusHistory: $statusHistory)';
}


}

/// @nodoc
abstract mixin class _$VorModelCopyWith<$Res> implements $VorModelCopyWith<$Res> {
  factory _$VorModelCopyWith(_VorModel value, $Res Function(_VorModel) _then) = __$VorModelCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'company_id') String companyId,@JsonKey(name: 'contract_id') String contractId, String number,@JsonKey(name: 'start_date') DateTime startDate,@JsonKey(name: 'end_date') DateTime endDate, VorStatus status,@JsonKey(name: 'excel_url') String? excelUrl,@JsonKey(name: 'pdf_url') String? pdfUrl,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'created_by') String? createdBy,@JsonKey(includeFromJson: false, includeToJson: false) String? createdByName, List<String> systems, List<VorStatusHistoryModel> statusHistory
});




}
/// @nodoc
class __$VorModelCopyWithImpl<$Res>
    implements _$VorModelCopyWith<$Res> {
  __$VorModelCopyWithImpl(this._self, this._then);

  final _VorModel _self;
  final $Res Function(_VorModel) _then;

/// Create a copy of VorModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? contractId = null,Object? number = null,Object? startDate = null,Object? endDate = null,Object? status = null,Object? excelUrl = freezed,Object? pdfUrl = freezed,Object? createdAt = null,Object? createdBy = freezed,Object? createdByName = freezed,Object? systems = null,Object? statusHistory = null,}) {
  return _then(_VorModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,contractId: null == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as VorStatus,excelUrl: freezed == excelUrl ? _self.excelUrl : excelUrl // ignore: cast_nullable_to_non_nullable
as String?,pdfUrl: freezed == pdfUrl ? _self.pdfUrl : pdfUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,createdByName: freezed == createdByName ? _self.createdByName : createdByName // ignore: cast_nullable_to_non_nullable
as String?,systems: null == systems ? _self._systems : systems // ignore: cast_nullable_to_non_nullable
as List<String>,statusHistory: null == statusHistory ? _self._statusHistory : statusHistory // ignore: cast_nullable_to_non_nullable
as List<VorStatusHistoryModel>,
  ));
}


}


/// @nodoc
mixin _$VorItemModel {

/// Идентификатор позиции.
 String get id;/// Идентификатор ведомости.
@JsonKey(name: 'vor_id') String get vorId;/// Идентификатор сметной позиции (если есть).
@JsonKey(name: 'estimate_item_id') String? get estimateItemId;/// Наименование работы (для новых позиций).
 String? get name;/// Единица измерения.
 String? get unit;/// Количество.
 double get quantity;/// Флаг превышения или новой позиции.
@JsonKey(name: 'is_extra') bool get isExtra;/// Порядок сортировки.
@JsonKey(name: 'sort_order') int get sortOrder;
/// Create a copy of VorItemModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VorItemModelCopyWith<VorItemModel> get copyWith => _$VorItemModelCopyWithImpl<VorItemModel>(this as VorItemModel, _$identity);

  /// Serializes this VorItemModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VorItemModel&&(identical(other.id, id) || other.id == id)&&(identical(other.vorId, vorId) || other.vorId == vorId)&&(identical(other.estimateItemId, estimateItemId) || other.estimateItemId == estimateItemId)&&(identical(other.name, name) || other.name == name)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.isExtra, isExtra) || other.isExtra == isExtra)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,vorId,estimateItemId,name,unit,quantity,isExtra,sortOrder);

@override
String toString() {
  return 'VorItemModel(id: $id, vorId: $vorId, estimateItemId: $estimateItemId, name: $name, unit: $unit, quantity: $quantity, isExtra: $isExtra, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $VorItemModelCopyWith<$Res>  {
  factory $VorItemModelCopyWith(VorItemModel value, $Res Function(VorItemModel) _then) = _$VorItemModelCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'vor_id') String vorId,@JsonKey(name: 'estimate_item_id') String? estimateItemId, String? name, String? unit, double quantity,@JsonKey(name: 'is_extra') bool isExtra,@JsonKey(name: 'sort_order') int sortOrder
});




}
/// @nodoc
class _$VorItemModelCopyWithImpl<$Res>
    implements $VorItemModelCopyWith<$Res> {
  _$VorItemModelCopyWithImpl(this._self, this._then);

  final VorItemModel _self;
  final $Res Function(VorItemModel) _then;

/// Create a copy of VorItemModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? vorId = null,Object? estimateItemId = freezed,Object? name = freezed,Object? unit = freezed,Object? quantity = null,Object? isExtra = null,Object? sortOrder = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,vorId: null == vorId ? _self.vorId : vorId // ignore: cast_nullable_to_non_nullable
as String,estimateItemId: freezed == estimateItemId ? _self.estimateItemId : estimateItemId // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double,isExtra: null == isExtra ? _self.isExtra : isExtra // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _VorItemModel implements VorItemModel {
  const _VorItemModel({required this.id, @JsonKey(name: 'vor_id') required this.vorId, @JsonKey(name: 'estimate_item_id') this.estimateItemId, this.name, this.unit, required this.quantity, @JsonKey(name: 'is_extra') this.isExtra = false, @JsonKey(name: 'sort_order') this.sortOrder = 0});
  factory _VorItemModel.fromJson(Map<String, dynamic> json) => _$VorItemModelFromJson(json);

/// Идентификатор позиции.
@override final  String id;
/// Идентификатор ведомости.
@override@JsonKey(name: 'vor_id') final  String vorId;
/// Идентификатор сметной позиции (если есть).
@override@JsonKey(name: 'estimate_item_id') final  String? estimateItemId;
/// Наименование работы (для новых позиций).
@override final  String? name;
/// Единица измерения.
@override final  String? unit;
/// Количество.
@override final  double quantity;
/// Флаг превышения или новой позиции.
@override@JsonKey(name: 'is_extra') final  bool isExtra;
/// Порядок сортировки.
@override@JsonKey(name: 'sort_order') final  int sortOrder;

/// Create a copy of VorItemModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VorItemModelCopyWith<_VorItemModel> get copyWith => __$VorItemModelCopyWithImpl<_VorItemModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VorItemModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VorItemModel&&(identical(other.id, id) || other.id == id)&&(identical(other.vorId, vorId) || other.vorId == vorId)&&(identical(other.estimateItemId, estimateItemId) || other.estimateItemId == estimateItemId)&&(identical(other.name, name) || other.name == name)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.isExtra, isExtra) || other.isExtra == isExtra)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,vorId,estimateItemId,name,unit,quantity,isExtra,sortOrder);

@override
String toString() {
  return 'VorItemModel(id: $id, vorId: $vorId, estimateItemId: $estimateItemId, name: $name, unit: $unit, quantity: $quantity, isExtra: $isExtra, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$VorItemModelCopyWith<$Res> implements $VorItemModelCopyWith<$Res> {
  factory _$VorItemModelCopyWith(_VorItemModel value, $Res Function(_VorItemModel) _then) = __$VorItemModelCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'vor_id') String vorId,@JsonKey(name: 'estimate_item_id') String? estimateItemId, String? name, String? unit, double quantity,@JsonKey(name: 'is_extra') bool isExtra,@JsonKey(name: 'sort_order') int sortOrder
});




}
/// @nodoc
class __$VorItemModelCopyWithImpl<$Res>
    implements _$VorItemModelCopyWith<$Res> {
  __$VorItemModelCopyWithImpl(this._self, this._then);

  final _VorItemModel _self;
  final $Res Function(_VorItemModel) _then;

/// Create a copy of VorItemModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? vorId = null,Object? estimateItemId = freezed,Object? name = freezed,Object? unit = freezed,Object? quantity = null,Object? isExtra = null,Object? sortOrder = null,}) {
  return _then(_VorItemModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,vorId: null == vorId ? _self.vorId : vorId // ignore: cast_nullable_to_non_nullable
as String,estimateItemId: freezed == estimateItemId ? _self.estimateItemId : estimateItemId // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double,isExtra: null == isExtra ? _self.isExtra : isExtra // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$VorStatusHistoryModel {

/// Идентификатор записи.
 String get id;/// Статус, на который перешли.
 VorStatus get status;/// Кто совершил действие (ID пользователя).
@JsonKey(name: 'user_id') String? get userId;/// ФИО пользователя (опционально).
@JsonKey(includeFromJson: false, includeToJson: false) String? get userName;/// Причина изменения.
 String? get comment;/// Дата изменения.
@JsonKey(name: 'created_at') DateTime get createdAt;
/// Create a copy of VorStatusHistoryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VorStatusHistoryModelCopyWith<VorStatusHistoryModel> get copyWith => _$VorStatusHistoryModelCopyWithImpl<VorStatusHistoryModel>(this as VorStatusHistoryModel, _$identity);

  /// Serializes this VorStatusHistoryModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VorStatusHistoryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,status,userId,userName,comment,createdAt);

@override
String toString() {
  return 'VorStatusHistoryModel(id: $id, status: $status, userId: $userId, userName: $userName, comment: $comment, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $VorStatusHistoryModelCopyWith<$Res>  {
  factory $VorStatusHistoryModelCopyWith(VorStatusHistoryModel value, $Res Function(VorStatusHistoryModel) _then) = _$VorStatusHistoryModelCopyWithImpl;
@useResult
$Res call({
 String id, VorStatus status,@JsonKey(name: 'user_id') String? userId,@JsonKey(includeFromJson: false, includeToJson: false) String? userName, String? comment,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class _$VorStatusHistoryModelCopyWithImpl<$Res>
    implements $VorStatusHistoryModelCopyWith<$Res> {
  _$VorStatusHistoryModelCopyWithImpl(this._self, this._then);

  final VorStatusHistoryModel _self;
  final $Res Function(VorStatusHistoryModel) _then;

/// Create a copy of VorStatusHistoryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? status = null,Object? userId = freezed,Object? userName = freezed,Object? comment = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as VorStatus,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,userName: freezed == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String?,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _VorStatusHistoryModel extends VorStatusHistoryModel {
  const _VorStatusHistoryModel({required this.id, required this.status, @JsonKey(name: 'user_id') this.userId, @JsonKey(includeFromJson: false, includeToJson: false) this.userName, this.comment, @JsonKey(name: 'created_at') required this.createdAt}): super._();
  factory _VorStatusHistoryModel.fromJson(Map<String, dynamic> json) => _$VorStatusHistoryModelFromJson(json);

/// Идентификатор записи.
@override final  String id;
/// Статус, на который перешли.
@override final  VorStatus status;
/// Кто совершил действие (ID пользователя).
@override@JsonKey(name: 'user_id') final  String? userId;
/// ФИО пользователя (опционально).
@override@JsonKey(includeFromJson: false, includeToJson: false) final  String? userName;
/// Причина изменения.
@override final  String? comment;
/// Дата изменения.
@override@JsonKey(name: 'created_at') final  DateTime createdAt;

/// Create a copy of VorStatusHistoryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VorStatusHistoryModelCopyWith<_VorStatusHistoryModel> get copyWith => __$VorStatusHistoryModelCopyWithImpl<_VorStatusHistoryModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VorStatusHistoryModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VorStatusHistoryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,status,userId,userName,comment,createdAt);

@override
String toString() {
  return 'VorStatusHistoryModel(id: $id, status: $status, userId: $userId, userName: $userName, comment: $comment, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$VorStatusHistoryModelCopyWith<$Res> implements $VorStatusHistoryModelCopyWith<$Res> {
  factory _$VorStatusHistoryModelCopyWith(_VorStatusHistoryModel value, $Res Function(_VorStatusHistoryModel) _then) = __$VorStatusHistoryModelCopyWithImpl;
@override @useResult
$Res call({
 String id, VorStatus status,@JsonKey(name: 'user_id') String? userId,@JsonKey(includeFromJson: false, includeToJson: false) String? userName, String? comment,@JsonKey(name: 'created_at') DateTime createdAt
});




}
/// @nodoc
class __$VorStatusHistoryModelCopyWithImpl<$Res>
    implements _$VorStatusHistoryModelCopyWith<$Res> {
  __$VorStatusHistoryModelCopyWithImpl(this._self, this._then);

  final _VorStatusHistoryModel _self;
  final $Res Function(_VorStatusHistoryModel) _then;

/// Create a copy of VorStatusHistoryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? status = null,Object? userId = freezed,Object? userName = freezed,Object? comment = freezed,Object? createdAt = null,}) {
  return _then(_VorStatusHistoryModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as VorStatus,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,userName: freezed == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String?,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
