// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'estimate_completion_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EstimateCompletionModel {

@JsonKey(name: 'estimate_id', fromJson: _parseString) String get estimateId;@JsonKey(name: 'object_id', fromJson: _parseString) String get objectId;@JsonKey(name: 'contract_id', fromJson: _parseString) String get contractId; String get system; String get subsystem; String get number; String get name; String get unit;@JsonKey(fromJson: _parseDouble) double get quantity;@JsonKey(fromJson: _parseDouble) double get total;@JsonKey(name: 'completed_quantity', fromJson: _parseDouble) double get completedQuantity;@JsonKey(name: 'completed_total', fromJson: _parseDouble) double get completedTotal;@JsonKey(fromJson: _parseDouble) double get percentage;@JsonKey(name: 'remaining_quantity', fromJson: _parseDouble) double get remainingQuantity;
/// Create a copy of EstimateCompletionModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EstimateCompletionModelCopyWith<EstimateCompletionModel> get copyWith => _$EstimateCompletionModelCopyWithImpl<EstimateCompletionModel>(this as EstimateCompletionModel, _$identity);

  /// Serializes this EstimateCompletionModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EstimateCompletionModel&&(identical(other.estimateId, estimateId) || other.estimateId == estimateId)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.system, system) || other.system == system)&&(identical(other.subsystem, subsystem) || other.subsystem == subsystem)&&(identical(other.number, number) || other.number == number)&&(identical(other.name, name) || other.name == name)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.total, total) || other.total == total)&&(identical(other.completedQuantity, completedQuantity) || other.completedQuantity == completedQuantity)&&(identical(other.completedTotal, completedTotal) || other.completedTotal == completedTotal)&&(identical(other.percentage, percentage) || other.percentage == percentage)&&(identical(other.remainingQuantity, remainingQuantity) || other.remainingQuantity == remainingQuantity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,estimateId,objectId,contractId,system,subsystem,number,name,unit,quantity,total,completedQuantity,completedTotal,percentage,remainingQuantity);

@override
String toString() {
  return 'EstimateCompletionModel(estimateId: $estimateId, objectId: $objectId, contractId: $contractId, system: $system, subsystem: $subsystem, number: $number, name: $name, unit: $unit, quantity: $quantity, total: $total, completedQuantity: $completedQuantity, completedTotal: $completedTotal, percentage: $percentage, remainingQuantity: $remainingQuantity)';
}


}

/// @nodoc
abstract mixin class $EstimateCompletionModelCopyWith<$Res>  {
  factory $EstimateCompletionModelCopyWith(EstimateCompletionModel value, $Res Function(EstimateCompletionModel) _then) = _$EstimateCompletionModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'estimate_id', fromJson: _parseString) String estimateId,@JsonKey(name: 'object_id', fromJson: _parseString) String objectId,@JsonKey(name: 'contract_id', fromJson: _parseString) String contractId, String system, String subsystem, String number, String name, String unit,@JsonKey(fromJson: _parseDouble) double quantity,@JsonKey(fromJson: _parseDouble) double total,@JsonKey(name: 'completed_quantity', fromJson: _parseDouble) double completedQuantity,@JsonKey(name: 'completed_total', fromJson: _parseDouble) double completedTotal,@JsonKey(fromJson: _parseDouble) double percentage,@JsonKey(name: 'remaining_quantity', fromJson: _parseDouble) double remainingQuantity
});




}
/// @nodoc
class _$EstimateCompletionModelCopyWithImpl<$Res>
    implements $EstimateCompletionModelCopyWith<$Res> {
  _$EstimateCompletionModelCopyWithImpl(this._self, this._then);

  final EstimateCompletionModel _self;
  final $Res Function(EstimateCompletionModel) _then;

/// Create a copy of EstimateCompletionModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? estimateId = null,Object? objectId = null,Object? contractId = null,Object? system = null,Object? subsystem = null,Object? number = null,Object? name = null,Object? unit = null,Object? quantity = null,Object? total = null,Object? completedQuantity = null,Object? completedTotal = null,Object? percentage = null,Object? remainingQuantity = null,}) {
  return _then(_self.copyWith(
estimateId: null == estimateId ? _self.estimateId : estimateId // ignore: cast_nullable_to_non_nullable
as String,objectId: null == objectId ? _self.objectId : objectId // ignore: cast_nullable_to_non_nullable
as String,contractId: null == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String,system: null == system ? _self.system : system // ignore: cast_nullable_to_non_nullable
as String,subsystem: null == subsystem ? _self.subsystem : subsystem // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as double,completedQuantity: null == completedQuantity ? _self.completedQuantity : completedQuantity // ignore: cast_nullable_to_non_nullable
as double,completedTotal: null == completedTotal ? _self.completedTotal : completedTotal // ignore: cast_nullable_to_non_nullable
as double,percentage: null == percentage ? _self.percentage : percentage // ignore: cast_nullable_to_non_nullable
as double,remainingQuantity: null == remainingQuantity ? _self.remainingQuantity : remainingQuantity // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _EstimateCompletionModel implements EstimateCompletionModel {
  const _EstimateCompletionModel({@JsonKey(name: 'estimate_id', fromJson: _parseString) this.estimateId = '', @JsonKey(name: 'object_id', fromJson: _parseString) this.objectId = '', @JsonKey(name: 'contract_id', fromJson: _parseString) this.contractId = '', this.system = '', this.subsystem = '', this.number = '', this.name = '', this.unit = '', @JsonKey(fromJson: _parseDouble) this.quantity = 0.0, @JsonKey(fromJson: _parseDouble) this.total = 0.0, @JsonKey(name: 'completed_quantity', fromJson: _parseDouble) this.completedQuantity = 0.0, @JsonKey(name: 'completed_total', fromJson: _parseDouble) this.completedTotal = 0.0, @JsonKey(fromJson: _parseDouble) this.percentage = 0.0, @JsonKey(name: 'remaining_quantity', fromJson: _parseDouble) this.remainingQuantity = 0.0});
  factory _EstimateCompletionModel.fromJson(Map<String, dynamic> json) => _$EstimateCompletionModelFromJson(json);

@override@JsonKey(name: 'estimate_id', fromJson: _parseString) final  String estimateId;
@override@JsonKey(name: 'object_id', fromJson: _parseString) final  String objectId;
@override@JsonKey(name: 'contract_id', fromJson: _parseString) final  String contractId;
@override@JsonKey() final  String system;
@override@JsonKey() final  String subsystem;
@override@JsonKey() final  String number;
@override@JsonKey() final  String name;
@override@JsonKey() final  String unit;
@override@JsonKey(fromJson: _parseDouble) final  double quantity;
@override@JsonKey(fromJson: _parseDouble) final  double total;
@override@JsonKey(name: 'completed_quantity', fromJson: _parseDouble) final  double completedQuantity;
@override@JsonKey(name: 'completed_total', fromJson: _parseDouble) final  double completedTotal;
@override@JsonKey(fromJson: _parseDouble) final  double percentage;
@override@JsonKey(name: 'remaining_quantity', fromJson: _parseDouble) final  double remainingQuantity;

/// Create a copy of EstimateCompletionModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EstimateCompletionModelCopyWith<_EstimateCompletionModel> get copyWith => __$EstimateCompletionModelCopyWithImpl<_EstimateCompletionModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EstimateCompletionModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EstimateCompletionModel&&(identical(other.estimateId, estimateId) || other.estimateId == estimateId)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.system, system) || other.system == system)&&(identical(other.subsystem, subsystem) || other.subsystem == subsystem)&&(identical(other.number, number) || other.number == number)&&(identical(other.name, name) || other.name == name)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.total, total) || other.total == total)&&(identical(other.completedQuantity, completedQuantity) || other.completedQuantity == completedQuantity)&&(identical(other.completedTotal, completedTotal) || other.completedTotal == completedTotal)&&(identical(other.percentage, percentage) || other.percentage == percentage)&&(identical(other.remainingQuantity, remainingQuantity) || other.remainingQuantity == remainingQuantity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,estimateId,objectId,contractId,system,subsystem,number,name,unit,quantity,total,completedQuantity,completedTotal,percentage,remainingQuantity);

@override
String toString() {
  return 'EstimateCompletionModel(estimateId: $estimateId, objectId: $objectId, contractId: $contractId, system: $system, subsystem: $subsystem, number: $number, name: $name, unit: $unit, quantity: $quantity, total: $total, completedQuantity: $completedQuantity, completedTotal: $completedTotal, percentage: $percentage, remainingQuantity: $remainingQuantity)';
}


}

/// @nodoc
abstract mixin class _$EstimateCompletionModelCopyWith<$Res> implements $EstimateCompletionModelCopyWith<$Res> {
  factory _$EstimateCompletionModelCopyWith(_EstimateCompletionModel value, $Res Function(_EstimateCompletionModel) _then) = __$EstimateCompletionModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'estimate_id', fromJson: _parseString) String estimateId,@JsonKey(name: 'object_id', fromJson: _parseString) String objectId,@JsonKey(name: 'contract_id', fromJson: _parseString) String contractId, String system, String subsystem, String number, String name, String unit,@JsonKey(fromJson: _parseDouble) double quantity,@JsonKey(fromJson: _parseDouble) double total,@JsonKey(name: 'completed_quantity', fromJson: _parseDouble) double completedQuantity,@JsonKey(name: 'completed_total', fromJson: _parseDouble) double completedTotal,@JsonKey(fromJson: _parseDouble) double percentage,@JsonKey(name: 'remaining_quantity', fromJson: _parseDouble) double remainingQuantity
});




}
/// @nodoc
class __$EstimateCompletionModelCopyWithImpl<$Res>
    implements _$EstimateCompletionModelCopyWith<$Res> {
  __$EstimateCompletionModelCopyWithImpl(this._self, this._then);

  final _EstimateCompletionModel _self;
  final $Res Function(_EstimateCompletionModel) _then;

/// Create a copy of EstimateCompletionModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? estimateId = null,Object? objectId = null,Object? contractId = null,Object? system = null,Object? subsystem = null,Object? number = null,Object? name = null,Object? unit = null,Object? quantity = null,Object? total = null,Object? completedQuantity = null,Object? completedTotal = null,Object? percentage = null,Object? remainingQuantity = null,}) {
  return _then(_EstimateCompletionModel(
estimateId: null == estimateId ? _self.estimateId : estimateId // ignore: cast_nullable_to_non_nullable
as String,objectId: null == objectId ? _self.objectId : objectId // ignore: cast_nullable_to_non_nullable
as String,contractId: null == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String,system: null == system ? _self.system : system // ignore: cast_nullable_to_non_nullable
as String,subsystem: null == subsystem ? _self.subsystem : subsystem // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as double,completedQuantity: null == completedQuantity ? _self.completedQuantity : completedQuantity // ignore: cast_nullable_to_non_nullable
as double,completedTotal: null == completedTotal ? _self.completedTotal : completedTotal // ignore: cast_nullable_to_non_nullable
as double,percentage: null == percentage ? _self.percentage : percentage // ignore: cast_nullable_to_non_nullable
as double,remainingQuantity: null == remainingQuantity ? _self.remainingQuantity : remainingQuantity // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
