// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'refresh_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RefreshState {

/// Карта времени последнего успешного запуска обновления для каждой цели (UTC).
 Map<String, DateTime> get lastRunByTargetUtc;/// Флаг, указывающий на выполнение процесса обновления в данный момент.
 bool get isRefreshing;/// Время последнего возврата приложения из фонового режима (UTC).
 DateTime? get lastAppResumeAtUtc;/// Набор ID активных целей, которые считаются видимыми.
 Set<String> get visibleTargetIds;/// Длительность последнего цикла обновления.
 Duration? get lastRefreshDuration;/// Количество обновленных целей в последнем цикле.
 int get lastRefreshedCount;
/// Create a copy of RefreshState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RefreshStateCopyWith<RefreshState> get copyWith => _$RefreshStateCopyWithImpl<RefreshState>(this as RefreshState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RefreshState&&const DeepCollectionEquality().equals(other.lastRunByTargetUtc, lastRunByTargetUtc)&&(identical(other.isRefreshing, isRefreshing) || other.isRefreshing == isRefreshing)&&(identical(other.lastAppResumeAtUtc, lastAppResumeAtUtc) || other.lastAppResumeAtUtc == lastAppResumeAtUtc)&&const DeepCollectionEquality().equals(other.visibleTargetIds, visibleTargetIds)&&(identical(other.lastRefreshDuration, lastRefreshDuration) || other.lastRefreshDuration == lastRefreshDuration)&&(identical(other.lastRefreshedCount, lastRefreshedCount) || other.lastRefreshedCount == lastRefreshedCount));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(lastRunByTargetUtc),isRefreshing,lastAppResumeAtUtc,const DeepCollectionEquality().hash(visibleTargetIds),lastRefreshDuration,lastRefreshedCount);

@override
String toString() {
  return 'RefreshState(lastRunByTargetUtc: $lastRunByTargetUtc, isRefreshing: $isRefreshing, lastAppResumeAtUtc: $lastAppResumeAtUtc, visibleTargetIds: $visibleTargetIds, lastRefreshDuration: $lastRefreshDuration, lastRefreshedCount: $lastRefreshedCount)';
}


}

/// @nodoc
abstract mixin class $RefreshStateCopyWith<$Res>  {
  factory $RefreshStateCopyWith(RefreshState value, $Res Function(RefreshState) _then) = _$RefreshStateCopyWithImpl;
@useResult
$Res call({
 Map<String, DateTime> lastRunByTargetUtc, bool isRefreshing, DateTime? lastAppResumeAtUtc, Set<String> visibleTargetIds, Duration? lastRefreshDuration, int lastRefreshedCount
});




}
/// @nodoc
class _$RefreshStateCopyWithImpl<$Res>
    implements $RefreshStateCopyWith<$Res> {
  _$RefreshStateCopyWithImpl(this._self, this._then);

  final RefreshState _self;
  final $Res Function(RefreshState) _then;

/// Create a copy of RefreshState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lastRunByTargetUtc = null,Object? isRefreshing = null,Object? lastAppResumeAtUtc = freezed,Object? visibleTargetIds = null,Object? lastRefreshDuration = freezed,Object? lastRefreshedCount = null,}) {
  return _then(_self.copyWith(
lastRunByTargetUtc: null == lastRunByTargetUtc ? _self.lastRunByTargetUtc : lastRunByTargetUtc // ignore: cast_nullable_to_non_nullable
as Map<String, DateTime>,isRefreshing: null == isRefreshing ? _self.isRefreshing : isRefreshing // ignore: cast_nullable_to_non_nullable
as bool,lastAppResumeAtUtc: freezed == lastAppResumeAtUtc ? _self.lastAppResumeAtUtc : lastAppResumeAtUtc // ignore: cast_nullable_to_non_nullable
as DateTime?,visibleTargetIds: null == visibleTargetIds ? _self.visibleTargetIds : visibleTargetIds // ignore: cast_nullable_to_non_nullable
as Set<String>,lastRefreshDuration: freezed == lastRefreshDuration ? _self.lastRefreshDuration : lastRefreshDuration // ignore: cast_nullable_to_non_nullable
as Duration?,lastRefreshedCount: null == lastRefreshedCount ? _self.lastRefreshedCount : lastRefreshedCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// @nodoc


class _RefreshState implements RefreshState {
  const _RefreshState({final  Map<String, DateTime> lastRunByTargetUtc = const {}, this.isRefreshing = false, this.lastAppResumeAtUtc, final  Set<String> visibleTargetIds = const {}, this.lastRefreshDuration, this.lastRefreshedCount = 0}): _lastRunByTargetUtc = lastRunByTargetUtc,_visibleTargetIds = visibleTargetIds;
  

/// Карта времени последнего успешного запуска обновления для каждой цели (UTC).
 final  Map<String, DateTime> _lastRunByTargetUtc;
/// Карта времени последнего успешного запуска обновления для каждой цели (UTC).
@override@JsonKey() Map<String, DateTime> get lastRunByTargetUtc {
  if (_lastRunByTargetUtc is EqualUnmodifiableMapView) return _lastRunByTargetUtc;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_lastRunByTargetUtc);
}

/// Флаг, указывающий на выполнение процесса обновления в данный момент.
@override@JsonKey() final  bool isRefreshing;
/// Время последнего возврата приложения из фонового режима (UTC).
@override final  DateTime? lastAppResumeAtUtc;
/// Набор ID активных целей, которые считаются видимыми.
 final  Set<String> _visibleTargetIds;
/// Набор ID активных целей, которые считаются видимыми.
@override@JsonKey() Set<String> get visibleTargetIds {
  if (_visibleTargetIds is EqualUnmodifiableSetView) return _visibleTargetIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_visibleTargetIds);
}

/// Длительность последнего цикла обновления.
@override final  Duration? lastRefreshDuration;
/// Количество обновленных целей в последнем цикле.
@override@JsonKey() final  int lastRefreshedCount;

/// Create a copy of RefreshState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RefreshStateCopyWith<_RefreshState> get copyWith => __$RefreshStateCopyWithImpl<_RefreshState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RefreshState&&const DeepCollectionEquality().equals(other._lastRunByTargetUtc, _lastRunByTargetUtc)&&(identical(other.isRefreshing, isRefreshing) || other.isRefreshing == isRefreshing)&&(identical(other.lastAppResumeAtUtc, lastAppResumeAtUtc) || other.lastAppResumeAtUtc == lastAppResumeAtUtc)&&const DeepCollectionEquality().equals(other._visibleTargetIds, _visibleTargetIds)&&(identical(other.lastRefreshDuration, lastRefreshDuration) || other.lastRefreshDuration == lastRefreshDuration)&&(identical(other.lastRefreshedCount, lastRefreshedCount) || other.lastRefreshedCount == lastRefreshedCount));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_lastRunByTargetUtc),isRefreshing,lastAppResumeAtUtc,const DeepCollectionEquality().hash(_visibleTargetIds),lastRefreshDuration,lastRefreshedCount);

@override
String toString() {
  return 'RefreshState(lastRunByTargetUtc: $lastRunByTargetUtc, isRefreshing: $isRefreshing, lastAppResumeAtUtc: $lastAppResumeAtUtc, visibleTargetIds: $visibleTargetIds, lastRefreshDuration: $lastRefreshDuration, lastRefreshedCount: $lastRefreshedCount)';
}


}

/// @nodoc
abstract mixin class _$RefreshStateCopyWith<$Res> implements $RefreshStateCopyWith<$Res> {
  factory _$RefreshStateCopyWith(_RefreshState value, $Res Function(_RefreshState) _then) = __$RefreshStateCopyWithImpl;
@override @useResult
$Res call({
 Map<String, DateTime> lastRunByTargetUtc, bool isRefreshing, DateTime? lastAppResumeAtUtc, Set<String> visibleTargetIds, Duration? lastRefreshDuration, int lastRefreshedCount
});




}
/// @nodoc
class __$RefreshStateCopyWithImpl<$Res>
    implements _$RefreshStateCopyWith<$Res> {
  __$RefreshStateCopyWithImpl(this._self, this._then);

  final _RefreshState _self;
  final $Res Function(_RefreshState) _then;

/// Create a copy of RefreshState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lastRunByTargetUtc = null,Object? isRefreshing = null,Object? lastAppResumeAtUtc = freezed,Object? visibleTargetIds = null,Object? lastRefreshDuration = freezed,Object? lastRefreshedCount = null,}) {
  return _then(_RefreshState(
lastRunByTargetUtc: null == lastRunByTargetUtc ? _self._lastRunByTargetUtc : lastRunByTargetUtc // ignore: cast_nullable_to_non_nullable
as Map<String, DateTime>,isRefreshing: null == isRefreshing ? _self.isRefreshing : isRefreshing // ignore: cast_nullable_to_non_nullable
as bool,lastAppResumeAtUtc: freezed == lastAppResumeAtUtc ? _self.lastAppResumeAtUtc : lastAppResumeAtUtc // ignore: cast_nullable_to_non_nullable
as DateTime?,visibleTargetIds: null == visibleTargetIds ? _self._visibleTargetIds : visibleTargetIds // ignore: cast_nullable_to_non_nullable
as Set<String>,lastRefreshDuration: freezed == lastRefreshDuration ? _self.lastRefreshDuration : lastRefreshDuration // ignore: cast_nullable_to_non_nullable
as Duration?,lastRefreshedCount: null == lastRefreshedCount ? _self.lastRefreshedCount : lastRefreshedCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
