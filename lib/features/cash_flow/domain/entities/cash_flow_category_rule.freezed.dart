// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cash_flow_category_rule.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CashFlowCategoryRule {

/// Уникальный идентификатор.
 String get id;/// Компания-владелец.
 String get companyId;/// Статья ДДС, которую назначить при совпадении.
 String get categoryId;/// Ключевое слово (поиск без учёта регистра в назначении платежа).
 String get keyword;/// Тип операции, для которого применяется правило.
 CashFlowOperationType get operationType;/// Приоритет: больше — проверяется раньше.
 int get priority;/// Нужна ли привязка к договору и объекту.
///
/// `false` — операция обрабатывается только по статье (например, налоги).
 bool get requiresContractBinding;/// Дата создания.
 DateTime? get createdAt;/// Наименование категории (join для UI).
 String? get categoryName;
/// Create a copy of CashFlowCategoryRule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CashFlowCategoryRuleCopyWith<CashFlowCategoryRule> get copyWith => _$CashFlowCategoryRuleCopyWithImpl<CashFlowCategoryRule>(this as CashFlowCategoryRule, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CashFlowCategoryRule&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.keyword, keyword) || other.keyword == keyword)&&(identical(other.operationType, operationType) || other.operationType == operationType)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.requiresContractBinding, requiresContractBinding) || other.requiresContractBinding == requiresContractBinding)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,categoryId,keyword,operationType,priority,requiresContractBinding,createdAt,categoryName);

@override
String toString() {
  return 'CashFlowCategoryRule(id: $id, companyId: $companyId, categoryId: $categoryId, keyword: $keyword, operationType: $operationType, priority: $priority, requiresContractBinding: $requiresContractBinding, createdAt: $createdAt, categoryName: $categoryName)';
}


}

/// @nodoc
abstract mixin class $CashFlowCategoryRuleCopyWith<$Res>  {
  factory $CashFlowCategoryRuleCopyWith(CashFlowCategoryRule value, $Res Function(CashFlowCategoryRule) _then) = _$CashFlowCategoryRuleCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String categoryId, String keyword, CashFlowOperationType operationType, int priority, bool requiresContractBinding, DateTime? createdAt, String? categoryName
});




}
/// @nodoc
class _$CashFlowCategoryRuleCopyWithImpl<$Res>
    implements $CashFlowCategoryRuleCopyWith<$Res> {
  _$CashFlowCategoryRuleCopyWithImpl(this._self, this._then);

  final CashFlowCategoryRule _self;
  final $Res Function(CashFlowCategoryRule) _then;

/// Create a copy of CashFlowCategoryRule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? categoryId = null,Object? keyword = null,Object? operationType = null,Object? priority = null,Object? requiresContractBinding = null,Object? createdAt = freezed,Object? categoryName = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,keyword: null == keyword ? _self.keyword : keyword // ignore: cast_nullable_to_non_nullable
as String,operationType: null == operationType ? _self.operationType : operationType // ignore: cast_nullable_to_non_nullable
as CashFlowOperationType,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,requiresContractBinding: null == requiresContractBinding ? _self.requiresContractBinding : requiresContractBinding // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc


class _CashFlowCategoryRule implements CashFlowCategoryRule {
  const _CashFlowCategoryRule({required this.id, required this.companyId, required this.categoryId, required this.keyword, required this.operationType, this.priority = 0, this.requiresContractBinding = true, this.createdAt, this.categoryName});
  

/// Уникальный идентификатор.
@override final  String id;
/// Компания-владелец.
@override final  String companyId;
/// Статья ДДС, которую назначить при совпадении.
@override final  String categoryId;
/// Ключевое слово (поиск без учёта регистра в назначении платежа).
@override final  String keyword;
/// Тип операции, для которого применяется правило.
@override final  CashFlowOperationType operationType;
/// Приоритет: больше — проверяется раньше.
@override@JsonKey() final  int priority;
/// Нужна ли привязка к договору и объекту.
///
/// `false` — операция обрабатывается только по статье (например, налоги).
@override@JsonKey() final  bool requiresContractBinding;
/// Дата создания.
@override final  DateTime? createdAt;
/// Наименование категории (join для UI).
@override final  String? categoryName;

/// Create a copy of CashFlowCategoryRule
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CashFlowCategoryRuleCopyWith<_CashFlowCategoryRule> get copyWith => __$CashFlowCategoryRuleCopyWithImpl<_CashFlowCategoryRule>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CashFlowCategoryRule&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.keyword, keyword) || other.keyword == keyword)&&(identical(other.operationType, operationType) || other.operationType == operationType)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.requiresContractBinding, requiresContractBinding) || other.requiresContractBinding == requiresContractBinding)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,categoryId,keyword,operationType,priority,requiresContractBinding,createdAt,categoryName);

@override
String toString() {
  return 'CashFlowCategoryRule(id: $id, companyId: $companyId, categoryId: $categoryId, keyword: $keyword, operationType: $operationType, priority: $priority, requiresContractBinding: $requiresContractBinding, createdAt: $createdAt, categoryName: $categoryName)';
}


}

/// @nodoc
abstract mixin class _$CashFlowCategoryRuleCopyWith<$Res> implements $CashFlowCategoryRuleCopyWith<$Res> {
  factory _$CashFlowCategoryRuleCopyWith(_CashFlowCategoryRule value, $Res Function(_CashFlowCategoryRule) _then) = __$CashFlowCategoryRuleCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String categoryId, String keyword, CashFlowOperationType operationType, int priority, bool requiresContractBinding, DateTime? createdAt, String? categoryName
});




}
/// @nodoc
class __$CashFlowCategoryRuleCopyWithImpl<$Res>
    implements _$CashFlowCategoryRuleCopyWith<$Res> {
  __$CashFlowCategoryRuleCopyWithImpl(this._self, this._then);

  final _CashFlowCategoryRule _self;
  final $Res Function(_CashFlowCategoryRule) _then;

/// Create a copy of CashFlowCategoryRule
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? categoryId = null,Object? keyword = null,Object? operationType = null,Object? priority = null,Object? requiresContractBinding = null,Object? createdAt = freezed,Object? categoryName = freezed,}) {
  return _then(_CashFlowCategoryRule(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,keyword: null == keyword ? _self.keyword : keyword // ignore: cast_nullable_to_non_nullable
as String,operationType: null == operationType ? _self.operationType : operationType // ignore: cast_nullable_to_non_nullable
as CashFlowOperationType,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,requiresContractBinding: null == requiresContractBinding ? _self.requiresContractBinding : requiresContractBinding // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
