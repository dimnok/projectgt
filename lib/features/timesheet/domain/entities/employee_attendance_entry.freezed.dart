// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'employee_attendance_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EmployeeAttendanceEntry {

/// Уникальный идентификатор записи
 String get id;/// ID компании
 String get companyId;/// ID сотрудника
 String get employeeId;/// ID объекта (например, ЦОД Дубна, Офис)
 String get objectId;/// Дата работы
 DateTime get date;/// Количество отработанных часов
 num get hours;/// Тип посещаемости
 AttendanceType get attendanceType;/// Комментарий к записи
 String? get comment;/// Кто создал запись
 String? get createdBy;/// Дата и время создания записи
 DateTime? get createdAt;/// Дата и время последнего обновления записи
 DateTime? get updatedAt;// Обогащённые данные (не из БД)
/// ФИО сотрудника
 String? get employeeName;/// Должность сотрудника
 String? get employeePosition;/// Название объекта
 String? get objectName;
/// Create a copy of EmployeeAttendanceEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmployeeAttendanceEntryCopyWith<EmployeeAttendanceEntry> get copyWith => _$EmployeeAttendanceEntryCopyWithImpl<EmployeeAttendanceEntry>(this as EmployeeAttendanceEntry, _$identity);

  /// Serializes this EmployeeAttendanceEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmployeeAttendanceEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.date, date) || other.date == date)&&(identical(other.hours, hours) || other.hours == hours)&&(identical(other.attendanceType, attendanceType) || other.attendanceType == attendanceType)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.employeeName, employeeName) || other.employeeName == employeeName)&&(identical(other.employeePosition, employeePosition) || other.employeePosition == employeePosition)&&(identical(other.objectName, objectName) || other.objectName == objectName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,employeeId,objectId,date,hours,attendanceType,comment,createdBy,createdAt,updatedAt,employeeName,employeePosition,objectName);

@override
String toString() {
  return 'EmployeeAttendanceEntry(id: $id, companyId: $companyId, employeeId: $employeeId, objectId: $objectId, date: $date, hours: $hours, attendanceType: $attendanceType, comment: $comment, createdBy: $createdBy, createdAt: $createdAt, updatedAt: $updatedAt, employeeName: $employeeName, employeePosition: $employeePosition, objectName: $objectName)';
}


}

/// @nodoc
abstract mixin class $EmployeeAttendanceEntryCopyWith<$Res>  {
  factory $EmployeeAttendanceEntryCopyWith(EmployeeAttendanceEntry value, $Res Function(EmployeeAttendanceEntry) _then) = _$EmployeeAttendanceEntryCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String employeeId, String objectId, DateTime date, num hours, AttendanceType attendanceType, String? comment, String? createdBy, DateTime? createdAt, DateTime? updatedAt, String? employeeName, String? employeePosition, String? objectName
});




}
/// @nodoc
class _$EmployeeAttendanceEntryCopyWithImpl<$Res>
    implements $EmployeeAttendanceEntryCopyWith<$Res> {
  _$EmployeeAttendanceEntryCopyWithImpl(this._self, this._then);

  final EmployeeAttendanceEntry _self;
  final $Res Function(EmployeeAttendanceEntry) _then;

/// Create a copy of EmployeeAttendanceEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? employeeId = null,Object? objectId = null,Object? date = null,Object? hours = null,Object? attendanceType = null,Object? comment = freezed,Object? createdBy = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? employeeName = freezed,Object? employeePosition = freezed,Object? objectName = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,employeeId: null == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String,objectId: null == objectId ? _self.objectId : objectId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,hours: null == hours ? _self.hours : hours // ignore: cast_nullable_to_non_nullable
as num,attendanceType: null == attendanceType ? _self.attendanceType : attendanceType // ignore: cast_nullable_to_non_nullable
as AttendanceType,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,employeeName: freezed == employeeName ? _self.employeeName : employeeName // ignore: cast_nullable_to_non_nullable
as String?,employeePosition: freezed == employeePosition ? _self.employeePosition : employeePosition // ignore: cast_nullable_to_non_nullable
as String?,objectName: freezed == objectName ? _self.objectName : objectName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _EmployeeAttendanceEntry implements EmployeeAttendanceEntry {
  const _EmployeeAttendanceEntry({required this.id, required this.companyId, required this.employeeId, required this.objectId, required this.date, required this.hours, this.attendanceType = AttendanceType.work, this.comment, this.createdBy, this.createdAt, this.updatedAt, this.employeeName, this.employeePosition, this.objectName});
  factory _EmployeeAttendanceEntry.fromJson(Map<String, dynamic> json) => _$EmployeeAttendanceEntryFromJson(json);

/// Уникальный идентификатор записи
@override final  String id;
/// ID компании
@override final  String companyId;
/// ID сотрудника
@override final  String employeeId;
/// ID объекта (например, ЦОД Дубна, Офис)
@override final  String objectId;
/// Дата работы
@override final  DateTime date;
/// Количество отработанных часов
@override final  num hours;
/// Тип посещаемости
@override@JsonKey() final  AttendanceType attendanceType;
/// Комментарий к записи
@override final  String? comment;
/// Кто создал запись
@override final  String? createdBy;
/// Дата и время создания записи
@override final  DateTime? createdAt;
/// Дата и время последнего обновления записи
@override final  DateTime? updatedAt;
// Обогащённые данные (не из БД)
/// ФИО сотрудника
@override final  String? employeeName;
/// Должность сотрудника
@override final  String? employeePosition;
/// Название объекта
@override final  String? objectName;

/// Create a copy of EmployeeAttendanceEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EmployeeAttendanceEntryCopyWith<_EmployeeAttendanceEntry> get copyWith => __$EmployeeAttendanceEntryCopyWithImpl<_EmployeeAttendanceEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EmployeeAttendanceEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EmployeeAttendanceEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.date, date) || other.date == date)&&(identical(other.hours, hours) || other.hours == hours)&&(identical(other.attendanceType, attendanceType) || other.attendanceType == attendanceType)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.employeeName, employeeName) || other.employeeName == employeeName)&&(identical(other.employeePosition, employeePosition) || other.employeePosition == employeePosition)&&(identical(other.objectName, objectName) || other.objectName == objectName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,employeeId,objectId,date,hours,attendanceType,comment,createdBy,createdAt,updatedAt,employeeName,employeePosition,objectName);

@override
String toString() {
  return 'EmployeeAttendanceEntry(id: $id, companyId: $companyId, employeeId: $employeeId, objectId: $objectId, date: $date, hours: $hours, attendanceType: $attendanceType, comment: $comment, createdBy: $createdBy, createdAt: $createdAt, updatedAt: $updatedAt, employeeName: $employeeName, employeePosition: $employeePosition, objectName: $objectName)';
}


}

/// @nodoc
abstract mixin class _$EmployeeAttendanceEntryCopyWith<$Res> implements $EmployeeAttendanceEntryCopyWith<$Res> {
  factory _$EmployeeAttendanceEntryCopyWith(_EmployeeAttendanceEntry value, $Res Function(_EmployeeAttendanceEntry) _then) = __$EmployeeAttendanceEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String employeeId, String objectId, DateTime date, num hours, AttendanceType attendanceType, String? comment, String? createdBy, DateTime? createdAt, DateTime? updatedAt, String? employeeName, String? employeePosition, String? objectName
});




}
/// @nodoc
class __$EmployeeAttendanceEntryCopyWithImpl<$Res>
    implements _$EmployeeAttendanceEntryCopyWith<$Res> {
  __$EmployeeAttendanceEntryCopyWithImpl(this._self, this._then);

  final _EmployeeAttendanceEntry _self;
  final $Res Function(_EmployeeAttendanceEntry) _then;

/// Create a copy of EmployeeAttendanceEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? employeeId = null,Object? objectId = null,Object? date = null,Object? hours = null,Object? attendanceType = null,Object? comment = freezed,Object? createdBy = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? employeeName = freezed,Object? employeePosition = freezed,Object? objectName = freezed,}) {
  return _then(_EmployeeAttendanceEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,employeeId: null == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String,objectId: null == objectId ? _self.objectId : objectId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,hours: null == hours ? _self.hours : hours // ignore: cast_nullable_to_non_nullable
as num,attendanceType: null == attendanceType ? _self.attendanceType : attendanceType // ignore: cast_nullable_to_non_nullable
as AttendanceType,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,employeeName: freezed == employeeName ? _self.employeeName : employeeName // ignore: cast_nullable_to_non_nullable
as String?,employeePosition: freezed == employeePosition ? _self.employeePosition : employeePosition // ignore: cast_nullable_to_non_nullable
as String?,objectName: freezed == objectName ? _self.objectName : objectName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
