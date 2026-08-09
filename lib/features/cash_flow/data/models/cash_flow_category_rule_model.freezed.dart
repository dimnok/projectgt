// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cash_flow_category_rule_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CashFlowCategoryRuleModel {

 String get id; String get companyId; String get categoryId; String get keyword; CashFlowOperationType get operationType; int get priority; bool get requiresContractBinding; DateTime? get createdAt;@JsonKey(includeToJson: false) String? get categoryName;
/// Create a copy of CashFlowCategoryRuleModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CashFlowCategoryRuleModelCopyWith<CashFlowCategoryRuleModel> get copyWith => _$CashFlowCategoryRuleModelCopyWithImpl<CashFlowCategoryRuleModel>(this as CashFlowCategoryRuleModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CashFlowCategoryRuleModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.keyword, keyword) || other.keyword == keyword)&&(identical(other.operationType, operationType) || other.operationType == operationType)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.requiresContractBinding, requiresContractBinding) || other.requiresContractBinding == requiresContractBinding)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,categoryId,keyword,operationType,priority,requiresContractBinding,createdAt,categoryName);

@override
String toString() {
  return 'CashFlowCategoryRuleModel(id: $id, companyId: $companyId, categoryId: $categoryId, keyword: $keyword, operationType: $operationType, priority: $priority, requiresContractBinding: $requiresContractBinding, createdAt: $createdAt, categoryName: $categoryName)';
}


}

/// @nodoc
abstract mixin class $CashFlowCategoryRuleModelCopyWith<$Res>  {
  factory $CashFlowCategoryRuleModelCopyWith(CashFlowCategoryRuleModel value, $Res Function(CashFlowCategoryRuleModel) _then) = _$CashFlowCategoryRuleModelCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String categoryId, String keyword, CashFlowOperationType operationType, int priority, bool requiresContractBinding, DateTime? createdAt,@JsonKey(includeToJson: false) String? categoryName
});




}
/// @nodoc
class _$CashFlowCategoryRuleModelCopyWithImpl<$Res>
    implements $CashFlowCategoryRuleModelCopyWith<$Res> {
  _$CashFlowCategoryRuleModelCopyWithImpl(this._self, this._then);

  final CashFlowCategoryRuleModel _self;
  final $Res Function(CashFlowCategoryRuleModel) _then;

/// Create a copy of CashFlowCategoryRuleModel
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

@JsonSerializable(fieldRename: FieldRename.snake)
class _CashFlowCategoryRuleModel extends CashFlowCategoryRuleModel {
  const _CashFlowCategoryRuleModel({required this.id, required this.companyId, required this.categoryId, required this.keyword, required this.operationType, this.priority = 0, this.requiresContractBinding = true, this.createdAt, @JsonKey(includeToJson: false) this.categoryName}): super._();
  

@override final  String id;
@override final  String companyId;
@override final  String categoryId;
@override final  String keyword;
@override final  CashFlowOperationType operationType;
@override@JsonKey() final  int priority;
@override@JsonKey() final  bool requiresContractBinding;
@override final  DateTime? createdAt;
@override@JsonKey(includeToJson: false) final  String? categoryName;

/// Create a copy of CashFlowCategoryRuleModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CashFlowCategoryRuleModelCopyWith<_CashFlowCategoryRuleModel> get copyWith => __$CashFlowCategoryRuleModelCopyWithImpl<_CashFlowCategoryRuleModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CashFlowCategoryRuleModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.keyword, keyword) || other.keyword == keyword)&&(identical(other.operationType, operationType) || other.operationType == operationType)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.requiresContractBinding, requiresContractBinding) || other.requiresContractBinding == requiresContractBinding)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,categoryId,keyword,operationType,priority,requiresContractBinding,createdAt,categoryName);

@override
String toString() {
  return 'CashFlowCategoryRuleModel(id: $id, companyId: $companyId, categoryId: $categoryId, keyword: $keyword, operationType: $operationType, priority: $priority, requiresContractBinding: $requiresContractBinding, createdAt: $createdAt, categoryName: $categoryName)';
}


}

/// @nodoc
abstract mixin class _$CashFlowCategoryRuleModelCopyWith<$Res> implements $CashFlowCategoryRuleModelCopyWith<$Res> {
  factory _$CashFlowCategoryRuleModelCopyWith(_CashFlowCategoryRuleModel value, $Res Function(_CashFlowCategoryRuleModel) _then) = __$CashFlowCategoryRuleModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String categoryId, String keyword, CashFlowOperationType operationType, int priority, bool requiresContractBinding, DateTime? createdAt,@JsonKey(includeToJson: false) String? categoryName
});




}
/// @nodoc
class __$CashFlowCategoryRuleModelCopyWithImpl<$Res>
    implements _$CashFlowCategoryRuleModelCopyWith<$Res> {
  __$CashFlowCategoryRuleModelCopyWithImpl(this._self, this._then);

  final _CashFlowCategoryRuleModel _self;
  final $Res Function(_CashFlowCategoryRuleModel) _then;

/// Create a copy of CashFlowCategoryRuleModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? categoryId = null,Object? keyword = null,Object? operationType = null,Object? priority = null,Object? requiresContractBinding = null,Object? createdAt = freezed,Object? categoryName = freezed,}) {
  return _then(_CashFlowCategoryRuleModel(
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
