// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'work_hour_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WorkHourModel {

/// Идентификатор записи.
 String get id;/// Идентификатор компании.
 String get companyId;/// Идентификатор смены.
 String get workId;/// Идентификатор сотрудника.
 String get employeeId;/// Количество часов.
 num get hours;/// Комментарий к записи.
 String? get comment;/// Дата создания записи.
 DateTime? get createdAt;/// Дата последнего обновления.
 DateTime? get updatedAt;
/// Create a copy of WorkHourModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkHourModelCopyWith<WorkHourModel> get copyWith => _$WorkHourModelCopyWithImpl<WorkHourModel>(this as WorkHourModel, _$identity);

  /// Serializes this WorkHourModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkHourModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.workId, workId) || other.workId == workId)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.hours, hours) || other.hours == hours)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,workId,employeeId,hours,comment,createdAt,updatedAt);

@override
String toString() {
  return 'WorkHourModel(id: $id, companyId: $companyId, workId: $workId, employeeId: $employeeId, hours: $hours, comment: $comment, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $WorkHourModelCopyWith<$Res>  {
  factory $WorkHourModelCopyWith(WorkHourModel value, $Res Function(WorkHourModel) _then) = _$WorkHourModelCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String workId, String employeeId, num hours, String? comment, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$WorkHourModelCopyWithImpl<$Res>
    implements $WorkHourModelCopyWith<$Res> {
  _$WorkHourModelCopyWithImpl(this._self, this._then);

  final WorkHourModel _self;
  final $Res Function(WorkHourModel) _then;

/// Create a copy of WorkHourModel
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
class _WorkHourModel implements WorkHourModel {
  const _WorkHourModel({required this.id, required this.companyId, required this.workId, required this.employeeId, required this.hours, this.comment, this.createdAt, this.updatedAt});
  factory _WorkHourModel.fromJson(Map<String, dynamic> json) => _$WorkHourModelFromJson(json);

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

/// Create a copy of WorkHourModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkHourModelCopyWith<_WorkHourModel> get copyWith => __$WorkHourModelCopyWithImpl<_WorkHourModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkHourModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkHourModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.workId, workId) || other.workId == workId)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.hours, hours) || other.hours == hours)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,workId,employeeId,hours,comment,createdAt,updatedAt);

@override
String toString() {
  return 'WorkHourModel(id: $id, companyId: $companyId, workId: $workId, employeeId: $employeeId, hours: $hours, comment: $comment, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$WorkHourModelCopyWith<$Res> implements $WorkHourModelCopyWith<$Res> {
  factory _$WorkHourModelCopyWith(_WorkHourModel value, $Res Function(_WorkHourModel) _then) = __$WorkHourModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String workId, String employeeId, num hours, String? comment, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$WorkHourModelCopyWithImpl<$Res>
    implements _$WorkHourModelCopyWith<$Res> {
  __$WorkHourModelCopyWithImpl(this._self, this._then);

  final _WorkHourModel _self;
  final $Res Function(_WorkHourModel) _then;

/// Create a copy of WorkHourModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? workId = null,Object? employeeId = null,Object? hours = null,Object? comment = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_WorkHourModel(
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
