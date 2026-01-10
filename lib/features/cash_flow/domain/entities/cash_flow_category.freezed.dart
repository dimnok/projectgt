// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cash_flow_category.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CashFlowCategory {

/// Уникальный идентификатор категории.
 String get id;/// Идентификатор компании, которой принадлежит категория.
 String get companyId;/// Наименование категории.
 String get name;/// Тип допустимых операций для этой категории.
 CashFlowOperationType get type;/// Дата создания.
 DateTime? get createdAt;
/// Create a copy of CashFlowCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CashFlowCategoryCopyWith<CashFlowCategory> get copyWith => _$CashFlowCategoryCopyWithImpl<CashFlowCategory>(this as CashFlowCategory, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CashFlowCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,name,type,createdAt);

@override
String toString() {
  return 'CashFlowCategory(id: $id, companyId: $companyId, name: $name, type: $type, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $CashFlowCategoryCopyWith<$Res>  {
  factory $CashFlowCategoryCopyWith(CashFlowCategory value, $Res Function(CashFlowCategory) _then) = _$CashFlowCategoryCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String name, CashFlowOperationType type, DateTime? createdAt
});




}
/// @nodoc
class _$CashFlowCategoryCopyWithImpl<$Res>
    implements $CashFlowCategoryCopyWith<$Res> {
  _$CashFlowCategoryCopyWithImpl(this._self, this._then);

  final CashFlowCategory _self;
  final $Res Function(CashFlowCategory) _then;

/// Create a copy of CashFlowCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? name = null,Object? type = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CashFlowOperationType,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc


class _CashFlowCategory extends CashFlowCategory {
  const _CashFlowCategory({required this.id, required this.companyId, required this.name, this.type = CashFlowOperationType.expense, this.createdAt}): super._();
  

/// Уникальный идентификатор категории.
@override final  String id;
/// Идентификатор компании, которой принадлежит категория.
@override final  String companyId;
/// Наименование категории.
@override final  String name;
/// Тип допустимых операций для этой категории.
@override@JsonKey() final  CashFlowOperationType type;
/// Дата создания.
@override final  DateTime? createdAt;

/// Create a copy of CashFlowCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CashFlowCategoryCopyWith<_CashFlowCategory> get copyWith => __$CashFlowCategoryCopyWithImpl<_CashFlowCategory>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CashFlowCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,name,type,createdAt);

@override
String toString() {
  return 'CashFlowCategory(id: $id, companyId: $companyId, name: $name, type: $type, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$CashFlowCategoryCopyWith<$Res> implements $CashFlowCategoryCopyWith<$Res> {
  factory _$CashFlowCategoryCopyWith(_CashFlowCategory value, $Res Function(_CashFlowCategory) _then) = __$CashFlowCategoryCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String name, CashFlowOperationType type, DateTime? createdAt
});




}
/// @nodoc
class __$CashFlowCategoryCopyWithImpl<$Res>
    implements _$CashFlowCategoryCopyWith<$Res> {
  __$CashFlowCategoryCopyWithImpl(this._self, this._then);

  final _CashFlowCategory _self;
  final $Res Function(_CashFlowCategory) _then;

/// Create a copy of CashFlowCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? name = null,Object? type = null,Object? createdAt = freezed,}) {
  return _then(_CashFlowCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CashFlowOperationType,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
