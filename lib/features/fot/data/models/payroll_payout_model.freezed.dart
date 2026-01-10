// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payroll_payout_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PayrollPayoutModel {

 String get id;@JsonKey(name: 'employee_id') String get employeeId;@JsonKey(name: 'company_id') String get companyId; num get amount;@JsonKey(name: 'payout_date') DateTime get payoutDate; String get method; String get type;@JsonKey(name: 'created_at') DateTime? get createdAt; String? get comment;
/// Create a copy of PayrollPayoutModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PayrollPayoutModelCopyWith<PayrollPayoutModel> get copyWith => _$PayrollPayoutModelCopyWithImpl<PayrollPayoutModel>(this as PayrollPayoutModel, _$identity);

  /// Serializes this PayrollPayoutModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PayrollPayoutModel&&(identical(other.id, id) || other.id == id)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.payoutDate, payoutDate) || other.payoutDate == payoutDate)&&(identical(other.method, method) || other.method == method)&&(identical(other.type, type) || other.type == type)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.comment, comment) || other.comment == comment));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,employeeId,companyId,amount,payoutDate,method,type,createdAt,comment);

@override
String toString() {
  return 'PayrollPayoutModel(id: $id, employeeId: $employeeId, companyId: $companyId, amount: $amount, payoutDate: $payoutDate, method: $method, type: $type, createdAt: $createdAt, comment: $comment)';
}


}

/// @nodoc
abstract mixin class $PayrollPayoutModelCopyWith<$Res>  {
  factory $PayrollPayoutModelCopyWith(PayrollPayoutModel value, $Res Function(PayrollPayoutModel) _then) = _$PayrollPayoutModelCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'employee_id') String employeeId,@JsonKey(name: 'company_id') String companyId, num amount,@JsonKey(name: 'payout_date') DateTime payoutDate, String method, String type,@JsonKey(name: 'created_at') DateTime? createdAt, String? comment
});




}
/// @nodoc
class _$PayrollPayoutModelCopyWithImpl<$Res>
    implements $PayrollPayoutModelCopyWith<$Res> {
  _$PayrollPayoutModelCopyWithImpl(this._self, this._then);

  final PayrollPayoutModel _self;
  final $Res Function(PayrollPayoutModel) _then;

/// Create a copy of PayrollPayoutModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? employeeId = null,Object? companyId = null,Object? amount = null,Object? payoutDate = null,Object? method = null,Object? type = null,Object? createdAt = freezed,Object? comment = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,employeeId: null == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as num,payoutDate: null == payoutDate ? _self.payoutDate : payoutDate // ignore: cast_nullable_to_non_nullable
as DateTime,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _PayrollPayoutModel implements PayrollPayoutModel {
  const _PayrollPayoutModel({required this.id, @JsonKey(name: 'employee_id') required this.employeeId, @JsonKey(name: 'company_id') required this.companyId, required this.amount, @JsonKey(name: 'payout_date') required this.payoutDate, required this.method, required this.type, @JsonKey(name: 'created_at') this.createdAt, this.comment});
  factory _PayrollPayoutModel.fromJson(Map<String, dynamic> json) => _$PayrollPayoutModelFromJson(json);

@override final  String id;
@override@JsonKey(name: 'employee_id') final  String employeeId;
@override@JsonKey(name: 'company_id') final  String companyId;
@override final  num amount;
@override@JsonKey(name: 'payout_date') final  DateTime payoutDate;
@override final  String method;
@override final  String type;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override final  String? comment;

/// Create a copy of PayrollPayoutModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PayrollPayoutModelCopyWith<_PayrollPayoutModel> get copyWith => __$PayrollPayoutModelCopyWithImpl<_PayrollPayoutModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PayrollPayoutModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PayrollPayoutModel&&(identical(other.id, id) || other.id == id)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.payoutDate, payoutDate) || other.payoutDate == payoutDate)&&(identical(other.method, method) || other.method == method)&&(identical(other.type, type) || other.type == type)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.comment, comment) || other.comment == comment));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,employeeId,companyId,amount,payoutDate,method,type,createdAt,comment);

@override
String toString() {
  return 'PayrollPayoutModel(id: $id, employeeId: $employeeId, companyId: $companyId, amount: $amount, payoutDate: $payoutDate, method: $method, type: $type, createdAt: $createdAt, comment: $comment)';
}


}

/// @nodoc
abstract mixin class _$PayrollPayoutModelCopyWith<$Res> implements $PayrollPayoutModelCopyWith<$Res> {
  factory _$PayrollPayoutModelCopyWith(_PayrollPayoutModel value, $Res Function(_PayrollPayoutModel) _then) = __$PayrollPayoutModelCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'employee_id') String employeeId,@JsonKey(name: 'company_id') String companyId, num amount,@JsonKey(name: 'payout_date') DateTime payoutDate, String method, String type,@JsonKey(name: 'created_at') DateTime? createdAt, String? comment
});




}
/// @nodoc
class __$PayrollPayoutModelCopyWithImpl<$Res>
    implements _$PayrollPayoutModelCopyWith<$Res> {
  __$PayrollPayoutModelCopyWithImpl(this._self, this._then);

  final _PayrollPayoutModel _self;
  final $Res Function(_PayrollPayoutModel) _then;

/// Create a copy of PayrollPayoutModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? employeeId = null,Object? companyId = null,Object? amount = null,Object? payoutDate = null,Object? method = null,Object? type = null,Object? createdAt = freezed,Object? comment = freezed,}) {
  return _then(_PayrollPayoutModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,employeeId: null == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as num,payoutDate: null == payoutDate ? _self.payoutDate : payoutDate // ignore: cast_nullable_to_non_nullable
as DateTime,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
