// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'contractor_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ContractorState {

 List<Contractor> get contractors; ContractorStatus get status; String? get errorMessage; String get searchQuery; Contractor? get contractor;
/// Create a copy of ContractorState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContractorStateCopyWith<ContractorState> get copyWith => _$ContractorStateCopyWithImpl<ContractorState>(this as ContractorState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContractorState&&const DeepCollectionEquality().equals(other.contractors, contractors)&&(identical(other.status, status) || other.status == status)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.contractor, contractor) || other.contractor == contractor));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(contractors),status,errorMessage,searchQuery,contractor);

@override
String toString() {
  return 'ContractorState(contractors: $contractors, status: $status, errorMessage: $errorMessage, searchQuery: $searchQuery, contractor: $contractor)';
}


}

/// @nodoc
abstract mixin class $ContractorStateCopyWith<$Res>  {
  factory $ContractorStateCopyWith(ContractorState value, $Res Function(ContractorState) _then) = _$ContractorStateCopyWithImpl;
@useResult
$Res call({
 List<Contractor> contractors, ContractorStatus status, String? errorMessage, String searchQuery, Contractor? contractor
});


$ContractorCopyWith<$Res>? get contractor;

}
/// @nodoc
class _$ContractorStateCopyWithImpl<$Res>
    implements $ContractorStateCopyWith<$Res> {
  _$ContractorStateCopyWithImpl(this._self, this._then);

  final ContractorState _self;
  final $Res Function(ContractorState) _then;

/// Create a copy of ContractorState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? contractors = null,Object? status = null,Object? errorMessage = freezed,Object? searchQuery = null,Object? contractor = freezed,}) {
  return _then(_self.copyWith(
contractors: null == contractors ? _self.contractors : contractors // ignore: cast_nullable_to_non_nullable
as List<Contractor>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ContractorStatus,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,contractor: freezed == contractor ? _self.contractor : contractor // ignore: cast_nullable_to_non_nullable
as Contractor?,
  ));
}
/// Create a copy of ContractorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ContractorCopyWith<$Res>? get contractor {
    if (_self.contractor == null) {
    return null;
  }

  return $ContractorCopyWith<$Res>(_self.contractor!, (value) {
    return _then(_self.copyWith(contractor: value));
  });
}
}


/// @nodoc


class _ContractorState implements ContractorState {
  const _ContractorState({final  List<Contractor> contractors = const [], this.status = ContractorStatus.initial, this.errorMessage, this.searchQuery = '', this.contractor}): _contractors = contractors;
  

 final  List<Contractor> _contractors;
@override@JsonKey() List<Contractor> get contractors {
  if (_contractors is EqualUnmodifiableListView) return _contractors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_contractors);
}

@override@JsonKey() final  ContractorStatus status;
@override final  String? errorMessage;
@override@JsonKey() final  String searchQuery;
@override final  Contractor? contractor;

/// Create a copy of ContractorState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContractorStateCopyWith<_ContractorState> get copyWith => __$ContractorStateCopyWithImpl<_ContractorState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ContractorState&&const DeepCollectionEquality().equals(other._contractors, _contractors)&&(identical(other.status, status) || other.status == status)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.contractor, contractor) || other.contractor == contractor));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_contractors),status,errorMessage,searchQuery,contractor);

@override
String toString() {
  return 'ContractorState(contractors: $contractors, status: $status, errorMessage: $errorMessage, searchQuery: $searchQuery, contractor: $contractor)';
}


}

/// @nodoc
abstract mixin class _$ContractorStateCopyWith<$Res> implements $ContractorStateCopyWith<$Res> {
  factory _$ContractorStateCopyWith(_ContractorState value, $Res Function(_ContractorState) _then) = __$ContractorStateCopyWithImpl;
@override @useResult
$Res call({
 List<Contractor> contractors, ContractorStatus status, String? errorMessage, String searchQuery, Contractor? contractor
});


@override $ContractorCopyWith<$Res>? get contractor;

}
/// @nodoc
class __$ContractorStateCopyWithImpl<$Res>
    implements _$ContractorStateCopyWith<$Res> {
  __$ContractorStateCopyWithImpl(this._self, this._then);

  final _ContractorState _self;
  final $Res Function(_ContractorState) _then;

/// Create a copy of ContractorState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? contractors = null,Object? status = null,Object? errorMessage = freezed,Object? searchQuery = null,Object? contractor = freezed,}) {
  return _then(_ContractorState(
contractors: null == contractors ? _self._contractors : contractors // ignore: cast_nullable_to_non_nullable
as List<Contractor>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ContractorStatus,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,contractor: freezed == contractor ? _self.contractor : contractor // ignore: cast_nullable_to_non_nullable
as Contractor?,
  ));
}

/// Create a copy of ContractorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ContractorCopyWith<$Res>? get contractor {
    if (_self.contractor == null) {
    return null;
  }

  return $ContractorCopyWith<$Res>(_self.contractor!, (value) {
    return _then(_self.copyWith(contractor: value));
  });
}
}

// dart format on
