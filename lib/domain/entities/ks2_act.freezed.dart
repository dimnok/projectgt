// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ks2_act.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Ks2Act {

 String get id; String get companyId; String get contractId; String get number; DateTime get date; DateTime get periodFrom; DateTime get periodTo; Ks2Status get status; double get totalAmount; DateTime? get createdAt; DateTime? get updatedAt; String? get createdBy;
/// Create a copy of Ks2Act
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Ks2ActCopyWith<Ks2Act> get copyWith => _$Ks2ActCopyWithImpl<Ks2Act>(this as Ks2Act, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Ks2Act&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.number, number) || other.number == number)&&(identical(other.date, date) || other.date == date)&&(identical(other.periodFrom, periodFrom) || other.periodFrom == periodFrom)&&(identical(other.periodTo, periodTo) || other.periodTo == periodTo)&&(identical(other.status, status) || other.status == status)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,contractId,number,date,periodFrom,periodTo,status,totalAmount,createdAt,updatedAt,createdBy);

@override
String toString() {
  return 'Ks2Act(id: $id, companyId: $companyId, contractId: $contractId, number: $number, date: $date, periodFrom: $periodFrom, periodTo: $periodTo, status: $status, totalAmount: $totalAmount, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class $Ks2ActCopyWith<$Res>  {
  factory $Ks2ActCopyWith(Ks2Act value, $Res Function(Ks2Act) _then) = _$Ks2ActCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String contractId, String number, DateTime date, DateTime periodFrom, DateTime periodTo, Ks2Status status, double totalAmount, DateTime? createdAt, DateTime? updatedAt, String? createdBy
});




}
/// @nodoc
class _$Ks2ActCopyWithImpl<$Res>
    implements $Ks2ActCopyWith<$Res> {
  _$Ks2ActCopyWithImpl(this._self, this._then);

  final Ks2Act _self;
  final $Res Function(Ks2Act) _then;

/// Create a copy of Ks2Act
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? contractId = null,Object? number = null,Object? date = null,Object? periodFrom = null,Object? periodTo = null,Object? status = null,Object? totalAmount = null,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,contractId: null == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,periodFrom: null == periodFrom ? _self.periodFrom : periodFrom // ignore: cast_nullable_to_non_nullable
as DateTime,periodTo: null == periodTo ? _self.periodTo : periodTo // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as Ks2Status,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc


class _Ks2Act implements Ks2Act {
  const _Ks2Act({required this.id, required this.companyId, required this.contractId, required this.number, required this.date, required this.periodFrom, required this.periodTo, this.status = Ks2Status.draft, this.totalAmount = 0, this.createdAt, this.updatedAt, this.createdBy});
  

@override final  String id;
@override final  String companyId;
@override final  String contractId;
@override final  String number;
@override final  DateTime date;
@override final  DateTime periodFrom;
@override final  DateTime periodTo;
@override@JsonKey() final  Ks2Status status;
@override@JsonKey() final  double totalAmount;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;
@override final  String? createdBy;

/// Create a copy of Ks2Act
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$Ks2ActCopyWith<_Ks2Act> get copyWith => __$Ks2ActCopyWithImpl<_Ks2Act>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Ks2Act&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.number, number) || other.number == number)&&(identical(other.date, date) || other.date == date)&&(identical(other.periodFrom, periodFrom) || other.periodFrom == periodFrom)&&(identical(other.periodTo, periodTo) || other.periodTo == periodTo)&&(identical(other.status, status) || other.status == status)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,contractId,number,date,periodFrom,periodTo,status,totalAmount,createdAt,updatedAt,createdBy);

@override
String toString() {
  return 'Ks2Act(id: $id, companyId: $companyId, contractId: $contractId, number: $number, date: $date, periodFrom: $periodFrom, periodTo: $periodTo, status: $status, totalAmount: $totalAmount, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class _$Ks2ActCopyWith<$Res> implements $Ks2ActCopyWith<$Res> {
  factory _$Ks2ActCopyWith(_Ks2Act value, $Res Function(_Ks2Act) _then) = __$Ks2ActCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String contractId, String number, DateTime date, DateTime periodFrom, DateTime periodTo, Ks2Status status, double totalAmount, DateTime? createdAt, DateTime? updatedAt, String? createdBy
});




}
/// @nodoc
class __$Ks2ActCopyWithImpl<$Res>
    implements _$Ks2ActCopyWith<$Res> {
  __$Ks2ActCopyWithImpl(this._self, this._then);

  final _Ks2Act _self;
  final $Res Function(_Ks2Act) _then;

/// Create a copy of Ks2Act
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? contractId = null,Object? number = null,Object? date = null,Object? periodFrom = null,Object? periodTo = null,Object? status = null,Object? totalAmount = null,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,}) {
  return _then(_Ks2Act(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,contractId: null == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,periodFrom: null == periodFrom ? _self.periodFrom : periodFrom // ignore: cast_nullable_to_non_nullable
as DateTime,periodTo: null == periodTo ? _self.periodTo : periodTo // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as Ks2Status,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
