// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'work_hour.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WorkHour {

/// Идентификатор записи.
 String get id;/// Идентификатор компании.
 String get companyId;/// Идентификатор смены.
 String get workId;/// Идентификатор сотрудника.
 String get employeeId;/// Количество часов.
 num get hours;/// Комментарий к записи.
 String? get comment;/// Дата создания записи.
 DateTime? get createdAt;/// Дата последнего обновления.
 DateTime? get updatedAt;
/// Create a copy of WorkHour
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkHourCopyWith<WorkHour> get copyWith => _$WorkHourCopyWithImpl<WorkHour>(this as WorkHour, _$identity);

  /// Serializes this WorkHour to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkHour&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.workId, workId) || other.workId == workId)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.hours, hours) || other.hours == hours)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,workId,employeeId,hours,comment,createdAt,updatedAt);

@override
String toString() {
  return 'WorkHour(id: $id, companyId: $companyId, workId: $workId, employeeId: $employeeId, hours: $hours, comment: $comment, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $WorkHourCopyWith<$Res>  {
  factory $WorkHourCopyWith(WorkHour value, $Res Function(WorkHour) _then) = _$WorkHourCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String workId, String employeeId, num hours, String? comment, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$WorkHourCopyWithImpl<$Res>
    implements $WorkHourCopyWith<$Res> {
  _$WorkHourCopyWithImpl(this._self, this._then);

  final WorkHour _self;
  final $Res Function(WorkHour) _then;

/// Create a copy of WorkHour
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? workId = null,Object? employeeId = null,Object? hours = null,Object? comment = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,workId: null == workId ? _self.workId : workId // ignore: cast_nullable_to_non_nullable
as String,employeeId: null == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String,hours: null == hours ? _self.hours : hours // ignore: cast_nullable_to_non_nullable
as num,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _WorkHour implements WorkHour {
  const _WorkHour({required this.id, required this.companyId, required this.workId, required this.employeeId, required this.hours, this.comment, this.createdAt, this.updatedAt});
  factory _WorkHour.fromJson(Map<String, dynamic> json) => _$WorkHourFromJson(json);

/// Идентификатор записи.
@override final  String id;
/// Идентификатор компании.
@override final  String companyId;
/// Идентификатор смены.
@override final  String workId;
/// Идентификатор сотрудника.
@override final  String employeeId;
/// Количество часов.
@override final  num hours;
/// Комментарий к записи.
@override final  String? comment;
/// Дата создания записи.
@override final  DateTime? createdAt;
/// Дата последнего обновления.
@override final  DateTime? updatedAt;

/// Create a copy of WorkHour
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkHourCopyWith<_WorkHour> get copyWith => __$WorkHourCopyWithImpl<_WorkHour>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkHourToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkHour&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.workId, workId) || other.workId == workId)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.hours, hours) || other.hours == hours)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,workId,employeeId,hours,comment,createdAt,updatedAt);

@override
String toString() {
  return 'WorkHour(id: $id, companyId: $companyId, workId: $workId, employeeId: $employeeId, hours: $hours, comment: $comment, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$WorkHourCopyWith<$Res> implements $WorkHourCopyWith<$Res> {
  factory _$WorkHourCopyWith(_WorkHour value, $Res Function(_WorkHour) _then) = __$WorkHourCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String workId, String employeeId, num hours, String? comment, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$WorkHourCopyWithImpl<$Res>
    implements _$WorkHourCopyWith<$Res> {
  __$WorkHourCopyWithImpl(this._self, this._then);

  final _WorkHour _self;
  final $Res Function(_WorkHour) _then;

/// Create a copy of WorkHour
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? workId = null,Object? employeeId = null,Object? hours = null,Object? comment = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_WorkHour(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,workId: null == workId ? _self.workId : workId // ignore: cast_nullable_to_non_nullable
as String,employeeId: null == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String,hours: null == hours ? _self.hours : hours // ignore: cast_nullable_to_non_nullable
as num,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
