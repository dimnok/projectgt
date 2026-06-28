// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'employee_application_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EmployeeApplicationModel {

 String get id;@JsonKey(name: 'company_id') String get companyId;@JsonKey(name: 'employee_id') String get employeeId;@JsonKey(name: 'application_type') String get applicationType;@JsonKey(name: 'start_date') DateTime get startDate;@JsonKey(name: 'end_date') DateTime? get endDate;@JsonKey(name: 'duration_days') int get durationDays;@JsonKey(name: 'scan_name') String get scanName;@JsonKey(name: 'scan_path') String get scanPath;@JsonKey(name: 'scan_size') int get scanSize;@JsonKey(name: 'scan_type') String get scanType;@JsonKey(name: 'created_by') String get createdBy;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'creator') Map<String, dynamic>? get creator;
/// Create a copy of EmployeeApplicationModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmployeeApplicationModelCopyWith<EmployeeApplicationModel> get copyWith => _$EmployeeApplicationModelCopyWithImpl<EmployeeApplicationModel>(this as EmployeeApplicationModel, _$identity);

  /// Serializes this EmployeeApplicationModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmployeeApplicationModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.applicationType, applicationType) || other.applicationType == applicationType)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.durationDays, durationDays) || other.durationDays == durationDays)&&(identical(other.scanName, scanName) || other.scanName == scanName)&&(identical(other.scanPath, scanPath) || other.scanPath == scanPath)&&(identical(other.scanSize, scanSize) || other.scanSize == scanSize)&&(identical(other.scanType, scanType) || other.scanType == scanType)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other.creator, creator));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,employeeId,applicationType,startDate,endDate,durationDays,scanName,scanPath,scanSize,scanType,createdBy,createdAt,const DeepCollectionEquality().hash(creator));

@override
String toString() {
  return 'EmployeeApplicationModel(id: $id, companyId: $companyId, employeeId: $employeeId, applicationType: $applicationType, startDate: $startDate, endDate: $endDate, durationDays: $durationDays, scanName: $scanName, scanPath: $scanPath, scanSize: $scanSize, scanType: $scanType, createdBy: $createdBy, createdAt: $createdAt, creator: $creator)';
}


}

/// @nodoc
abstract mixin class $EmployeeApplicationModelCopyWith<$Res>  {
  factory $EmployeeApplicationModelCopyWith(EmployeeApplicationModel value, $Res Function(EmployeeApplicationModel) _then) = _$EmployeeApplicationModelCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'company_id') String companyId,@JsonKey(name: 'employee_id') String employeeId,@JsonKey(name: 'application_type') String applicationType,@JsonKey(name: 'start_date') DateTime startDate,@JsonKey(name: 'end_date') DateTime? endDate,@JsonKey(name: 'duration_days') int durationDays,@JsonKey(name: 'scan_name') String scanName,@JsonKey(name: 'scan_path') String scanPath,@JsonKey(name: 'scan_size') int scanSize,@JsonKey(name: 'scan_type') String scanType,@JsonKey(name: 'created_by') String createdBy,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'creator') Map<String, dynamic>? creator
});




}
/// @nodoc
class _$EmployeeApplicationModelCopyWithImpl<$Res>
    implements $EmployeeApplicationModelCopyWith<$Res> {
  _$EmployeeApplicationModelCopyWithImpl(this._self, this._then);

  final EmployeeApplicationModel _self;
  final $Res Function(EmployeeApplicationModel) _then;

/// Create a copy of EmployeeApplicationModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? employeeId = null,Object? applicationType = null,Object? startDate = null,Object? endDate = freezed,Object? durationDays = null,Object? scanName = null,Object? scanPath = null,Object? scanSize = null,Object? scanType = null,Object? createdBy = null,Object? createdAt = null,Object? creator = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,employeeId: null == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String,applicationType: null == applicationType ? _self.applicationType : applicationType // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,durationDays: null == durationDays ? _self.durationDays : durationDays // ignore: cast_nullable_to_non_nullable
as int,scanName: null == scanName ? _self.scanName : scanName // ignore: cast_nullable_to_non_nullable
as String,scanPath: null == scanPath ? _self.scanPath : scanPath // ignore: cast_nullable_to_non_nullable
as String,scanSize: null == scanSize ? _self.scanSize : scanSize // ignore: cast_nullable_to_non_nullable
as int,scanType: null == scanType ? _self.scanType : scanType // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,creator: freezed == creator ? _self.creator : creator // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _EmployeeApplicationModel extends EmployeeApplicationModel {
  const _EmployeeApplicationModel({required this.id, @JsonKey(name: 'company_id') required this.companyId, @JsonKey(name: 'employee_id') required this.employeeId, @JsonKey(name: 'application_type') required this.applicationType, @JsonKey(name: 'start_date') required this.startDate, @JsonKey(name: 'end_date') this.endDate, @JsonKey(name: 'duration_days') required this.durationDays, @JsonKey(name: 'scan_name') required this.scanName, @JsonKey(name: 'scan_path') required this.scanPath, @JsonKey(name: 'scan_size') required this.scanSize, @JsonKey(name: 'scan_type') required this.scanType, @JsonKey(name: 'created_by') required this.createdBy, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'creator') final  Map<String, dynamic>? creator}): _creator = creator,super._();
  factory _EmployeeApplicationModel.fromJson(Map<String, dynamic> json) => _$EmployeeApplicationModelFromJson(json);

@override final  String id;
@override@JsonKey(name: 'company_id') final  String companyId;
@override@JsonKey(name: 'employee_id') final  String employeeId;
@override@JsonKey(name: 'application_type') final  String applicationType;
@override@JsonKey(name: 'start_date') final  DateTime startDate;
@override@JsonKey(name: 'end_date') final  DateTime? endDate;
@override@JsonKey(name: 'duration_days') final  int durationDays;
@override@JsonKey(name: 'scan_name') final  String scanName;
@override@JsonKey(name: 'scan_path') final  String scanPath;
@override@JsonKey(name: 'scan_size') final  int scanSize;
@override@JsonKey(name: 'scan_type') final  String scanType;
@override@JsonKey(name: 'created_by') final  String createdBy;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
 final  Map<String, dynamic>? _creator;
@override@JsonKey(name: 'creator') Map<String, dynamic>? get creator {
  final value = _creator;
  if (value == null) return null;
  if (_creator is EqualUnmodifiableMapView) return _creator;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of EmployeeApplicationModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EmployeeApplicationModelCopyWith<_EmployeeApplicationModel> get copyWith => __$EmployeeApplicationModelCopyWithImpl<_EmployeeApplicationModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EmployeeApplicationModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EmployeeApplicationModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.applicationType, applicationType) || other.applicationType == applicationType)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.durationDays, durationDays) || other.durationDays == durationDays)&&(identical(other.scanName, scanName) || other.scanName == scanName)&&(identical(other.scanPath, scanPath) || other.scanPath == scanPath)&&(identical(other.scanSize, scanSize) || other.scanSize == scanSize)&&(identical(other.scanType, scanType) || other.scanType == scanType)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other._creator, _creator));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,employeeId,applicationType,startDate,endDate,durationDays,scanName,scanPath,scanSize,scanType,createdBy,createdAt,const DeepCollectionEquality().hash(_creator));

@override
String toString() {
  return 'EmployeeApplicationModel(id: $id, companyId: $companyId, employeeId: $employeeId, applicationType: $applicationType, startDate: $startDate, endDate: $endDate, durationDays: $durationDays, scanName: $scanName, scanPath: $scanPath, scanSize: $scanSize, scanType: $scanType, createdBy: $createdBy, createdAt: $createdAt, creator: $creator)';
}


}

/// @nodoc
abstract mixin class _$EmployeeApplicationModelCopyWith<$Res> implements $EmployeeApplicationModelCopyWith<$Res> {
  factory _$EmployeeApplicationModelCopyWith(_EmployeeApplicationModel value, $Res Function(_EmployeeApplicationModel) _then) = __$EmployeeApplicationModelCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'company_id') String companyId,@JsonKey(name: 'employee_id') String employeeId,@JsonKey(name: 'application_type') String applicationType,@JsonKey(name: 'start_date') DateTime startDate,@JsonKey(name: 'end_date') DateTime? endDate,@JsonKey(name: 'duration_days') int durationDays,@JsonKey(name: 'scan_name') String scanName,@JsonKey(name: 'scan_path') String scanPath,@JsonKey(name: 'scan_size') int scanSize,@JsonKey(name: 'scan_type') String scanType,@JsonKey(name: 'created_by') String createdBy,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'creator') Map<String, dynamic>? creator
});




}
/// @nodoc
class __$EmployeeApplicationModelCopyWithImpl<$Res>
    implements _$EmployeeApplicationModelCopyWith<$Res> {
  __$EmployeeApplicationModelCopyWithImpl(this._self, this._then);

  final _EmployeeApplicationModel _self;
  final $Res Function(_EmployeeApplicationModel) _then;

/// Create a copy of EmployeeApplicationModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? employeeId = null,Object? applicationType = null,Object? startDate = null,Object? endDate = freezed,Object? durationDays = null,Object? scanName = null,Object? scanPath = null,Object? scanSize = null,Object? scanType = null,Object? createdBy = null,Object? createdAt = null,Object? creator = freezed,}) {
  return _then(_EmployeeApplicationModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,employeeId: null == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String,applicationType: null == applicationType ? _self.applicationType : applicationType // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,durationDays: null == durationDays ? _self.durationDays : durationDays // ignore: cast_nullable_to_non_nullable
as int,scanName: null == scanName ? _self.scanName : scanName // ignore: cast_nullable_to_non_nullable
as String,scanPath: null == scanPath ? _self.scanPath : scanPath // ignore: cast_nullable_to_non_nullable
as String,scanSize: null == scanSize ? _self.scanSize : scanSize // ignore: cast_nullable_to_non_nullable
as int,scanType: null == scanType ? _self.scanType : scanType // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,creator: freezed == creator ? _self._creator : creator // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
