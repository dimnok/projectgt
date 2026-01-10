// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'employee_rate.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EmployeeRate {

/// Уникальный идентификатор записи ставки
 String get id;/// Идентификатор компании
 String get companyId;/// Идентификатор сотрудника
 String get employeeId;/// Почасовая ставка в рублях
 double get hourlyRate;/// Дата начала действия ставки
 DateTime get validFrom;/// Дата окончания действия ставки (null означает текущую ставку)
 DateTime? get validTo;/// Дата создания записи
 DateTime? get createdAt;/// Идентификатор пользователя, создавшего запись
 String? get createdBy;
/// Create a copy of EmployeeRate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmployeeRateCopyWith<EmployeeRate> get copyWith => _$EmployeeRateCopyWithImpl<EmployeeRate>(this as EmployeeRate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmployeeRate&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.hourlyRate, hourlyRate) || other.hourlyRate == hourlyRate)&&(identical(other.validFrom, validFrom) || other.validFrom == validFrom)&&(identical(other.validTo, validTo) || other.validTo == validTo)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,employeeId,hourlyRate,validFrom,validTo,createdAt,createdBy);

@override
String toString() {
  return 'EmployeeRate(id: $id, companyId: $companyId, employeeId: $employeeId, hourlyRate: $hourlyRate, validFrom: $validFrom, validTo: $validTo, createdAt: $createdAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class $EmployeeRateCopyWith<$Res>  {
  factory $EmployeeRateCopyWith(EmployeeRate value, $Res Function(EmployeeRate) _then) = _$EmployeeRateCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String employeeId, double hourlyRate, DateTime validFrom, DateTime? validTo, DateTime? createdAt, String? createdBy
});




}
/// @nodoc
class _$EmployeeRateCopyWithImpl<$Res>
    implements $EmployeeRateCopyWith<$Res> {
  _$EmployeeRateCopyWithImpl(this._self, this._then);

  final EmployeeRate _self;
  final $Res Function(EmployeeRate) _then;

/// Create a copy of EmployeeRate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? employeeId = null,Object? hourlyRate = null,Object? validFrom = null,Object? validTo = freezed,Object? createdAt = freezed,Object? createdBy = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,employeeId: null == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String,hourlyRate: null == hourlyRate ? _self.hourlyRate : hourlyRate // ignore: cast_nullable_to_non_nullable
as double,validFrom: null == validFrom ? _self.validFrom : validFrom // ignore: cast_nullable_to_non_nullable
as DateTime,validTo: freezed == validTo ? _self.validTo : validTo // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc


class _EmployeeRate extends EmployeeRate {
  const _EmployeeRate({required this.id, required this.companyId, required this.employeeId, required this.hourlyRate, required this.validFrom, this.validTo, this.createdAt, this.createdBy}): super._();
  

/// Уникальный идентификатор записи ставки
@override final  String id;
/// Идентификатор компании
@override final  String companyId;
/// Идентификатор сотрудника
@override final  String employeeId;
/// Почасовая ставка в рублях
@override final  double hourlyRate;
/// Дата начала действия ставки
@override final  DateTime validFrom;
/// Дата окончания действия ставки (null означает текущую ставку)
@override final  DateTime? validTo;
/// Дата создания записи
@override final  DateTime? createdAt;
/// Идентификатор пользователя, создавшего запись
@override final  String? createdBy;

/// Create a copy of EmployeeRate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EmployeeRateCopyWith<_EmployeeRate> get copyWith => __$EmployeeRateCopyWithImpl<_EmployeeRate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EmployeeRate&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.hourlyRate, hourlyRate) || other.hourlyRate == hourlyRate)&&(identical(other.validFrom, validFrom) || other.validFrom == validFrom)&&(identical(other.validTo, validTo) || other.validTo == validTo)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,employeeId,hourlyRate,validFrom,validTo,createdAt,createdBy);

@override
String toString() {
  return 'EmployeeRate(id: $id, companyId: $companyId, employeeId: $employeeId, hourlyRate: $hourlyRate, validFrom: $validFrom, validTo: $validTo, createdAt: $createdAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class _$EmployeeRateCopyWith<$Res> implements $EmployeeRateCopyWith<$Res> {
  factory _$EmployeeRateCopyWith(_EmployeeRate value, $Res Function(_EmployeeRate) _then) = __$EmployeeRateCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String employeeId, double hourlyRate, DateTime validFrom, DateTime? validTo, DateTime? createdAt, String? createdBy
});




}
/// @nodoc
class __$EmployeeRateCopyWithImpl<$Res>
    implements _$EmployeeRateCopyWith<$Res> {
  __$EmployeeRateCopyWithImpl(this._self, this._then);

  final _EmployeeRate _self;
  final $Res Function(_EmployeeRate) _then;

/// Create a copy of EmployeeRate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? employeeId = null,Object? hourlyRate = null,Object? validFrom = null,Object? validTo = freezed,Object? createdAt = freezed,Object? createdBy = freezed,}) {
  return _then(_EmployeeRate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,employeeId: null == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String,hourlyRate: null == hourlyRate ? _self.hourlyRate : hourlyRate // ignore: cast_nullable_to_non_nullable
as double,validFrom: null == validFrom ? _self.validFrom : validFrom // ignore: cast_nullable_to_non_nullable
as DateTime,validTo: freezed == validTo ? _self.validTo : validTo // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
