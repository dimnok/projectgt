// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bank_statement_match_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BankStatementMatchResult {

/// ID строки выписки.
 String get entryId;/// Уровень уверенности.
 BankStatementMatchConfidence get confidence;/// Подобранная статья ДДС.
 String? get categoryId;/// Подобранный контрагент.
 String? get contractorId;/// Подобранный договор.
 String? get contractId;/// Подобранный объект (из договора).
 String? get objectId;/// Подобранный счёт взаиморасчётов (опционально).
 String? get settlementOperationId;/// Пояснения для UI (источник совпадения / причина низкой уверенности).
 List<String> get matchReasons;
/// Create a copy of BankStatementMatchResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BankStatementMatchResultCopyWith<BankStatementMatchResult> get copyWith => _$BankStatementMatchResultCopyWithImpl<BankStatementMatchResult>(this as BankStatementMatchResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BankStatementMatchResult&&(identical(other.entryId, entryId) || other.entryId == entryId)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.contractorId, contractorId) || other.contractorId == contractorId)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.settlementOperationId, settlementOperationId) || other.settlementOperationId == settlementOperationId)&&const DeepCollectionEquality().equals(other.matchReasons, matchReasons));
}


@override
int get hashCode => Object.hash(runtimeType,entryId,confidence,categoryId,contractorId,contractId,objectId,settlementOperationId,const DeepCollectionEquality().hash(matchReasons));

@override
String toString() {
  return 'BankStatementMatchResult(entryId: $entryId, confidence: $confidence, categoryId: $categoryId, contractorId: $contractorId, contractId: $contractId, objectId: $objectId, settlementOperationId: $settlementOperationId, matchReasons: $matchReasons)';
}


}

/// @nodoc
abstract mixin class $BankStatementMatchResultCopyWith<$Res>  {
  factory $BankStatementMatchResultCopyWith(BankStatementMatchResult value, $Res Function(BankStatementMatchResult) _then) = _$BankStatementMatchResultCopyWithImpl;
@useResult
$Res call({
 String entryId, BankStatementMatchConfidence confidence, String? categoryId, String? contractorId, String? contractId, String? objectId, String? settlementOperationId, List<String> matchReasons
});




}
/// @nodoc
class _$BankStatementMatchResultCopyWithImpl<$Res>
    implements $BankStatementMatchResultCopyWith<$Res> {
  _$BankStatementMatchResultCopyWithImpl(this._self, this._then);

  final BankStatementMatchResult _self;
  final $Res Function(BankStatementMatchResult) _then;

/// Create a copy of BankStatementMatchResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? entryId = null,Object? confidence = null,Object? categoryId = freezed,Object? contractorId = freezed,Object? contractId = freezed,Object? objectId = freezed,Object? settlementOperationId = freezed,Object? matchReasons = null,}) {
  return _then(_self.copyWith(
entryId: null == entryId ? _self.entryId : entryId // ignore: cast_nullable_to_non_nullable
as String,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as BankStatementMatchConfidence,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,contractorId: freezed == contractorId ? _self.contractorId : contractorId // ignore: cast_nullable_to_non_nullable
as String?,contractId: freezed == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String?,objectId: freezed == objectId ? _self.objectId : objectId // ignore: cast_nullable_to_non_nullable
as String?,settlementOperationId: freezed == settlementOperationId ? _self.settlementOperationId : settlementOperationId // ignore: cast_nullable_to_non_nullable
as String?,matchReasons: null == matchReasons ? _self.matchReasons : matchReasons // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// @nodoc


class _BankStatementMatchResult extends BankStatementMatchResult {
  const _BankStatementMatchResult({required this.entryId, required this.confidence, this.categoryId, this.contractorId, this.contractId, this.objectId, this.settlementOperationId, final  List<String> matchReasons = const []}): _matchReasons = matchReasons,super._();
  

/// ID строки выписки.
@override final  String entryId;
/// Уровень уверенности.
@override final  BankStatementMatchConfidence confidence;
/// Подобранная статья ДДС.
@override final  String? categoryId;
/// Подобранный контрагент.
@override final  String? contractorId;
/// Подобранный договор.
@override final  String? contractId;
/// Подобранный объект (из договора).
@override final  String? objectId;
/// Подобранный счёт взаиморасчётов (опционально).
@override final  String? settlementOperationId;
/// Пояснения для UI (источник совпадения / причина низкой уверенности).
 final  List<String> _matchReasons;
/// Пояснения для UI (источник совпадения / причина низкой уверенности).
@override@JsonKey() List<String> get matchReasons {
  if (_matchReasons is EqualUnmodifiableListView) return _matchReasons;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_matchReasons);
}


/// Create a copy of BankStatementMatchResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BankStatementMatchResultCopyWith<_BankStatementMatchResult> get copyWith => __$BankStatementMatchResultCopyWithImpl<_BankStatementMatchResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BankStatementMatchResult&&(identical(other.entryId, entryId) || other.entryId == entryId)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.contractorId, contractorId) || other.contractorId == contractorId)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.settlementOperationId, settlementOperationId) || other.settlementOperationId == settlementOperationId)&&const DeepCollectionEquality().equals(other._matchReasons, _matchReasons));
}


@override
int get hashCode => Object.hash(runtimeType,entryId,confidence,categoryId,contractorId,contractId,objectId,settlementOperationId,const DeepCollectionEquality().hash(_matchReasons));

@override
String toString() {
  return 'BankStatementMatchResult(entryId: $entryId, confidence: $confidence, categoryId: $categoryId, contractorId: $contractorId, contractId: $contractId, objectId: $objectId, settlementOperationId: $settlementOperationId, matchReasons: $matchReasons)';
}


}

/// @nodoc
abstract mixin class _$BankStatementMatchResultCopyWith<$Res> implements $BankStatementMatchResultCopyWith<$Res> {
  factory _$BankStatementMatchResultCopyWith(_BankStatementMatchResult value, $Res Function(_BankStatementMatchResult) _then) = __$BankStatementMatchResultCopyWithImpl;
@override @useResult
$Res call({
 String entryId, BankStatementMatchConfidence confidence, String? categoryId, String? contractorId, String? contractId, String? objectId, String? settlementOperationId, List<String> matchReasons
});




}
/// @nodoc
class __$BankStatementMatchResultCopyWithImpl<$Res>
    implements _$BankStatementMatchResultCopyWith<$Res> {
  __$BankStatementMatchResultCopyWithImpl(this._self, this._then);

  final _BankStatementMatchResult _self;
  final $Res Function(_BankStatementMatchResult) _then;

/// Create a copy of BankStatementMatchResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? entryId = null,Object? confidence = null,Object? categoryId = freezed,Object? contractorId = freezed,Object? contractId = freezed,Object? objectId = freezed,Object? settlementOperationId = freezed,Object? matchReasons = null,}) {
  return _then(_BankStatementMatchResult(
entryId: null == entryId ? _self.entryId : entryId // ignore: cast_nullable_to_non_nullable
as String,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as BankStatementMatchConfidence,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,contractorId: freezed == contractorId ? _self.contractorId : contractorId // ignore: cast_nullable_to_non_nullable
as String?,contractId: freezed == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String?,objectId: freezed == objectId ? _self.objectId : objectId // ignore: cast_nullable_to_non_nullable
as String?,settlementOperationId: freezed == settlementOperationId ? _self.settlementOperationId : settlementOperationId // ignore: cast_nullable_to_non_nullable
as String?,matchReasons: null == matchReasons ? _self._matchReasons : matchReasons // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
