// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ks6a_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Ks6aPeriod {

/// Идентификатор периода.
 String get id;/// Дата начала периода.
@JsonKey(name: 'start_date') DateTime get startDate;/// Дата окончания периода.
@JsonKey(name: 'end_date') DateTime get endDate;/// Статус периода (черновик/согласовано).
 Ks6aStatus get status;/// Название периода.
 String? get title;/// Итоговая сумма по периоду.
@JsonKey(name: 'total_amount') double get totalAmount;
/// Create a copy of Ks6aPeriod
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Ks6aPeriodCopyWith<Ks6aPeriod> get copyWith => _$Ks6aPeriodCopyWithImpl<Ks6aPeriod>(this as Ks6aPeriod, _$identity);

  /// Serializes this Ks6aPeriod to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Ks6aPeriod&&(identical(other.id, id) || other.id == id)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.title, title) || other.title == title)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,startDate,endDate,status,title,totalAmount);

@override
String toString() {
  return 'Ks6aPeriod(id: $id, startDate: $startDate, endDate: $endDate, status: $status, title: $title, totalAmount: $totalAmount)';
}


}

/// @nodoc
abstract mixin class $Ks6aPeriodCopyWith<$Res>  {
  factory $Ks6aPeriodCopyWith(Ks6aPeriod value, $Res Function(Ks6aPeriod) _then) = _$Ks6aPeriodCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'start_date') DateTime startDate,@JsonKey(name: 'end_date') DateTime endDate, Ks6aStatus status, String? title,@JsonKey(name: 'total_amount') double totalAmount
});




}
/// @nodoc
class _$Ks6aPeriodCopyWithImpl<$Res>
    implements $Ks6aPeriodCopyWith<$Res> {
  _$Ks6aPeriodCopyWithImpl(this._self, this._then);

  final Ks6aPeriod _self;
  final $Res Function(Ks6aPeriod) _then;

/// Create a copy of Ks6aPeriod
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? startDate = null,Object? endDate = null,Object? status = null,Object? title = freezed,Object? totalAmount = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as Ks6aStatus,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _Ks6aPeriod implements Ks6aPeriod {
  const _Ks6aPeriod({required this.id, @JsonKey(name: 'start_date') required this.startDate, @JsonKey(name: 'end_date') required this.endDate, required this.status, this.title, @JsonKey(name: 'total_amount') this.totalAmount = 0.0});
  factory _Ks6aPeriod.fromJson(Map<String, dynamic> json) => _$Ks6aPeriodFromJson(json);

/// Идентификатор периода.
@override final  String id;
/// Дата начала периода.
@override@JsonKey(name: 'start_date') final  DateTime startDate;
/// Дата окончания периода.
@override@JsonKey(name: 'end_date') final  DateTime endDate;
/// Статус периода (черновик/согласовано).
@override final  Ks6aStatus status;
/// Название периода.
@override final  String? title;
/// Итоговая сумма по периоду.
@override@JsonKey(name: 'total_amount') final  double totalAmount;

/// Create a copy of Ks6aPeriod
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$Ks6aPeriodCopyWith<_Ks6aPeriod> get copyWith => __$Ks6aPeriodCopyWithImpl<_Ks6aPeriod>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$Ks6aPeriodToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Ks6aPeriod&&(identical(other.id, id) || other.id == id)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.title, title) || other.title == title)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,startDate,endDate,status,title,totalAmount);

@override
String toString() {
  return 'Ks6aPeriod(id: $id, startDate: $startDate, endDate: $endDate, status: $status, title: $title, totalAmount: $totalAmount)';
}


}

/// @nodoc
abstract mixin class _$Ks6aPeriodCopyWith<$Res> implements $Ks6aPeriodCopyWith<$Res> {
  factory _$Ks6aPeriodCopyWith(_Ks6aPeriod value, $Res Function(_Ks6aPeriod) _then) = __$Ks6aPeriodCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'start_date') DateTime startDate,@JsonKey(name: 'end_date') DateTime endDate, Ks6aStatus status, String? title,@JsonKey(name: 'total_amount') double totalAmount
});




}
/// @nodoc
class __$Ks6aPeriodCopyWithImpl<$Res>
    implements _$Ks6aPeriodCopyWith<$Res> {
  __$Ks6aPeriodCopyWithImpl(this._self, this._then);

  final _Ks6aPeriod _self;
  final $Res Function(_Ks6aPeriod) _then;

/// Create a copy of Ks6aPeriod
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? startDate = null,Object? endDate = null,Object? status = null,Object? title = freezed,Object? totalAmount = null,}) {
  return _then(_Ks6aPeriod(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as Ks6aStatus,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$Ks6aPeriodItem {

/// Идентификатор записи.
 String get id;/// Идентификатор периода.
@JsonKey(name: 'period_id') String get periodId;/// Идентификатор сметной позиции.
@JsonKey(name: 'estimate_id') String get estimateId;/// Количество за период.
 double get quantity;/// Снапшот цены на момент создания периода.
@JsonKey(name: 'price_snapshot') double get priceSnapshot;/// Сумма за период (quantity * price_snapshot).
 double get amount;
/// Create a copy of Ks6aPeriodItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Ks6aPeriodItemCopyWith<Ks6aPeriodItem> get copyWith => _$Ks6aPeriodItemCopyWithImpl<Ks6aPeriodItem>(this as Ks6aPeriodItem, _$identity);

  /// Serializes this Ks6aPeriodItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Ks6aPeriodItem&&(identical(other.id, id) || other.id == id)&&(identical(other.periodId, periodId) || other.periodId == periodId)&&(identical(other.estimateId, estimateId) || other.estimateId == estimateId)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.priceSnapshot, priceSnapshot) || other.priceSnapshot == priceSnapshot)&&(identical(other.amount, amount) || other.amount == amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,periodId,estimateId,quantity,priceSnapshot,amount);

@override
String toString() {
  return 'Ks6aPeriodItem(id: $id, periodId: $periodId, estimateId: $estimateId, quantity: $quantity, priceSnapshot: $priceSnapshot, amount: $amount)';
}


}

/// @nodoc
abstract mixin class $Ks6aPeriodItemCopyWith<$Res>  {
  factory $Ks6aPeriodItemCopyWith(Ks6aPeriodItem value, $Res Function(Ks6aPeriodItem) _then) = _$Ks6aPeriodItemCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'period_id') String periodId,@JsonKey(name: 'estimate_id') String estimateId, double quantity,@JsonKey(name: 'price_snapshot') double priceSnapshot, double amount
});




}
/// @nodoc
class _$Ks6aPeriodItemCopyWithImpl<$Res>
    implements $Ks6aPeriodItemCopyWith<$Res> {
  _$Ks6aPeriodItemCopyWithImpl(this._self, this._then);

  final Ks6aPeriodItem _self;
  final $Res Function(Ks6aPeriodItem) _then;

/// Create a copy of Ks6aPeriodItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? periodId = null,Object? estimateId = null,Object? quantity = null,Object? priceSnapshot = null,Object? amount = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,periodId: null == periodId ? _self.periodId : periodId // ignore: cast_nullable_to_non_nullable
as String,estimateId: null == estimateId ? _self.estimateId : estimateId // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double,priceSnapshot: null == priceSnapshot ? _self.priceSnapshot : priceSnapshot // ignore: cast_nullable_to_non_nullable
as double,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _Ks6aPeriodItem implements Ks6aPeriodItem {
  const _Ks6aPeriodItem({required this.id, @JsonKey(name: 'period_id') required this.periodId, @JsonKey(name: 'estimate_id') required this.estimateId, required this.quantity, @JsonKey(name: 'price_snapshot') required this.priceSnapshot, required this.amount});
  factory _Ks6aPeriodItem.fromJson(Map<String, dynamic> json) => _$Ks6aPeriodItemFromJson(json);

/// Идентификатор записи.
@override final  String id;
/// Идентификатор периода.
@override@JsonKey(name: 'period_id') final  String periodId;
/// Идентификатор сметной позиции.
@override@JsonKey(name: 'estimate_id') final  String estimateId;
/// Количество за период.
@override final  double quantity;
/// Снапшот цены на момент создания периода.
@override@JsonKey(name: 'price_snapshot') final  double priceSnapshot;
/// Сумма за период (quantity * price_snapshot).
@override final  double amount;

/// Create a copy of Ks6aPeriodItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$Ks6aPeriodItemCopyWith<_Ks6aPeriodItem> get copyWith => __$Ks6aPeriodItemCopyWithImpl<_Ks6aPeriodItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$Ks6aPeriodItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Ks6aPeriodItem&&(identical(other.id, id) || other.id == id)&&(identical(other.periodId, periodId) || other.periodId == periodId)&&(identical(other.estimateId, estimateId) || other.estimateId == estimateId)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.priceSnapshot, priceSnapshot) || other.priceSnapshot == priceSnapshot)&&(identical(other.amount, amount) || other.amount == amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,periodId,estimateId,quantity,priceSnapshot,amount);

@override
String toString() {
  return 'Ks6aPeriodItem(id: $id, periodId: $periodId, estimateId: $estimateId, quantity: $quantity, priceSnapshot: $priceSnapshot, amount: $amount)';
}


}

/// @nodoc
abstract mixin class _$Ks6aPeriodItemCopyWith<$Res> implements $Ks6aPeriodItemCopyWith<$Res> {
  factory _$Ks6aPeriodItemCopyWith(_Ks6aPeriodItem value, $Res Function(_Ks6aPeriodItem) _then) = __$Ks6aPeriodItemCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'period_id') String periodId,@JsonKey(name: 'estimate_id') String estimateId, double quantity,@JsonKey(name: 'price_snapshot') double priceSnapshot, double amount
});




}
/// @nodoc
class __$Ks6aPeriodItemCopyWithImpl<$Res>
    implements _$Ks6aPeriodItemCopyWith<$Res> {
  __$Ks6aPeriodItemCopyWithImpl(this._self, this._then);

  final _Ks6aPeriodItem _self;
  final $Res Function(_Ks6aPeriodItem) _then;

/// Create a copy of Ks6aPeriodItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? periodId = null,Object? estimateId = null,Object? quantity = null,Object? priceSnapshot = null,Object? amount = null,}) {
  return _then(_Ks6aPeriodItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,periodId: null == periodId ? _self.periodId : periodId // ignore: cast_nullable_to_non_nullable
as String,estimateId: null == estimateId ? _self.estimateId : estimateId // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double,priceSnapshot: null == priceSnapshot ? _self.priceSnapshot : priceSnapshot // ignore: cast_nullable_to_non_nullable
as double,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$Ks6aContractData {

/// Список периодов.
 List<Ks6aPeriod> get periods;/// Список всех строк всех периодов.
 List<Ks6aPeriodItem> get items;
/// Create a copy of Ks6aContractData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Ks6aContractDataCopyWith<Ks6aContractData> get copyWith => _$Ks6aContractDataCopyWithImpl<Ks6aContractData>(this as Ks6aContractData, _$identity);

  /// Serializes this Ks6aContractData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Ks6aContractData&&const DeepCollectionEquality().equals(other.periods, periods)&&const DeepCollectionEquality().equals(other.items, items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(periods),const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'Ks6aContractData(periods: $periods, items: $items)';
}


}

/// @nodoc
abstract mixin class $Ks6aContractDataCopyWith<$Res>  {
  factory $Ks6aContractDataCopyWith(Ks6aContractData value, $Res Function(Ks6aContractData) _then) = _$Ks6aContractDataCopyWithImpl;
@useResult
$Res call({
 List<Ks6aPeriod> periods, List<Ks6aPeriodItem> items
});




}
/// @nodoc
class _$Ks6aContractDataCopyWithImpl<$Res>
    implements $Ks6aContractDataCopyWith<$Res> {
  _$Ks6aContractDataCopyWithImpl(this._self, this._then);

  final Ks6aContractData _self;
  final $Res Function(Ks6aContractData) _then;

/// Create a copy of Ks6aContractData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? periods = null,Object? items = null,}) {
  return _then(_self.copyWith(
periods: null == periods ? _self.periods : periods // ignore: cast_nullable_to_non_nullable
as List<Ks6aPeriod>,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<Ks6aPeriodItem>,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _Ks6aContractData implements Ks6aContractData {
  const _Ks6aContractData({required final  List<Ks6aPeriod> periods, required final  List<Ks6aPeriodItem> items}): _periods = periods,_items = items;
  factory _Ks6aContractData.fromJson(Map<String, dynamic> json) => _$Ks6aContractDataFromJson(json);

/// Список периодов.
 final  List<Ks6aPeriod> _periods;
/// Список периодов.
@override List<Ks6aPeriod> get periods {
  if (_periods is EqualUnmodifiableListView) return _periods;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_periods);
}

/// Список всех строк всех периодов.
 final  List<Ks6aPeriodItem> _items;
/// Список всех строк всех периодов.
@override List<Ks6aPeriodItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of Ks6aContractData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$Ks6aContractDataCopyWith<_Ks6aContractData> get copyWith => __$Ks6aContractDataCopyWithImpl<_Ks6aContractData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$Ks6aContractDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Ks6aContractData&&const DeepCollectionEquality().equals(other._periods, _periods)&&const DeepCollectionEquality().equals(other._items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_periods),const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'Ks6aContractData(periods: $periods, items: $items)';
}


}

/// @nodoc
abstract mixin class _$Ks6aContractDataCopyWith<$Res> implements $Ks6aContractDataCopyWith<$Res> {
  factory _$Ks6aContractDataCopyWith(_Ks6aContractData value, $Res Function(_Ks6aContractData) _then) = __$Ks6aContractDataCopyWithImpl;
@override @useResult
$Res call({
 List<Ks6aPeriod> periods, List<Ks6aPeriodItem> items
});




}
/// @nodoc
class __$Ks6aContractDataCopyWithImpl<$Res>
    implements _$Ks6aContractDataCopyWith<$Res> {
  __$Ks6aContractDataCopyWithImpl(this._self, this._then);

  final _Ks6aContractData _self;
  final $Res Function(_Ks6aContractData) _then;

/// Create a copy of Ks6aContractData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? periods = null,Object? items = null,}) {
  return _then(_Ks6aContractData(
periods: null == periods ? _self._periods : periods // ignore: cast_nullable_to_non_nullable
as List<Ks6aPeriod>,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<Ks6aPeriodItem>,
  ));
}


}

// dart format on
