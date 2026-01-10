// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'business_trip_rate.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BusinessTripRate {

/// Уникальный идентификатор ставки.
 String get id;/// Идентификатор объекта, к которому относится ставка.
 String get objectId;/// Идентификатор сотрудника (null = для всех сотрудников на объекте).
 String? get employeeId;/// Размер ставки командировочных за смену (в рублях).
 double get rate;/// Минимальное количество часов для начисления командировочных.
 double get minimumHours;/// Дата начала действия ставки.
 DateTime get validFrom;/// Дата окончания действия ставки (null = бессрочно).
 DateTime? get validTo;/// Дата и время создания записи.
 DateTime? get createdAt;/// Дата и время последнего обновления.
 DateTime? get updatedAt;/// Идентификатор пользователя, создавшего запись.
 String? get createdBy;
/// Create a copy of BusinessTripRate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BusinessTripRateCopyWith<BusinessTripRate> get copyWith => _$BusinessTripRateCopyWithImpl<BusinessTripRate>(this as BusinessTripRate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BusinessTripRate&&(identical(other.id, id) || other.id == id)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.rate, rate) || other.rate == rate)&&(identical(other.minimumHours, minimumHours) || other.minimumHours == minimumHours)&&(identical(other.validFrom, validFrom) || other.validFrom == validFrom)&&(identical(other.validTo, validTo) || other.validTo == validTo)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}


@override
int get hashCode => Object.hash(runtimeType,id,objectId,employeeId,rate,minimumHours,validFrom,validTo,createdAt,updatedAt,createdBy);

@override
String toString() {
  return 'BusinessTripRate(id: $id, objectId: $objectId, employeeId: $employeeId, rate: $rate, minimumHours: $minimumHours, validFrom: $validFrom, validTo: $validTo, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class $BusinessTripRateCopyWith<$Res>  {
  factory $BusinessTripRateCopyWith(BusinessTripRate value, $Res Function(BusinessTripRate) _then) = _$BusinessTripRateCopyWithImpl;
@useResult
$Res call({
 String id, String objectId, String? employeeId, double rate, double minimumHours, DateTime validFrom, DateTime? validTo, DateTime? createdAt, DateTime? updatedAt, String? createdBy
});




}
/// @nodoc
class _$BusinessTripRateCopyWithImpl<$Res>
    implements $BusinessTripRateCopyWith<$Res> {
  _$BusinessTripRateCopyWithImpl(this._self, this._then);

  final BusinessTripRate _self;
  final $Res Function(BusinessTripRate) _then;

/// Create a copy of BusinessTripRate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? objectId = null,Object? employeeId = freezed,Object? rate = null,Object? minimumHours = null,Object? validFrom = null,Object? validTo = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,objectId: null == objectId ? _self.objectId : objectId // ignore: cast_nullable_to_non_nullable
as String,employeeId: freezed == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String?,rate: null == rate ? _self.rate : rate // ignore: cast_nullable_to_non_nullable
as double,minimumHours: null == minimumHours ? _self.minimumHours : minimumHours // ignore: cast_nullable_to_non_nullable
as double,validFrom: null == validFrom ? _self.validFrom : validFrom // ignore: cast_nullable_to_non_nullable
as DateTime,validTo: freezed == validTo ? _self.validTo : validTo // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc


class _BusinessTripRate extends BusinessTripRate {
  const _BusinessTripRate({required this.id, required this.objectId, this.employeeId, required this.rate, this.minimumHours = 0.0, required this.validFrom, this.validTo, this.createdAt, this.updatedAt, this.createdBy}): super._();
  

/// Уникальный идентификатор ставки.
@override final  String id;
/// Идентификатор объекта, к которому относится ставка.
@override final  String objectId;
/// Идентификатор сотрудника (null = для всех сотрудников на объекте).
@override final  String? employeeId;
/// Размер ставки командировочных за смену (в рублях).
@override final  double rate;
/// Минимальное количество часов для начисления командировочных.
@override@JsonKey() final  double minimumHours;
/// Дата начала действия ставки.
@override final  DateTime validFrom;
/// Дата окончания действия ставки (null = бессрочно).
@override final  DateTime? validTo;
/// Дата и время создания записи.
@override final  DateTime? createdAt;
/// Дата и время последнего обновления.
@override final  DateTime? updatedAt;
/// Идентификатор пользователя, создавшего запись.
@override final  String? createdBy;

/// Create a copy of BusinessTripRate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BusinessTripRateCopyWith<_BusinessTripRate> get copyWith => __$BusinessTripRateCopyWithImpl<_BusinessTripRate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BusinessTripRate&&(identical(other.id, id) || other.id == id)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.rate, rate) || other.rate == rate)&&(identical(other.minimumHours, minimumHours) || other.minimumHours == minimumHours)&&(identical(other.validFrom, validFrom) || other.validFrom == validFrom)&&(identical(other.validTo, validTo) || other.validTo == validTo)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}


@override
int get hashCode => Object.hash(runtimeType,id,objectId,employeeId,rate,minimumHours,validFrom,validTo,createdAt,updatedAt,createdBy);

@override
String toString() {
  return 'BusinessTripRate(id: $id, objectId: $objectId, employeeId: $employeeId, rate: $rate, minimumHours: $minimumHours, validFrom: $validFrom, validTo: $validTo, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class _$BusinessTripRateCopyWith<$Res> implements $BusinessTripRateCopyWith<$Res> {
  factory _$BusinessTripRateCopyWith(_BusinessTripRate value, $Res Function(_BusinessTripRate) _then) = __$BusinessTripRateCopyWithImpl;
@override @useResult
$Res call({
 String id, String objectId, String? employeeId, double rate, double minimumHours, DateTime validFrom, DateTime? validTo, DateTime? createdAt, DateTime? updatedAt, String? createdBy
});




}
/// @nodoc
class __$BusinessTripRateCopyWithImpl<$Res>
    implements _$BusinessTripRateCopyWith<$Res> {
  __$BusinessTripRateCopyWithImpl(this._self, this._then);

  final _BusinessTripRate _self;
  final $Res Function(_BusinessTripRate) _then;

/// Create a copy of BusinessTripRate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? objectId = null,Object? employeeId = freezed,Object? rate = null,Object? minimumHours = null,Object? validFrom = null,Object? validTo = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,}) {
  return _then(_BusinessTripRate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,objectId: null == objectId ? _self.objectId : objectId // ignore: cast_nullable_to_non_nullable
as String,employeeId: freezed == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String?,rate: null == rate ? _self.rate : rate // ignore: cast_nullable_to_non_nullable
as double,minimumHours: null == minimumHours ? _self.minimumHours : minimumHours // ignore: cast_nullable_to_non_nullable
as double,validFrom: null == validFrom ? _self.validFrom : validFrom // ignore: cast_nullable_to_non_nullable
as DateTime,validTo: freezed == validTo ? _self.validTo : validTo // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
