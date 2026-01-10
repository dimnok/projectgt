// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'work.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Work {

/// Идентификатор смены.
 String? get id;/// Идентификатор компании.
 String get companyId;/// Дата смены.
 DateTime get date;/// Идентификатор объекта.
 String get objectId;/// Идентификатор пользователя, открывшего смену.
 String get openedBy;/// Статус смены (например, open/closed).
 String get status;/// Ссылка на фото смены.
 String? get photoUrl;/// Ссылка на вечернее фото смены.
 String? get eveningPhotoUrl;/// Дата создания записи.
 DateTime? get createdAt;/// Дата последнего обновления.
 DateTime? get updatedAt;/// Общая сумма всех работ в смене.
///
/// Вычисляется автоматически через триггеры БД при изменении work_items.
/// Nullable для обратной совместимости.
 double? get totalAmount;/// Количество работ в смене.
///
/// Вычисляется автоматически через триггеры БД при изменении work_items.
/// Nullable для обратной совместимости.
 int? get itemsCount;/// Количество уникальных сотрудников в смене.
///
/// Вычисляется автоматически через триггеры БД при изменении work_hours.
/// Nullable для обратной совместимости.
 int? get employeesCount;/// ID сообщения Telegram с утренним отчетом.
///
/// Сохраняется при открытии смены для связывания с вечерним отчетом.
/// Используется как reply_to_message_id при закрытии смены.
 int? get telegramMessageId;
/// Create a copy of Work
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkCopyWith<Work> get copyWith => _$WorkCopyWithImpl<Work>(this as Work, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Work&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.date, date) || other.date == date)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.openedBy, openedBy) || other.openedBy == openedBy)&&(identical(other.status, status) || other.status == status)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.eveningPhotoUrl, eveningPhotoUrl) || other.eveningPhotoUrl == eveningPhotoUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.itemsCount, itemsCount) || other.itemsCount == itemsCount)&&(identical(other.employeesCount, employeesCount) || other.employeesCount == employeesCount)&&(identical(other.telegramMessageId, telegramMessageId) || other.telegramMessageId == telegramMessageId));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,date,objectId,openedBy,status,photoUrl,eveningPhotoUrl,createdAt,updatedAt,totalAmount,itemsCount,employeesCount,telegramMessageId);

@override
String toString() {
  return 'Work(id: $id, companyId: $companyId, date: $date, objectId: $objectId, openedBy: $openedBy, status: $status, photoUrl: $photoUrl, eveningPhotoUrl: $eveningPhotoUrl, createdAt: $createdAt, updatedAt: $updatedAt, totalAmount: $totalAmount, itemsCount: $itemsCount, employeesCount: $employeesCount, telegramMessageId: $telegramMessageId)';
}


}

/// @nodoc
abstract mixin class $WorkCopyWith<$Res>  {
  factory $WorkCopyWith(Work value, $Res Function(Work) _then) = _$WorkCopyWithImpl;
@useResult
$Res call({
 String? id, String companyId, DateTime date, String objectId, String openedBy, String status, String? photoUrl, String? eveningPhotoUrl, DateTime? createdAt, DateTime? updatedAt, double? totalAmount, int? itemsCount, int? employeesCount, int? telegramMessageId
});




}
/// @nodoc
class _$WorkCopyWithImpl<$Res>
    implements $WorkCopyWith<$Res> {
  _$WorkCopyWithImpl(this._self, this._then);

  final Work _self;
  final $Res Function(Work) _then;

/// Create a copy of Work
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? companyId = null,Object? date = null,Object? objectId = null,Object? openedBy = null,Object? status = null,Object? photoUrl = freezed,Object? eveningPhotoUrl = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? totalAmount = freezed,Object? itemsCount = freezed,Object? employeesCount = freezed,Object? telegramMessageId = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,objectId: null == objectId ? _self.objectId : objectId // ignore: cast_nullable_to_non_nullable
as String,openedBy: null == openedBy ? _self.openedBy : openedBy // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,eveningPhotoUrl: freezed == eveningPhotoUrl ? _self.eveningPhotoUrl : eveningPhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,totalAmount: freezed == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double?,itemsCount: freezed == itemsCount ? _self.itemsCount : itemsCount // ignore: cast_nullable_to_non_nullable
as int?,employeesCount: freezed == employeesCount ? _self.employeesCount : employeesCount // ignore: cast_nullable_to_non_nullable
as int?,telegramMessageId: freezed == telegramMessageId ? _self.telegramMessageId : telegramMessageId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// @nodoc


class _Work implements Work {
  const _Work({this.id, required this.companyId, required this.date, required this.objectId, required this.openedBy, required this.status, this.photoUrl, this.eveningPhotoUrl, this.createdAt, this.updatedAt, this.totalAmount, this.itemsCount, this.employeesCount, this.telegramMessageId});
  

/// Идентификатор смены.
@override final  String? id;
/// Идентификатор компании.
@override final  String companyId;
/// Дата смены.
@override final  DateTime date;
/// Идентификатор объекта.
@override final  String objectId;
/// Идентификатор пользователя, открывшего смену.
@override final  String openedBy;
/// Статус смены (например, open/closed).
@override final  String status;
/// Ссылка на фото смены.
@override final  String? photoUrl;
/// Ссылка на вечернее фото смены.
@override final  String? eveningPhotoUrl;
/// Дата создания записи.
@override final  DateTime? createdAt;
/// Дата последнего обновления.
@override final  DateTime? updatedAt;
/// Общая сумма всех работ в смене.
///
/// Вычисляется автоматически через триггеры БД при изменении work_items.
/// Nullable для обратной совместимости.
@override final  double? totalAmount;
/// Количество работ в смене.
///
/// Вычисляется автоматически через триггеры БД при изменении work_items.
/// Nullable для обратной совместимости.
@override final  int? itemsCount;
/// Количество уникальных сотрудников в смене.
///
/// Вычисляется автоматически через триггеры БД при изменении work_hours.
/// Nullable для обратной совместимости.
@override final  int? employeesCount;
/// ID сообщения Telegram с утренним отчетом.
///
/// Сохраняется при открытии смены для связывания с вечерним отчетом.
/// Используется как reply_to_message_id при закрытии смены.
@override final  int? telegramMessageId;

/// Create a copy of Work
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkCopyWith<_Work> get copyWith => __$WorkCopyWithImpl<_Work>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Work&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.date, date) || other.date == date)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.openedBy, openedBy) || other.openedBy == openedBy)&&(identical(other.status, status) || other.status == status)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.eveningPhotoUrl, eveningPhotoUrl) || other.eveningPhotoUrl == eveningPhotoUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.itemsCount, itemsCount) || other.itemsCount == itemsCount)&&(identical(other.employeesCount, employeesCount) || other.employeesCount == employeesCount)&&(identical(other.telegramMessageId, telegramMessageId) || other.telegramMessageId == telegramMessageId));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,date,objectId,openedBy,status,photoUrl,eveningPhotoUrl,createdAt,updatedAt,totalAmount,itemsCount,employeesCount,telegramMessageId);

@override
String toString() {
  return 'Work(id: $id, companyId: $companyId, date: $date, objectId: $objectId, openedBy: $openedBy, status: $status, photoUrl: $photoUrl, eveningPhotoUrl: $eveningPhotoUrl, createdAt: $createdAt, updatedAt: $updatedAt, totalAmount: $totalAmount, itemsCount: $itemsCount, employeesCount: $employeesCount, telegramMessageId: $telegramMessageId)';
}


}

/// @nodoc
abstract mixin class _$WorkCopyWith<$Res> implements $WorkCopyWith<$Res> {
  factory _$WorkCopyWith(_Work value, $Res Function(_Work) _then) = __$WorkCopyWithImpl;
@override @useResult
$Res call({
 String? id, String companyId, DateTime date, String objectId, String openedBy, String status, String? photoUrl, String? eveningPhotoUrl, DateTime? createdAt, DateTime? updatedAt, double? totalAmount, int? itemsCount, int? employeesCount, int? telegramMessageId
});




}
/// @nodoc
class __$WorkCopyWithImpl<$Res>
    implements _$WorkCopyWith<$Res> {
  __$WorkCopyWithImpl(this._self, this._then);

  final _Work _self;
  final $Res Function(_Work) _then;

/// Create a copy of Work
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? companyId = null,Object? date = null,Object? objectId = null,Object? openedBy = null,Object? status = null,Object? photoUrl = freezed,Object? eveningPhotoUrl = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? totalAmount = freezed,Object? itemsCount = freezed,Object? employeesCount = freezed,Object? telegramMessageId = freezed,}) {
  return _then(_Work(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,objectId: null == objectId ? _self.objectId : objectId // ignore: cast_nullable_to_non_nullable
as String,openedBy: null == openedBy ? _self.openedBy : openedBy // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,eveningPhotoUrl: freezed == eveningPhotoUrl ? _self.eveningPhotoUrl : eveningPhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,totalAmount: freezed == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double?,itemsCount: freezed == itemsCount ? _self.itemsCount : itemsCount // ignore: cast_nullable_to_non_nullable
as int?,employeesCount: freezed == employeesCount ? _self.employeesCount : employeesCount // ignore: cast_nullable_to_non_nullable
as int?,telegramMessageId: freezed == telegramMessageId ? _self.telegramMessageId : telegramMessageId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
