// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'timesheet_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TimesheetEntry {
  /// Идентификатор записи (совпадает с id в work_hours).
  String get id;

  /// Идентификатор смены.
  String get workId;

  /// Идентификатор сотрудника.
  String get employeeId;

  /// Количество отработанных часов.
  num get hours;

  /// Комментарий к записи.
  String? get comment;

  /// Дата смены (не хранится в work_hours, добавляется из works).
  DateTime get date;

  /// Идентификатор объекта (не хранится в work_hours, добавляется из works).
  String get objectId;

  /// Имя сотрудника для отображения (не хранится в БД).
  String? get employeeName;

  /// Название объекта для отображения (не хранится в БД).
  String? get objectName;

  /// Должность сотрудника (не хранится в БД).
  String? get employeePosition;

  /// Дата создания записи.
  DateTime? get createdAt;

  /// Дата обновления записи.
  DateTime? get updatedAt;

  /// Create a copy of TimesheetEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TimesheetEntryCopyWith<TimesheetEntry> get copyWith =>
      _$TimesheetEntryCopyWithImpl<TimesheetEntry>(
          this as TimesheetEntry, _$identity);

  /// Serializes this TimesheetEntry to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TimesheetEntry &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.workId, workId) || other.workId == workId) &&
            (identical(other.employeeId, employeeId) ||
                other.employeeId == employeeId) &&
            (identical(other.hours, hours) || other.hours == hours) &&
            (identical(other.comment, comment) || other.comment == comment) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.objectId, objectId) ||
                other.objectId == objectId) &&
            (identical(other.employeeName, employeeName) ||
                other.employeeName == employeeName) &&
            (identical(other.objectName, objectName) ||
                other.objectName == objectName) &&
            (identical(other.employeePosition, employeePosition) ||
                other.employeePosition == employeePosition) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      workId,
      employeeId,
      hours,
      comment,
      date,
      objectId,
      employeeName,
      objectName,
      employeePosition,
      createdAt,
      updatedAt);

  @override
  String toString() {
    return 'TimesheetEntry(id: $id, workId: $workId, employeeId: $employeeId, hours: $hours, comment: $comment, date: $date, objectId: $objectId, employeeName: $employeeName, objectName: $objectName, employeePosition: $employeePosition, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class $TimesheetEntryCopyWith<$Res> {
  factory $TimesheetEntryCopyWith(
          TimesheetEntry value, $Res Function(TimesheetEntry) _then) =
      _$TimesheetEntryCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String workId,
      String employeeId,
      num hours,
      String? comment,
      DateTime date,
      String objectId,
      String? employeeName,
      String? objectName,
      String? employeePosition,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class _$TimesheetEntryCopyWithImpl<$Res>
    implements $TimesheetEntryCopyWith<$Res> {
  _$TimesheetEntryCopyWithImpl(this._self, this._then);

  final TimesheetEntry _self;
  final $Res Function(TimesheetEntry) _then;

  /// Create a copy of TimesheetEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? workId = null,
    Object? employeeId = null,
    Object? hours = null,
    Object? comment = freezed,
    Object? date = null,
    Object? objectId = null,
    Object? employeeName = freezed,
    Object? objectName = freezed,
    Object? employeePosition = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      workId: null == workId
          ? _self.workId
          : workId // ignore: cast_nullable_to_non_nullable
              as String,
      employeeId: null == employeeId
          ? _self.employeeId
          : employeeId // ignore: cast_nullable_to_non_nullable
              as String,
      hours: null == hours
          ? _self.hours
          : hours // ignore: cast_nullable_to_non_nullable
              as num,
      comment: freezed == comment
          ? _self.comment
          : comment // ignore: cast_nullable_to_non_nullable
              as String?,
      date: null == date
          ? _self.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      objectId: null == objectId
          ? _self.objectId
          : objectId // ignore: cast_nullable_to_non_nullable
              as String,
      employeeName: freezed == employeeName
          ? _self.employeeName
          : employeeName // ignore: cast_nullable_to_non_nullable
              as String?,
      objectName: freezed == objectName
          ? _self.objectName
          : objectName // ignore: cast_nullable_to_non_nullable
              as String?,
      employeePosition: freezed == employeePosition
          ? _self.employeePosition
          : employeePosition // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _TimesheetEntry implements TimesheetEntry {
  const _TimesheetEntry(
      {required this.id,
      required this.workId,
      required this.employeeId,
      required this.hours,
      this.comment,
      required this.date,
      required this.objectId,
      this.employeeName,
      this.objectName,
      this.employeePosition,
      this.createdAt,
      this.updatedAt});
  factory _TimesheetEntry.fromJson(Map<String, dynamic> json) =>
      _$TimesheetEntryFromJson(json);

  /// Идентификатор записи (совпадает с id в work_hours).
  @override
  final String id;

  /// Идентификатор смены.
  @override
  final String workId;

  /// Идентификатор сотрудника.
  @override
  final String employeeId;

  /// Количество отработанных часов.
  @override
  final num hours;

  /// Комментарий к записи.
  @override
  final String? comment;

  /// Дата смены (не хранится в work_hours, добавляется из works).
  @override
  final DateTime date;

  /// Идентификатор объекта (не хранится в work_hours, добавляется из works).
  @override
  final String objectId;

  /// Имя сотрудника для отображения (не хранится в БД).
  @override
  final String? employeeName;

  /// Название объекта для отображения (не хранится в БД).
  @override
  final String? objectName;

  /// Должность сотрудника (не хранится в БД).
  @override
  final String? employeePosition;

  /// Дата создания записи.
  @override
  final DateTime? createdAt;

  /// Дата обновления записи.
  @override
  final DateTime? updatedAt;

  /// Create a copy of TimesheetEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TimesheetEntryCopyWith<_TimesheetEntry> get copyWith =>
      __$TimesheetEntryCopyWithImpl<_TimesheetEntry>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$TimesheetEntryToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TimesheetEntry &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.workId, workId) || other.workId == workId) &&
            (identical(other.employeeId, employeeId) ||
                other.employeeId == employeeId) &&
            (identical(other.hours, hours) || other.hours == hours) &&
            (identical(other.comment, comment) || other.comment == comment) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.objectId, objectId) ||
                other.objectId == objectId) &&
            (identical(other.employeeName, employeeName) ||
                other.employeeName == employeeName) &&
            (identical(other.objectName, objectName) ||
                other.objectName == objectName) &&
            (identical(other.employeePosition, employeePosition) ||
                other.employeePosition == employeePosition) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      workId,
      employeeId,
      hours,
      comment,
      date,
      objectId,
      employeeName,
      objectName,
      employeePosition,
      createdAt,
      updatedAt);

  @override
  String toString() {
    return 'TimesheetEntry(id: $id, workId: $workId, employeeId: $employeeId, hours: $hours, comment: $comment, date: $date, objectId: $objectId, employeeName: $employeeName, objectName: $objectName, employeePosition: $employeePosition, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$TimesheetEntryCopyWith<$Res>
    implements $TimesheetEntryCopyWith<$Res> {
  factory _$TimesheetEntryCopyWith(
          _TimesheetEntry value, $Res Function(_TimesheetEntry) _then) =
      __$TimesheetEntryCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String workId,
      String employeeId,
      num hours,
      String? comment,
      DateTime date,
      String objectId,
      String? employeeName,
      String? objectName,
      String? employeePosition,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class __$TimesheetEntryCopyWithImpl<$Res>
    implements _$TimesheetEntryCopyWith<$Res> {
  __$TimesheetEntryCopyWithImpl(this._self, this._then);

  final _TimesheetEntry _self;
  final $Res Function(_TimesheetEntry) _then;

  /// Create a copy of TimesheetEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? workId = null,
    Object? employeeId = null,
    Object? hours = null,
    Object? comment = freezed,
    Object? date = null,
    Object? objectId = null,
    Object? employeeName = freezed,
    Object? objectName = freezed,
    Object? employeePosition = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_TimesheetEntry(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      workId: null == workId
          ? _self.workId
          : workId // ignore: cast_nullable_to_non_nullable
              as String,
      employeeId: null == employeeId
          ? _self.employeeId
          : employeeId // ignore: cast_nullable_to_non_nullable
              as String,
      hours: null == hours
          ? _self.hours
          : hours // ignore: cast_nullable_to_non_nullable
              as num,
      comment: freezed == comment
          ? _self.comment
          : comment // ignore: cast_nullable_to_non_nullable
              as String?,
      date: null == date
          ? _self.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      objectId: null == objectId
          ? _self.objectId
          : objectId // ignore: cast_nullable_to_non_nullable
              as String,
      employeeName: freezed == employeeName
          ? _self.employeeName
          : employeeName // ignore: cast_nullable_to_non_nullable
              as String?,
      objectName: freezed == objectName
          ? _self.objectName
          : objectName // ignore: cast_nullable_to_non_nullable
              as String?,
      employeePosition: freezed == employeePosition
          ? _self.employeePosition
          : employeePosition // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

// dart format on
