// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tmc_notification.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TmcNotification {

/// Идентификатор записи.
 String get id;/// Компания-владелец.
 String get companyId;/// Получатель (пользователь).
 String? get userId;/// Тип уведомления.
 TmcNotificationType get notificationType;/// Заголовок.
 String get title;/// Текст.
 String? get body;/// Связанная позиция.
 String? get itemId;/// Связанная единица.
 String? get unitId;/// Дополнительные данные.
 Map<String, dynamic> get payload;/// Прочитано.
 bool get isRead;/// Дата создания.
 DateTime? get createdAt;
/// Create a copy of TmcNotification
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TmcNotificationCopyWith<TmcNotification> get copyWith => _$TmcNotificationCopyWithImpl<TmcNotification>(this as TmcNotification, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TmcNotification&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.notificationType, notificationType) || other.notificationType == notificationType)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&const DeepCollectionEquality().equals(other.payload, payload)&&(identical(other.isRead, isRead) || other.isRead == isRead)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,userId,notificationType,title,body,itemId,unitId,const DeepCollectionEquality().hash(payload),isRead,createdAt);

@override
String toString() {
  return 'TmcNotification(id: $id, companyId: $companyId, userId: $userId, notificationType: $notificationType, title: $title, body: $body, itemId: $itemId, unitId: $unitId, payload: $payload, isRead: $isRead, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $TmcNotificationCopyWith<$Res>  {
  factory $TmcNotificationCopyWith(TmcNotification value, $Res Function(TmcNotification) _then) = _$TmcNotificationCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String? userId, TmcNotificationType notificationType, String title, String? body, String? itemId, String? unitId, Map<String, dynamic> payload, bool isRead, DateTime? createdAt
});




}
/// @nodoc
class _$TmcNotificationCopyWithImpl<$Res>
    implements $TmcNotificationCopyWith<$Res> {
  _$TmcNotificationCopyWithImpl(this._self, this._then);

  final TmcNotification _self;
  final $Res Function(TmcNotification) _then;

/// Create a copy of TmcNotification
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? userId = freezed,Object? notificationType = null,Object? title = null,Object? body = freezed,Object? itemId = freezed,Object? unitId = freezed,Object? payload = null,Object? isRead = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,notificationType: null == notificationType ? _self.notificationType : notificationType // ignore: cast_nullable_to_non_nullable
as TmcNotificationType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String?,itemId: freezed == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String?,unitId: freezed == unitId ? _self.unitId : unitId // ignore: cast_nullable_to_non_nullable
as String?,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc


class _TmcNotification implements TmcNotification {
  const _TmcNotification({required this.id, required this.companyId, this.userId, required this.notificationType, required this.title, this.body, this.itemId, this.unitId, final  Map<String, dynamic> payload = const {}, this.isRead = false, this.createdAt}): _payload = payload;
  

/// Идентификатор записи.
@override final  String id;
/// Компания-владелец.
@override final  String companyId;
/// Получатель (пользователь).
@override final  String? userId;
/// Тип уведомления.
@override final  TmcNotificationType notificationType;
/// Заголовок.
@override final  String title;
/// Текст.
@override final  String? body;
/// Связанная позиция.
@override final  String? itemId;
/// Связанная единица.
@override final  String? unitId;
/// Дополнительные данные.
 final  Map<String, dynamic> _payload;
/// Дополнительные данные.
@override@JsonKey() Map<String, dynamic> get payload {
  if (_payload is EqualUnmodifiableMapView) return _payload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_payload);
}

/// Прочитано.
@override@JsonKey() final  bool isRead;
/// Дата создания.
@override final  DateTime? createdAt;

/// Create a copy of TmcNotification
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TmcNotificationCopyWith<_TmcNotification> get copyWith => __$TmcNotificationCopyWithImpl<_TmcNotification>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TmcNotification&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.notificationType, notificationType) || other.notificationType == notificationType)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&const DeepCollectionEquality().equals(other._payload, _payload)&&(identical(other.isRead, isRead) || other.isRead == isRead)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,userId,notificationType,title,body,itemId,unitId,const DeepCollectionEquality().hash(_payload),isRead,createdAt);

@override
String toString() {
  return 'TmcNotification(id: $id, companyId: $companyId, userId: $userId, notificationType: $notificationType, title: $title, body: $body, itemId: $itemId, unitId: $unitId, payload: $payload, isRead: $isRead, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$TmcNotificationCopyWith<$Res> implements $TmcNotificationCopyWith<$Res> {
  factory _$TmcNotificationCopyWith(_TmcNotification value, $Res Function(_TmcNotification) _then) = __$TmcNotificationCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String? userId, TmcNotificationType notificationType, String title, String? body, String? itemId, String? unitId, Map<String, dynamic> payload, bool isRead, DateTime? createdAt
});




}
/// @nodoc
class __$TmcNotificationCopyWithImpl<$Res>
    implements _$TmcNotificationCopyWith<$Res> {
  __$TmcNotificationCopyWithImpl(this._self, this._then);

  final _TmcNotification _self;
  final $Res Function(_TmcNotification) _then;

/// Create a copy of TmcNotification
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? userId = freezed,Object? notificationType = null,Object? title = null,Object? body = freezed,Object? itemId = freezed,Object? unitId = freezed,Object? payload = null,Object? isRead = null,Object? createdAt = freezed,}) {
  return _then(_TmcNotification(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,notificationType: null == notificationType ? _self.notificationType : notificationType // ignore: cast_nullable_to_non_nullable
as TmcNotificationType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String?,itemId: freezed == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String?,unitId: freezed == unitId ? _self.unitId : unitId // ignore: cast_nullable_to_non_nullable
as String?,payload: null == payload ? _self._payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
