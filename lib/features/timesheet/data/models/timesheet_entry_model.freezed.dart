// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'timesheet_entry_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TimesheetEntryModel {
  /// Идентификатор записи.
  String get id;

  /// Идентификатор смены.
  String get workId;

  /// Идентификатор сотрудника.
  String get employeeId;

  /// Количество отработанных часов.
  num get hours;

  /// Комментарий к записи.
  String? get comment;

  /// Дата смены.
  DateTime get date;

  /// Идентификатор объекта.
  String get objectId;

  /// Имя сотрудника для отображения.
  String? get employeeName;

  /// Название объекта для отображения.
  String? get objectName;

  /// Дата создания записи.
  DateTime? get createdAt;

  /// Дата обновления записи.
  DateTime? get updatedAt;

  /// Create a copy of TimesheetEntryModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TimesheetEntryModelCopyWith<TimesheetEntryModel> get copyWith =>
      _$TimesheetEntryModelCopyWithImpl<TimesheetEntryModel>(
          this as TimesheetEntryModel, _$identity);

  /// Serializes this TimesheetEntryModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TimesheetEntryModel &&
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
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, workId, employeeId, hours,
      comment, date, objectId, employeeName, objectName, createdAt, updatedAt);

  @override
  String toString() {
    return 'TimesheetEntryModel(id: $id, workId: $workId, employeeId: $employeeId, hours: $hours, comment: $comment, date: $date, objectId: $objectId, employeeName: $employeeName, objectName: $objectName, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class $TimesheetEntryModelCopyWith<$Res> {
  factory $TimesheetEntryModelCopyWith(
          TimesheetEntryModel value, $Res Function(TimesheetEntryModel) _then) =
      _$TimesheetEntryModelCopyWithImpl;
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
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class _$TimesheetEntryModelCopyWithImpl<$Res>
    implements $TimesheetEntryModelCopyWith<$Res> {
  _$TimesheetEntryModelCopyWithImpl(this._self, this._then);

  final TimesheetEntryModel _self;
  final $Res Function(TimesheetEntryModel) _then;

  /// Create a copy of TimesheetEntryModel
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
class _TimesheetEntryModel implements TimesheetEntryModel {
  const _TimesheetEntryModel(
      {required this.id,
      required this.workId,
      required this.employeeId,
      required this.hours,
      this.comment,
      required this.date,
      required this.objectId,
      this.employeeName,
      this.objectName,
      this.createdAt,
      this.updatedAt});
  factory _TimesheetEntryModel.fromJson(Map<String, dynamic> json) =>
      _$TimesheetEntryModelFromJson(json);

  /// Идентификатор записи.
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

  /// Дата смены.
  @override
  final DateTime date;

  /// Идентификатор объекта.
  @override
  final String objectId;

  /// Имя сотрудника для отображения.
  @override
  final String? employeeName;

  /// Название объекта для отображения.
  @override
  final String? objectName;

  /// Дата создания записи.
  @override
  final DateTime? createdAt;

  /// Дата обновления записи.
  @override
  final DateTime? updatedAt;

  /// Create a copy of TimesheetEntryModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TimesheetEntryModelCopyWith<_TimesheetEntryModel> get copyWith =>
      __$TimesheetEntryModelCopyWithImpl<_TimesheetEntryModel>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$TimesheetEntryModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TimesheetEntryModel &&
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
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, workId, employeeId, hours,
      comment, date, objectId, employeeName, objectName, createdAt, updatedAt);

  @override
  String toString() {
    return 'TimesheetEntryModel(id: $id, workId: $workId, employeeId: $employeeId, hours: $hours, comment: $comment, date: $date, objectId: $objectId, employeeName: $employeeName, objectName: $objectName, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$TimesheetEntryModelCopyWith<$Res>
    implements $TimesheetEntryModelCopyWith<$Res> {
  factory _$TimesheetEntryModelCopyWith(_TimesheetEntryModel value,
          $Res Function(_TimesheetEntryModel) _then) =
      __$TimesheetEntryModelCopyWithImpl;
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
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class __$TimesheetEntryModelCopyWithImpl<$Res>
    implements _$TimesheetEntryModelCopyWith<$Res> {
  __$TimesheetEntryModelCopyWithImpl(this._self, this._then);

  final _TimesheetEntryModel _self;
  final $Res Function(_TimesheetEntryModel) _then;

  /// Create a copy of TimesheetEntryModel
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
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_TimesheetEntryModel(
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
