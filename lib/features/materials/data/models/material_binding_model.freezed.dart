// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'material_binding_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MaterialBindingModel {

/// Наименование материала из накладной
 String get name;/// Единица измерения из накладной
 String? get unit;/// Номер накладной
 String? get receiptNumber;/// Текущий статус привязки в рамках договора
 MaterialBindingStatus get bindingStatus;/// Название сметных позиций, к которым привязан материал (строкой)
 String? get linkedEstimateName;/// Список названий сметных позиций, к которым привязан материал
 List<String> get linkedEstimateNames;/// ID сметной позиции, к которой уже привязан материал
 String? get linkedEstimateId;/// ID записи в material_aliases (если привязан)
 String? get aliasId;
/// Create a copy of MaterialBindingModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MaterialBindingModelCopyWith<MaterialBindingModel> get copyWith => _$MaterialBindingModelCopyWithImpl<MaterialBindingModel>(this as MaterialBindingModel, _$identity);

  /// Serializes this MaterialBindingModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MaterialBindingModel&&(identical(other.name, name) || other.name == name)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.receiptNumber, receiptNumber) || other.receiptNumber == receiptNumber)&&(identical(other.bindingStatus, bindingStatus) || other.bindingStatus == bindingStatus)&&(identical(other.linkedEstimateName, linkedEstimateName) || other.linkedEstimateName == linkedEstimateName)&&const DeepCollectionEquality().equals(other.linkedEstimateNames, linkedEstimateNames)&&(identical(other.linkedEstimateId, linkedEstimateId) || other.linkedEstimateId == linkedEstimateId)&&(identical(other.aliasId, aliasId) || other.aliasId == aliasId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,unit,receiptNumber,bindingStatus,linkedEstimateName,const DeepCollectionEquality().hash(linkedEstimateNames),linkedEstimateId,aliasId);

@override
String toString() {
  return 'MaterialBindingModel(name: $name, unit: $unit, receiptNumber: $receiptNumber, bindingStatus: $bindingStatus, linkedEstimateName: $linkedEstimateName, linkedEstimateNames: $linkedEstimateNames, linkedEstimateId: $linkedEstimateId, aliasId: $aliasId)';
}


}

/// @nodoc
abstract mixin class $MaterialBindingModelCopyWith<$Res>  {
  factory $MaterialBindingModelCopyWith(MaterialBindingModel value, $Res Function(MaterialBindingModel) _then) = _$MaterialBindingModelCopyWithImpl;
@useResult
$Res call({
 String name, String? unit, String? receiptNumber, MaterialBindingStatus bindingStatus, String? linkedEstimateName, List<String> linkedEstimateNames, String? linkedEstimateId, String? aliasId
});




}
/// @nodoc
class _$MaterialBindingModelCopyWithImpl<$Res>
    implements $MaterialBindingModelCopyWith<$Res> {
  _$MaterialBindingModelCopyWithImpl(this._self, this._then);

  final MaterialBindingModel _self;
  final $Res Function(MaterialBindingModel) _then;

/// Create a copy of MaterialBindingModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? unit = freezed,Object? receiptNumber = freezed,Object? bindingStatus = null,Object? linkedEstimateName = freezed,Object? linkedEstimateNames = null,Object? linkedEstimateId = freezed,Object? aliasId = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,receiptNumber: freezed == receiptNumber ? _self.receiptNumber : receiptNumber // ignore: cast_nullable_to_non_nullable
as String?,bindingStatus: null == bindingStatus ? _self.bindingStatus : bindingStatus // ignore: cast_nullable_to_non_nullable
as MaterialBindingStatus,linkedEstimateName: freezed == linkedEstimateName ? _self.linkedEstimateName : linkedEstimateName // ignore: cast_nullable_to_non_nullable
as String?,linkedEstimateNames: null == linkedEstimateNames ? _self.linkedEstimateNames : linkedEstimateNames // ignore: cast_nullable_to_non_nullable
as List<String>,linkedEstimateId: freezed == linkedEstimateId ? _self.linkedEstimateId : linkedEstimateId // ignore: cast_nullable_to_non_nullable
as String?,aliasId: freezed == aliasId ? _self.aliasId : aliasId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _MaterialBindingModel implements MaterialBindingModel {
  const _MaterialBindingModel({required this.name, this.unit, this.receiptNumber, required this.bindingStatus, this.linkedEstimateName, final  List<String> linkedEstimateNames = const [], this.linkedEstimateId, this.aliasId}): _linkedEstimateNames = linkedEstimateNames;
  factory _MaterialBindingModel.fromJson(Map<String, dynamic> json) => _$MaterialBindingModelFromJson(json);

/// Наименование материала из накладной
@override final  String name;
/// Единица измерения из накладной
@override final  String? unit;
/// Номер накладной
@override final  String? receiptNumber;
/// Текущий статус привязки в рамках договора
@override final  MaterialBindingStatus bindingStatus;
/// Название сметных позиций, к которым привязан материал (строкой)
@override final  String? linkedEstimateName;
/// Список названий сметных позиций, к которым привязан материал
 final  List<String> _linkedEstimateNames;
/// Список названий сметных позиций, к которым привязан материал
@override@JsonKey() List<String> get linkedEstimateNames {
  if (_linkedEstimateNames is EqualUnmodifiableListView) return _linkedEstimateNames;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_linkedEstimateNames);
}

/// ID сметной позиции, к которой уже привязан материал
@override final  String? linkedEstimateId;
/// ID записи в material_aliases (если привязан)
@override final  String? aliasId;

/// Create a copy of MaterialBindingModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MaterialBindingModelCopyWith<_MaterialBindingModel> get copyWith => __$MaterialBindingModelCopyWithImpl<_MaterialBindingModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MaterialBindingModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MaterialBindingModel&&(identical(other.name, name) || other.name == name)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.receiptNumber, receiptNumber) || other.receiptNumber == receiptNumber)&&(identical(other.bindingStatus, bindingStatus) || other.bindingStatus == bindingStatus)&&(identical(other.linkedEstimateName, linkedEstimateName) || other.linkedEstimateName == linkedEstimateName)&&const DeepCollectionEquality().equals(other._linkedEstimateNames, _linkedEstimateNames)&&(identical(other.linkedEstimateId, linkedEstimateId) || other.linkedEstimateId == linkedEstimateId)&&(identical(other.aliasId, aliasId) || other.aliasId == aliasId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,unit,receiptNumber,bindingStatus,linkedEstimateName,const DeepCollectionEquality().hash(_linkedEstimateNames),linkedEstimateId,aliasId);

@override
String toString() {
  return 'MaterialBindingModel(name: $name, unit: $unit, receiptNumber: $receiptNumber, bindingStatus: $bindingStatus, linkedEstimateName: $linkedEstimateName, linkedEstimateNames: $linkedEstimateNames, linkedEstimateId: $linkedEstimateId, aliasId: $aliasId)';
}


}

/// @nodoc
abstract mixin class _$MaterialBindingModelCopyWith<$Res> implements $MaterialBindingModelCopyWith<$Res> {
  factory _$MaterialBindingModelCopyWith(_MaterialBindingModel value, $Res Function(_MaterialBindingModel) _then) = __$MaterialBindingModelCopyWithImpl;
@override @useResult
$Res call({
 String name, String? unit, String? receiptNumber, MaterialBindingStatus bindingStatus, String? linkedEstimateName, List<String> linkedEstimateNames, String? linkedEstimateId, String? aliasId
});




}
/// @nodoc
class __$MaterialBindingModelCopyWithImpl<$Res>
    implements _$MaterialBindingModelCopyWith<$Res> {
  __$MaterialBindingModelCopyWithImpl(this._self, this._then);

  final _MaterialBindingModel _self;
  final $Res Function(_MaterialBindingModel) _then;

/// Create a copy of MaterialBindingModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? unit = freezed,Object? receiptNumber = freezed,Object? bindingStatus = null,Object? linkedEstimateName = freezed,Object? linkedEstimateNames = null,Object? linkedEstimateId = freezed,Object? aliasId = freezed,}) {
  return _then(_MaterialBindingModel(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,receiptNumber: freezed == receiptNumber ? _self.receiptNumber : receiptNumber // ignore: cast_nullable_to_non_nullable
as String?,bindingStatus: null == bindingStatus ? _self.bindingStatus : bindingStatus // ignore: cast_nullable_to_non_nullable
as MaterialBindingStatus,linkedEstimateName: freezed == linkedEstimateName ? _self.linkedEstimateName : linkedEstimateName // ignore: cast_nullable_to_non_nullable
as String?,linkedEstimateNames: null == linkedEstimateNames ? _self._linkedEstimateNames : linkedEstimateNames // ignore: cast_nullable_to_non_nullable
as List<String>,linkedEstimateId: freezed == linkedEstimateId ? _self.linkedEstimateId : linkedEstimateId // ignore: cast_nullable_to_non_nullable
as String?,aliasId: freezed == aliasId ? _self.aliasId : aliasId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
