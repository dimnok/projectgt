// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'employee_attendance_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EmployeeAttendanceModel {

 String get id;@JsonKey(name: 'company_id') String get companyId;@JsonKey(name: 'employee_id') String get employeeId;@JsonKey(name: 'object_id') String get objectId; String get date; num get hours;@JsonKey(name: 'attendance_type') AttendanceType get attendanceType; String? get comment;@JsonKey(name: 'created_by') String? get createdBy;@JsonKey(name: 'created_at') String? get createdAt;@JsonKey(name: 'updated_at') String? get updatedAt;
/// Create a copy of EmployeeAttendanceModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmployeeAttendanceModelCopyWith<EmployeeAttendanceModel> get copyWith => _$EmployeeAttendanceModelCopyWithImpl<EmployeeAttendanceModel>(this as EmployeeAttendanceModel, _$identity);

  /// Serializes this EmployeeAttendanceModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmployeeAttendanceModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.date, date) || other.date == date)&&(identical(other.hours, hours) || other.hours == hours)&&(identical(other.attendanceType, attendanceType) || other.attendanceType == attendanceType)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,employeeId,objectId,date,hours,attendanceType,comment,createdBy,createdAt,updatedAt);

@override
String toString() {
  return 'EmployeeAttendanceModel(id: $id, companyId: $companyId, employeeId: $employeeId, objectId: $objectId, date: $date, hours: $hours, attendanceType: $attendanceType, comment: $comment, createdBy: $createdBy, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $EmployeeAttendanceModelCopyWith<$Res>  {
  factory $EmployeeAttendanceModelCopyWith(EmployeeAttendanceModel value, $Res Function(EmployeeAttendanceModel) _then) = _$EmployeeAttendanceModelCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'company_id') String companyId,@JsonKey(name: 'employee_id') String employeeId,@JsonKey(name: 'object_id') String objectId, String date, num hours,@JsonKey(name: 'attendance_type') AttendanceType attendanceType, String? comment,@JsonKey(name: 'created_by') String? createdBy,@JsonKey(name: 'created_at') String? createdAt,@JsonKey(name: 'updated_at') String? updatedAt
});




}
/// @nodoc
class _$EmployeeAttendanceModelCopyWithImpl<$Res>
    implements $EmployeeAttendanceModelCopyWith<$Res> {
  _$EmployeeAttendanceModelCopyWithImpl(this._self, this._then);

  final EmployeeAttendanceModel _self;
  final $Res Function(EmployeeAttendanceModel) _then;

/// Create a copy of EmployeeAttendanceModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? employeeId = null,Object? objectId = null,Object? date = null,Object? hours = null,Object? attendanceType = null,Object? comment = freezed,Object? createdBy = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,employeeId: null == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String,objectId: null == objectId ? _self.objectId : objectId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,hours: null == hours ? _self.hours : hours // ignore: cast_nullable_to_non_nullable
as num,attendanceType: null == attendanceType ? _self.attendanceType : attendanceType // ignore: cast_nullable_to_non_nullable
as AttendanceType,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _EmployeeAttendanceModel implements EmployeeAttendanceModel {
  const _EmployeeAttendanceModel({required this.id, @JsonKey(name: 'company_id') required this.companyId, @JsonKey(name: 'employee_id') required this.employeeId, @JsonKey(name: 'object_id') required this.objectId, required this.date, required this.hours, @JsonKey(name: 'attendance_type') this.attendanceType = AttendanceType.work, this.comment, @JsonKey(name: 'created_by') this.createdBy, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt});
  factory _EmployeeAttendanceModel.fromJson(Map<String, dynamic> json) => _$EmployeeAttendanceModelFromJson(json);

@override final  String id;
@override@JsonKey(name: 'company_id') final  String companyId;
@override@JsonKey(name: 'employee_id') final  String employeeId;
@override@JsonKey(name: 'object_id') final  String objectId;
@override final  String date;
@override final  num hours;
@override@JsonKey(name: 'attendance_type') final  AttendanceType attendanceType;
@override final  String? comment;
@override@JsonKey(name: 'created_by') final  String? createdBy;
@override@JsonKey(name: 'created_at') final  String? createdAt;
@override@JsonKey(name: 'updated_at') final  String? updatedAt;

/// Create a copy of EmployeeAttendanceModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EmployeeAttendanceModelCopyWith<_EmployeeAttendanceModel> get copyWith => __$EmployeeAttendanceModelCopyWithImpl<_EmployeeAttendanceModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EmployeeAttendanceModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EmployeeAttendanceModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.date, date) || other.date == date)&&(identical(other.hours, hours) || other.hours == hours)&&(identical(other.attendanceType, attendanceType) || other.attendanceType == attendanceType)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,employeeId,objectId,date,hours,attendanceType,comment,createdBy,createdAt,updatedAt);

@override
String toString() {
  return 'EmployeeAttendanceModel(id: $id, companyId: $companyId, employeeId: $employeeId, objectId: $objectId, date: $date, hours: $hours, attendanceType: $attendanceType, comment: $comment, createdBy: $createdBy, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$EmployeeAttendanceModelCopyWith<$Res> implements $EmployeeAttendanceModelCopyWith<$Res> {
  factory _$EmployeeAttendanceModelCopyWith(_EmployeeAttendanceModel value, $Res Function(_EmployeeAttendanceModel) _then) = __$EmployeeAttendanceModelCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'company_id') String companyId,@JsonKey(name: 'employee_id') String employeeId,@JsonKey(name: 'object_id') String objectId, String date, num hours,@JsonKey(name: 'attendance_type') AttendanceType attendanceType, String? comment,@JsonKey(name: 'created_by') String? createdBy,@JsonKey(name: 'created_at') String? createdAt,@JsonKey(name: 'updated_at') String? updatedAt
});




}
/// @nodoc
class __$EmployeeAttendanceModelCopyWithImpl<$Res>
    implements _$EmployeeAttendanceModelCopyWith<$Res> {
  __$EmployeeAttendanceModelCopyWithImpl(this._self, this._then);

  final _EmployeeAttendanceModel _self;
  final $Res Function(_EmployeeAttendanceModel) _then;

/// Create a copy of EmployeeAttendanceModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? employeeId = null,Object? objectId = null,Object? date = null,Object? hours = null,Object? attendanceType = null,Object? comment = freezed,Object? createdBy = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_EmployeeAttendanceModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,employeeId: null == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String,objectId: null == objectId ? _self.objectId : objectId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,hours: null == hours ? _self.hours : hours // ignore: cast_nullable_to_non_nullable
as num,attendanceType: null == attendanceType ? _self.attendanceType : attendanceType // ignore: cast_nullable_to_non_nullable
as AttendanceType,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
