// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'available_filters.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AvailableFilters {

/// Список ID объектов.
 Set<String> get objectIds;/// Список ID контрагентов.
 Set<String> get contractorIds;/// Список ID договоров.
 Set<String> get contractIds;
/// Create a copy of AvailableFilters
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AvailableFiltersCopyWith<AvailableFilters> get copyWith => _$AvailableFiltersCopyWithImpl<AvailableFilters>(this as AvailableFilters, _$identity);

  /// Serializes this AvailableFilters to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AvailableFilters&&const DeepCollectionEquality().equals(other.objectIds, objectIds)&&const DeepCollectionEquality().equals(other.contractorIds, contractorIds)&&const DeepCollectionEquality().equals(other.contractIds, contractIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(objectIds),const DeepCollectionEquality().hash(contractorIds),const DeepCollectionEquality().hash(contractIds));

@override
String toString() {
  return 'AvailableFilters(objectIds: $objectIds, contractorIds: $contractorIds, contractIds: $contractIds)';
}


}

/// @nodoc
abstract mixin class $AvailableFiltersCopyWith<$Res>  {
  factory $AvailableFiltersCopyWith(AvailableFilters value, $Res Function(AvailableFilters) _then) = _$AvailableFiltersCopyWithImpl;
@useResult
$Res call({
 Set<String> objectIds, Set<String> contractorIds, Set<String> contractIds
});




}
/// @nodoc
class _$AvailableFiltersCopyWithImpl<$Res>
    implements $AvailableFiltersCopyWith<$Res> {
  _$AvailableFiltersCopyWithImpl(this._self, this._then);

  final AvailableFilters _self;
  final $Res Function(AvailableFilters) _then;

/// Create a copy of AvailableFilters
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? objectIds = null,Object? contractorIds = null,Object? contractIds = null,}) {
  return _then(_self.copyWith(
objectIds: null == objectIds ? _self.objectIds : objectIds // ignore: cast_nullable_to_non_nullable
as Set<String>,contractorIds: null == contractorIds ? _self.contractorIds : contractorIds // ignore: cast_nullable_to_non_nullable
as Set<String>,contractIds: null == contractIds ? _self.contractIds : contractIds // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _AvailableFilters implements AvailableFilters {
  const _AvailableFilters({final  Set<String> objectIds = const {}, final  Set<String> contractorIds = const {}, final  Set<String> contractIds = const {}}): _objectIds = objectIds,_contractorIds = contractorIds,_contractIds = contractIds;
  factory _AvailableFilters.fromJson(Map<String, dynamic> json) => _$AvailableFiltersFromJson(json);

/// Список ID объектов.
 final  Set<String> _objectIds;
/// Список ID объектов.
@override@JsonKey() Set<String> get objectIds {
  if (_objectIds is EqualUnmodifiableSetView) return _objectIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_objectIds);
}

/// Список ID контрагентов.
 final  Set<String> _contractorIds;
/// Список ID контрагентов.
@override@JsonKey() Set<String> get contractorIds {
  if (_contractorIds is EqualUnmodifiableSetView) return _contractorIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_contractorIds);
}

/// Список ID договоров.
 final  Set<String> _contractIds;
/// Список ID договоров.
@override@JsonKey() Set<String> get contractIds {
  if (_contractIds is EqualUnmodifiableSetView) return _contractIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_contractIds);
}


/// Create a copy of AvailableFilters
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AvailableFiltersCopyWith<_AvailableFilters> get copyWith => __$AvailableFiltersCopyWithImpl<_AvailableFilters>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AvailableFiltersToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AvailableFilters&&const DeepCollectionEquality().equals(other._objectIds, _objectIds)&&const DeepCollectionEquality().equals(other._contractorIds, _contractorIds)&&const DeepCollectionEquality().equals(other._contractIds, _contractIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_objectIds),const DeepCollectionEquality().hash(_contractorIds),const DeepCollectionEquality().hash(_contractIds));

@override
String toString() {
  return 'AvailableFilters(objectIds: $objectIds, contractorIds: $contractorIds, contractIds: $contractIds)';
}


}

/// @nodoc
abstract mixin class _$AvailableFiltersCopyWith<$Res> implements $AvailableFiltersCopyWith<$Res> {
  factory _$AvailableFiltersCopyWith(_AvailableFilters value, $Res Function(_AvailableFilters) _then) = __$AvailableFiltersCopyWithImpl;
@override @useResult
$Res call({
 Set<String> objectIds, Set<String> contractorIds, Set<String> contractIds
});




}
/// @nodoc
class __$AvailableFiltersCopyWithImpl<$Res>
    implements _$AvailableFiltersCopyWith<$Res> {
  __$AvailableFiltersCopyWithImpl(this._self, this._then);

  final _AvailableFilters _self;
  final $Res Function(_AvailableFilters) _then;

/// Create a copy of AvailableFilters
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? objectIds = null,Object? contractorIds = null,Object? contractIds = null,}) {
  return _then(_AvailableFilters(
objectIds: null == objectIds ? _self._objectIds : objectIds // ignore: cast_nullable_to_non_nullable
as Set<String>,contractorIds: null == contractorIds ? _self._contractorIds : contractorIds // ignore: cast_nullable_to_non_nullable
as Set<String>,contractIds: null == contractIds ? _self._contractIds : contractIds // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}


}

// dart format on
