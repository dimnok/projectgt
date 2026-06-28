// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'employee_application.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EmployeeApplication {

 String get id; String get companyId; String get employeeId; EmployeeApplicationType get applicationType; DateTime get startDate; DateTime? get endDate; int get durationDays; String get scanName; String get scanPath; int get scanSize; String get scanType; String get createdBy; String? get createdByName; DateTime get createdAt;
/// Create a copy of EmployeeApplication
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmployeeApplicationCopyWith<EmployeeApplication> get copyWith => _$EmployeeApplicationCopyWithImpl<EmployeeApplication>(this as EmployeeApplication, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmployeeApplication&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.applicationType, applicationType) || other.applicationType == applicationType)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.durationDays, durationDays) || other.durationDays == durationDays)&&(identical(other.scanName, scanName) || other.scanName == scanName)&&(identical(other.scanPath, scanPath) || other.scanPath == scanPath)&&(identical(other.scanSize, scanSize) || other.scanSize == scanSize)&&(identical(other.scanType, scanType) || other.scanType == scanType)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdByName, createdByName) || other.createdByName == createdByName)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,employeeId,applicationType,startDate,endDate,durationDays,scanName,scanPath,scanSize,scanType,createdBy,createdByName,createdAt);

@override
String toString() {
  return 'EmployeeApplication(id: $id, companyId: $companyId, employeeId: $employeeId, applicationType: $applicationType, startDate: $startDate, endDate: $endDate, durationDays: $durationDays, scanName: $scanName, scanPath: $scanPath, scanSize: $scanSize, scanType: $scanType, createdBy: $createdBy, createdByName: $createdByName, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $EmployeeApplicationCopyWith<$Res>  {
  factory $EmployeeApplicationCopyWith(EmployeeApplication value, $Res Function(EmployeeApplication) _then) = _$EmployeeApplicationCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String employeeId, EmployeeApplicationType applicationType, DateTime startDate, DateTime? endDate, int durationDays, String scanName, String scanPath, int scanSize, String scanType, String createdBy, String? createdByName, DateTime createdAt
});




}
/// @nodoc
class _$EmployeeApplicationCopyWithImpl<$Res>
    implements $EmployeeApplicationCopyWith<$Res> {
  _$EmployeeApplicationCopyWithImpl(this._self, this._then);

  final EmployeeApplication _self;
  final $Res Function(EmployeeApplication) _then;

/// Create a copy of EmployeeApplication
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? employeeId = null,Object? applicationType = null,Object? startDate = null,Object? endDate = freezed,Object? durationDays = null,Object? scanName = null,Object? scanPath = null,Object? scanSize = null,Object? scanType = null,Object? createdBy = null,Object? createdByName = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,employeeId: null == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String,applicationType: null == applicationType ? _self.applicationType : applicationType // ignore: cast_nullable_to_non_nullable
as EmployeeApplicationType,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,durationDays: null == durationDays ? _self.durationDays : durationDays // ignore: cast_nullable_to_non_nullable
as int,scanName: null == scanName ? _self.scanName : scanName // ignore: cast_nullable_to_non_nullable
as String,scanPath: null == scanPath ? _self.scanPath : scanPath // ignore: cast_nullable_to_non_nullable
as String,scanSize: null == scanSize ? _self.scanSize : scanSize // ignore: cast_nullable_to_non_nullable
as int,scanType: null == scanType ? _self.scanType : scanType // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdByName: freezed == createdByName ? _self.createdByName : createdByName // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// @nodoc


class _EmployeeApplication implements EmployeeApplication {
  const _EmployeeApplication({required this.id, required this.companyId, required this.employeeId, required this.applicationType, required this.startDate, this.endDate, required this.durationDays, required this.scanName, required this.scanPath, required this.scanSize, required this.scanType, required this.createdBy, this.createdByName, required this.createdAt});
  

@override final  String id;
@override final  String companyId;
@override final  String employeeId;
@override final  EmployeeApplicationType applicationType;
@override final  DateTime startDate;
@override final  DateTime? endDate;
@override final  int durationDays;
@override final  String scanName;
@override final  String scanPath;
@override final  int scanSize;
@override final  String scanType;
@override final  String createdBy;
@override final  String? createdByName;
@override final  DateTime createdAt;

/// Create a copy of EmployeeApplication
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EmployeeApplicationCopyWith<_EmployeeApplication> get copyWith => __$EmployeeApplicationCopyWithImpl<_EmployeeApplication>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EmployeeApplication&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.applicationType, applicationType) || other.applicationType == applicationType)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.durationDays, durationDays) || other.durationDays == durationDays)&&(identical(other.scanName, scanName) || other.scanName == scanName)&&(identical(other.scanPath, scanPath) || other.scanPath == scanPath)&&(identical(other.scanSize, scanSize) || other.scanSize == scanSize)&&(identical(other.scanType, scanType) || other.scanType == scanType)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdByName, createdByName) || other.createdByName == createdByName)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,employeeId,applicationType,startDate,endDate,durationDays,scanName,scanPath,scanSize,scanType,createdBy,createdByName,createdAt);

@override
String toString() {
  return 'EmployeeApplication(id: $id, companyId: $companyId, employeeId: $employeeId, applicationType: $applicationType, startDate: $startDate, endDate: $endDate, durationDays: $durationDays, scanName: $scanName, scanPath: $scanPath, scanSize: $scanSize, scanType: $scanType, createdBy: $createdBy, createdByName: $createdByName, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$EmployeeApplicationCopyWith<$Res> implements $EmployeeApplicationCopyWith<$Res> {
  factory _$EmployeeApplicationCopyWith(_EmployeeApplication value, $Res Function(_EmployeeApplication) _then) = __$EmployeeApplicationCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String employeeId, EmployeeApplicationType applicationType, DateTime startDate, DateTime? endDate, int durationDays, String scanName, String scanPath, int scanSize, String scanType, String createdBy, String? createdByName, DateTime createdAt
});




}
/// @nodoc
class __$EmployeeApplicationCopyWithImpl<$Res>
    implements _$EmployeeApplicationCopyWith<$Res> {
  __$EmployeeApplicationCopyWithImpl(this._self, this._then);

  final _EmployeeApplication _self;
  final $Res Function(_EmployeeApplication) _then;

/// Create a copy of EmployeeApplication
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? employeeId = null,Object? applicationType = null,Object? startDate = null,Object? endDate = freezed,Object? durationDays = null,Object? scanName = null,Object? scanPath = null,Object? scanSize = null,Object? scanType = null,Object? createdBy = null,Object? createdByName = freezed,Object? createdAt = null,}) {
  return _then(_EmployeeApplication(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,employeeId: null == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String,applicationType: null == applicationType ? _self.applicationType : applicationType // ignore: cast_nullable_to_non_nullable
as EmployeeApplicationType,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,durationDays: null == durationDays ? _self.durationDays : durationDays // ignore: cast_nullable_to_non_nullable
as int,scanName: null == scanName ? _self.scanName : scanName // ignore: cast_nullable_to_non_nullable
as String,scanPath: null == scanPath ? _self.scanPath : scanPath // ignore: cast_nullable_to_non_nullable
as String,scanSize: null == scanSize ? _self.scanSize : scanSize // ignore: cast_nullable_to_non_nullable
as int,scanType: null == scanType ? _self.scanType : scanType // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdByName: freezed == createdByName ? _self.createdByName : createdByName // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
