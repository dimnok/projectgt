// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tmc_notification_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TmcNotificationModel {

 String get id; String get companyId; String? get userId; TmcNotificationType get notificationType; String get title; String? get body; String? get itemId; String? get unitId; Map<String, dynamic> get payload; bool get isRead; DateTime? get createdAt;
/// Create a copy of TmcNotificationModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TmcNotificationModelCopyWith<TmcNotificationModel> get copyWith => _$TmcNotificationModelCopyWithImpl<TmcNotificationModel>(this as TmcNotificationModel, _$identity);

  /// Serializes this TmcNotificationModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TmcNotificationModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.notificationType, notificationType) || other.notificationType == notificationType)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&const DeepCollectionEquality().equals(other.payload, payload)&&(identical(other.isRead, isRead) || other.isRead == isRead)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,userId,notificationType,title,body,itemId,unitId,const DeepCollectionEquality().hash(payload),isRead,createdAt);

@override
String toString() {
  return 'TmcNotificationModel(id: $id, companyId: $companyId, userId: $userId, notificationType: $notificationType, title: $title, body: $body, itemId: $itemId, unitId: $unitId, payload: $payload, isRead: $isRead, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $TmcNotificationModelCopyWith<$Res>  {
  factory $TmcNotificationModelCopyWith(TmcNotificationModel value, $Res Function(TmcNotificationModel) _then) = _$TmcNotificationModelCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String? userId, TmcNotificationType notificationType, String title, String? body, String? itemId, String? unitId, Map<String, dynamic> payload, bool isRead, DateTime? createdAt
});




}
/// @nodoc
class _$TmcNotificationModelCopyWithImpl<$Res>
    implements $TmcNotificationModelCopyWith<$Res> {
  _$TmcNotificationModelCopyWithImpl(this._self, this._then);

  final TmcNotificationModel _self;
  final $Res Function(TmcNotificationModel) _then;

/// Create a copy of TmcNotificationModel
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

@JsonSerializable(fieldRename: FieldRename.snake)
class _TmcNotificationModel extends TmcNotificationModel {
  const _TmcNotificationModel({required this.id, required this.companyId, this.userId, required this.notificationType, required this.title, this.body, this.itemId, this.unitId, final  Map<String, dynamic> payload = const {}, this.isRead = false, this.createdAt}): _payload = payload,super._();
  factory _TmcNotificationModel.fromJson(Map<String, dynamic> json) => _$TmcNotificationModelFromJson(json);

@override final  String id;
@override final  String companyId;
@override final  String? userId;
@override final  TmcNotificationType notificationType;
@override final  String title;
@override final  String? body;
@override final  String? itemId;
@override final  String? unitId;
 final  Map<String, dynamic> _payload;
@override@JsonKey() Map<String, dynamic> get payload {
  if (_payload is EqualUnmodifiableMapView) return _payload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_payload);
}

@override@JsonKey() final  bool isRead;
@override final  DateTime? createdAt;

/// Create a copy of TmcNotificationModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TmcNotificationModelCopyWith<_TmcNotificationModel> get copyWith => __$TmcNotificationModelCopyWithImpl<_TmcNotificationModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TmcNotificationModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TmcNotificationModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.notificationType, notificationType) || other.notificationType == notificationType)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&const DeepCollectionEquality().equals(other._payload, _payload)&&(identical(other.isRead, isRead) || other.isRead == isRead)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,userId,notificationType,title,body,itemId,unitId,const DeepCollectionEquality().hash(_payload),isRead,createdAt);

@override
String toString() {
  return 'TmcNotificationModel(id: $id, companyId: $companyId, userId: $userId, notificationType: $notificationType, title: $title, body: $body, itemId: $itemId, unitId: $unitId, payload: $payload, isRead: $isRead, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$TmcNotificationModelCopyWith<$Res> implements $TmcNotificationModelCopyWith<$Res> {
  factory _$TmcNotificationModelCopyWith(_TmcNotificationModel value, $Res Function(_TmcNotificationModel) _then) = __$TmcNotificationModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String? userId, TmcNotificationType notificationType, String title, String? body, String? itemId, String? unitId, Map<String, dynamic> payload, bool isRead, DateTime? createdAt
});




}
/// @nodoc
class __$TmcNotificationModelCopyWithImpl<$Res>
    implements _$TmcNotificationModelCopyWith<$Res> {
  __$TmcNotificationModelCopyWithImpl(this._self, this._then);

  final _TmcNotificationModel _self;
  final $Res Function(_TmcNotificationModel) _then;

/// Create a copy of TmcNotificationModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? userId = freezed,Object? notificationType = null,Object? title = null,Object? body = freezed,Object? itemId = freezed,Object? unitId = freezed,Object? payload = null,Object? isRead = null,Object? createdAt = freezed,}) {
  return _then(_TmcNotificationModel(
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
