// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'object_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ObjectState implements DiagnosticableTreeMixin {

 ObjectStatus get status; List<ObjectEntity> get objects; String? get errorMessage;
/// Create a copy of ObjectState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ObjectStateCopyWith<ObjectState> get copyWith => _$ObjectStateCopyWithImpl<ObjectState>(this as ObjectState, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ObjectState'))
    ..add(DiagnosticsProperty('status', status))..add(DiagnosticsProperty('objects', objects))..add(DiagnosticsProperty('errorMessage', errorMessage));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ObjectState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.objects, objects)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(objects),errorMessage);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ObjectState(status: $status, objects: $objects, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $ObjectStateCopyWith<$Res>  {
  factory $ObjectStateCopyWith(ObjectState value, $Res Function(ObjectState) _then) = _$ObjectStateCopyWithImpl;
@useResult
$Res call({
 ObjectStatus status, List<ObjectEntity> objects, String? errorMessage
});




}
/// @nodoc
class _$ObjectStateCopyWithImpl<$Res>
    implements $ObjectStateCopyWith<$Res> {
  _$ObjectStateCopyWithImpl(this._self, this._then);

  final ObjectState _self;
  final $Res Function(ObjectState) _then;

/// Create a copy of ObjectState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? objects = null,Object? errorMessage = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ObjectStatus,objects: null == objects ? _self.objects : objects // ignore: cast_nullable_to_non_nullable
as List<ObjectEntity>,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc


class _ObjectState with DiagnosticableTreeMixin implements ObjectState {
  const _ObjectState({required this.status, final  List<ObjectEntity> objects = const [], this.errorMessage}): _objects = objects;
  

@override final  ObjectStatus status;
 final  List<ObjectEntity> _objects;
@override@JsonKey() List<ObjectEntity> get objects {
  if (_objects is EqualUnmodifiableListView) return _objects;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_objects);
}

@override final  String? errorMessage;

/// Create a copy of ObjectState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ObjectStateCopyWith<_ObjectState> get copyWith => __$ObjectStateCopyWithImpl<_ObjectState>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'ObjectState'))
    ..add(DiagnosticsProperty('status', status))..add(DiagnosticsProperty('objects', objects))..add(DiagnosticsProperty('errorMessage', errorMessage));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ObjectState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._objects, _objects)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_objects),errorMessage);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'ObjectState(status: $status, objects: $objects, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$ObjectStateCopyWith<$Res> implements $ObjectStateCopyWith<$Res> {
  factory _$ObjectStateCopyWith(_ObjectState value, $Res Function(_ObjectState) _then) = __$ObjectStateCopyWithImpl;
@override @useResult
$Res call({
 ObjectStatus status, List<ObjectEntity> objects, String? errorMessage
});




}
/// @nodoc
class __$ObjectStateCopyWithImpl<$Res>
    implements _$ObjectStateCopyWith<$Res> {
  __$ObjectStateCopyWithImpl(this._self, this._then);

  final _ObjectState _self;
  final $Res Function(_ObjectState) _then;

/// Create a copy of ObjectState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? objects = null,Object? errorMessage = freezed,}) {
  return _then(_ObjectState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ObjectStatus,objects: null == objects ? _self._objects : objects // ignore: cast_nullable_to_non_nullable
as List<ObjectEntity>,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
