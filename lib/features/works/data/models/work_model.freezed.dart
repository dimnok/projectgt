// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'work_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WorkModel {
  /// Идентификатор смены.
  String? get id;

  /// Дата смены.
  @JsonKey(name: 'date')
  DateTime get date;

  /// Идентификатор объекта.
  @JsonKey(name: 'object_id')
  String get objectId;

  /// Идентификатор пользователя, открывшего смену.
  @JsonKey(name: 'opened_by')
  String get openedBy;

  /// Статус смены.
  @JsonKey(name: 'status')
  String get status;

  /// Ссылка на фото смены.
  @JsonKey(name: 'photo_url')
  String? get photoUrl;

  /// Ссылка на вечернее фото смены.
  @JsonKey(name: 'evening_photo_url')
  String? get eveningPhotoUrl;

  /// Дата создания записи.
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;

  /// Дата последнего обновления.
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Общая сумма всех работ в смене.
  ///
  /// Вычисляется автоматически через триггеры БД.
  @JsonKey(name: 'total_amount')
  double? get totalAmount;

  /// Количество работ в смене.
  ///
  /// Вычисляется автоматически через триггеры БД.
  @JsonKey(name: 'items_count')
  int? get itemsCount;

  /// Количество уникальных сотрудников в смене.
  ///
  /// Вычисляется автоматически через триггеры БД.
  @JsonKey(name: 'employees_count')
  int? get employeesCount;

  /// Create a copy of WorkModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WorkModelCopyWith<WorkModel> get copyWith =>
      _$WorkModelCopyWithImpl<WorkModel>(this as WorkModel, _$identity);

  /// Serializes this WorkModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WorkModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.objectId, objectId) ||
                other.objectId == objectId) &&
            (identical(other.openedBy, openedBy) ||
                other.openedBy == openedBy) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.eveningPhotoUrl, eveningPhotoUrl) ||
                other.eveningPhotoUrl == eveningPhotoUrl) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.totalAmount, totalAmount) ||
                other.totalAmount == totalAmount) &&
            (identical(other.itemsCount, itemsCount) ||
                other.itemsCount == itemsCount) &&
            (identical(other.employeesCount, employeesCount) ||
                other.employeesCount == employeesCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      date,
      objectId,
      openedBy,
      status,
      photoUrl,
      eveningPhotoUrl,
      createdAt,
      updatedAt,
      totalAmount,
      itemsCount,
      employeesCount);

  @override
  String toString() {
    return 'WorkModel(id: $id, date: $date, objectId: $objectId, openedBy: $openedBy, status: $status, photoUrl: $photoUrl, eveningPhotoUrl: $eveningPhotoUrl, createdAt: $createdAt, updatedAt: $updatedAt, totalAmount: $totalAmount, itemsCount: $itemsCount, employeesCount: $employeesCount)';
  }
}

/// @nodoc
abstract mixin class $WorkModelCopyWith<$Res> {
  factory $WorkModelCopyWith(WorkModel value, $Res Function(WorkModel) _then) =
      _$WorkModelCopyWithImpl;
  @useResult
  $Res call(
      {String? id,
      @JsonKey(name: 'date') DateTime date,
      @JsonKey(name: 'object_id') String objectId,
      @JsonKey(name: 'opened_by') String openedBy,
      @JsonKey(name: 'status') String status,
      @JsonKey(name: 'photo_url') String? photoUrl,
      @JsonKey(name: 'evening_photo_url') String? eveningPhotoUrl,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
      @JsonKey(name: 'total_amount') double? totalAmount,
      @JsonKey(name: 'items_count') int? itemsCount,
      @JsonKey(name: 'employees_count') int? employeesCount});
}

/// @nodoc
class _$WorkModelCopyWithImpl<$Res> implements $WorkModelCopyWith<$Res> {
  _$WorkModelCopyWithImpl(this._self, this._then);

  final WorkModel _self;
  final $Res Function(WorkModel) _then;

  /// Create a copy of WorkModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? date = null,
    Object? objectId = null,
    Object? openedBy = null,
    Object? status = null,
    Object? photoUrl = freezed,
    Object? eveningPhotoUrl = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? totalAmount = freezed,
    Object? itemsCount = freezed,
    Object? employeesCount = freezed,
  }) {
    return _then(_self.copyWith(
      id: freezed == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      date: null == date
          ? _self.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      objectId: null == objectId
          ? _self.objectId
          : objectId // ignore: cast_nullable_to_non_nullable
              as String,
      openedBy: null == openedBy
          ? _self.openedBy
          : openedBy // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      photoUrl: freezed == photoUrl
          ? _self.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      eveningPhotoUrl: freezed == eveningPhotoUrl
          ? _self.eveningPhotoUrl
          : eveningPhotoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      totalAmount: freezed == totalAmount
          ? _self.totalAmount
          : totalAmount // ignore: cast_nullable_to_non_nullable
              as double?,
      itemsCount: freezed == itemsCount
          ? _self.itemsCount
          : itemsCount // ignore: cast_nullable_to_non_nullable
              as int?,
      employeesCount: freezed == employeesCount
          ? _self.employeesCount
          : employeesCount // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _WorkModel implements WorkModel {
  const _WorkModel(
      {this.id,
      @JsonKey(name: 'date') required this.date,
      @JsonKey(name: 'object_id') required this.objectId,
      @JsonKey(name: 'opened_by') required this.openedBy,
      @JsonKey(name: 'status') required this.status,
      @JsonKey(name: 'photo_url') this.photoUrl,
      @JsonKey(name: 'evening_photo_url') this.eveningPhotoUrl,
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'updated_at') this.updatedAt,
      @JsonKey(name: 'total_amount') this.totalAmount,
      @JsonKey(name: 'items_count') this.itemsCount,
      @JsonKey(name: 'employees_count') this.employeesCount});
  factory _WorkModel.fromJson(Map<String, dynamic> json) =>
      _$WorkModelFromJson(json);

  /// Идентификатор смены.
  @override
  final String? id;

  /// Дата смены.
  @override
  @JsonKey(name: 'date')
  final DateTime date;

  /// Идентификатор объекта.
  @override
  @JsonKey(name: 'object_id')
  final String objectId;

  /// Идентификатор пользователя, открывшего смену.
  @override
  @JsonKey(name: 'opened_by')
  final String openedBy;

  /// Статус смены.
  @override
  @JsonKey(name: 'status')
  final String status;

  /// Ссылка на фото смены.
  @override
  @JsonKey(name: 'photo_url')
  final String? photoUrl;

  /// Ссылка на вечернее фото смены.
  @override
  @JsonKey(name: 'evening_photo_url')
  final String? eveningPhotoUrl;

  /// Дата создания записи.
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  /// Дата последнего обновления.
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  /// Общая сумма всех работ в смене.
  ///
  /// Вычисляется автоматически через триггеры БД.
  @override
  @JsonKey(name: 'total_amount')
  final double? totalAmount;

  /// Количество работ в смене.
  ///
  /// Вычисляется автоматически через триггеры БД.
  @override
  @JsonKey(name: 'items_count')
  final int? itemsCount;

  /// Количество уникальных сотрудников в смене.
  ///
  /// Вычисляется автоматически через триггеры БД.
  @override
  @JsonKey(name: 'employees_count')
  final int? employeesCount;

  /// Create a copy of WorkModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$WorkModelCopyWith<_WorkModel> get copyWith =>
      __$WorkModelCopyWithImpl<_WorkModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$WorkModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _WorkModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.objectId, objectId) ||
                other.objectId == objectId) &&
            (identical(other.openedBy, openedBy) ||
                other.openedBy == openedBy) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.eveningPhotoUrl, eveningPhotoUrl) ||
                other.eveningPhotoUrl == eveningPhotoUrl) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.totalAmount, totalAmount) ||
                other.totalAmount == totalAmount) &&
            (identical(other.itemsCount, itemsCount) ||
                other.itemsCount == itemsCount) &&
            (identical(other.employeesCount, employeesCount) ||
                other.employeesCount == employeesCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      date,
      objectId,
      openedBy,
      status,
      photoUrl,
      eveningPhotoUrl,
      createdAt,
      updatedAt,
      totalAmount,
      itemsCount,
      employeesCount);

  @override
  String toString() {
    return 'WorkModel(id: $id, date: $date, objectId: $objectId, openedBy: $openedBy, status: $status, photoUrl: $photoUrl, eveningPhotoUrl: $eveningPhotoUrl, createdAt: $createdAt, updatedAt: $updatedAt, totalAmount: $totalAmount, itemsCount: $itemsCount, employeesCount: $employeesCount)';
  }
}

/// @nodoc
abstract mixin class _$WorkModelCopyWith<$Res>
    implements $WorkModelCopyWith<$Res> {
  factory _$WorkModelCopyWith(
          _WorkModel value, $Res Function(_WorkModel) _then) =
      __$WorkModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String? id,
      @JsonKey(name: 'date') DateTime date,
      @JsonKey(name: 'object_id') String objectId,
      @JsonKey(name: 'opened_by') String openedBy,
      @JsonKey(name: 'status') String status,
      @JsonKey(name: 'photo_url') String? photoUrl,
      @JsonKey(name: 'evening_photo_url') String? eveningPhotoUrl,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
      @JsonKey(name: 'total_amount') double? totalAmount,
      @JsonKey(name: 'items_count') int? itemsCount,
      @JsonKey(name: 'employees_count') int? employeesCount});
}

/// @nodoc
class __$WorkModelCopyWithImpl<$Res> implements _$WorkModelCopyWith<$Res> {
  __$WorkModelCopyWithImpl(this._self, this._then);

  final _WorkModel _self;
  final $Res Function(_WorkModel) _then;

  /// Create a copy of WorkModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = freezed,
    Object? date = null,
    Object? objectId = null,
    Object? openedBy = null,
    Object? status = null,
    Object? photoUrl = freezed,
    Object? eveningPhotoUrl = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? totalAmount = freezed,
    Object? itemsCount = freezed,
    Object? employeesCount = freezed,
  }) {
    return _then(_WorkModel(
      id: freezed == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      date: null == date
          ? _self.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      objectId: null == objectId
          ? _self.objectId
          : objectId // ignore: cast_nullable_to_non_nullable
              as String,
      openedBy: null == openedBy
          ? _self.openedBy
          : openedBy // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      photoUrl: freezed == photoUrl
          ? _self.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      eveningPhotoUrl: freezed == eveningPhotoUrl
          ? _self.eveningPhotoUrl
          : eveningPhotoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      totalAmount: freezed == totalAmount
          ? _self.totalAmount
          : totalAmount // ignore: cast_nullable_to_non_nullable
              as double?,
      itemsCount: freezed == itemsCount
          ? _self.itemsCount
          : itemsCount // ignore: cast_nullable_to_non_nullable
              as int?,
      employeesCount: freezed == employeesCount
          ? _self.employeesCount
          : employeesCount // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

// dart format on
