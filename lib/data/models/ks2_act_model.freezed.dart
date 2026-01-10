// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ks2_act_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Ks2ActModel {

 String get id;@JsonKey(name: 'company_id') String get companyId;@JsonKey(name: 'contract_id') String get contractId; String get number; DateTime get date;@JsonKey(name: 'period_from') DateTime get periodFrom;@JsonKey(name: 'period_to') DateTime get periodTo; Ks2Status get status;@JsonKey(name: 'total_amount') double get totalAmount;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;@JsonKey(name: 'created_by') String? get createdBy;
/// Create a copy of Ks2ActModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Ks2ActModelCopyWith<Ks2ActModel> get copyWith => _$Ks2ActModelCopyWithImpl<Ks2ActModel>(this as Ks2ActModel, _$identity);

  /// Serializes this Ks2ActModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Ks2ActModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.number, number) || other.number == number)&&(identical(other.date, date) || other.date == date)&&(identical(other.periodFrom, periodFrom) || other.periodFrom == periodFrom)&&(identical(other.periodTo, periodTo) || other.periodTo == periodTo)&&(identical(other.status, status) || other.status == status)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,contractId,number,date,periodFrom,periodTo,status,totalAmount,createdAt,updatedAt,createdBy);

@override
String toString() {
  return 'Ks2ActModel(id: $id, companyId: $companyId, contractId: $contractId, number: $number, date: $date, periodFrom: $periodFrom, periodTo: $periodTo, status: $status, totalAmount: $totalAmount, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class $Ks2ActModelCopyWith<$Res>  {
  factory $Ks2ActModelCopyWith(Ks2ActModel value, $Res Function(Ks2ActModel) _then) = _$Ks2ActModelCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'company_id') String companyId,@JsonKey(name: 'contract_id') String contractId, String number, DateTime date,@JsonKey(name: 'period_from') DateTime periodFrom,@JsonKey(name: 'period_to') DateTime periodTo, Ks2Status status,@JsonKey(name: 'total_amount') double totalAmount,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt,@JsonKey(name: 'created_by') String? createdBy
});




}
/// @nodoc
class _$Ks2ActModelCopyWithImpl<$Res>
    implements $Ks2ActModelCopyWith<$Res> {
  _$Ks2ActModelCopyWithImpl(this._self, this._then);

  final Ks2ActModel _self;
  final $Res Function(Ks2ActModel) _then;

/// Create a copy of Ks2ActModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? contractId = null,Object? number = null,Object? date = null,Object? periodFrom = null,Object? periodTo = null,Object? status = null,Object? totalAmount = null,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,contractId: null == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,periodFrom: null == periodFrom ? _self.periodFrom : periodFrom // ignore: cast_nullable_to_non_nullable
as DateTime,periodTo: null == periodTo ? _self.periodTo : periodTo // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as Ks2Status,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _Ks2ActModel extends Ks2ActModel {
  const _Ks2ActModel({required this.id, @JsonKey(name: 'company_id') required this.companyId, @JsonKey(name: 'contract_id') required this.contractId, required this.number, required this.date, @JsonKey(name: 'period_from') required this.periodFrom, @JsonKey(name: 'period_to') required this.periodTo, this.status = Ks2Status.draft, @JsonKey(name: 'total_amount') this.totalAmount = 0, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt, @JsonKey(name: 'created_by') this.createdBy}): super._();
  factory _Ks2ActModel.fromJson(Map<String, dynamic> json) => _$Ks2ActModelFromJson(json);

@override final  String id;
@override@JsonKey(name: 'company_id') final  String companyId;
@override@JsonKey(name: 'contract_id') final  String contractId;
@override final  String number;
@override final  DateTime date;
@override@JsonKey(name: 'period_from') final  DateTime periodFrom;
@override@JsonKey(name: 'period_to') final  DateTime periodTo;
@override@JsonKey() final  Ks2Status status;
@override@JsonKey(name: 'total_amount') final  double totalAmount;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;
@override@JsonKey(name: 'created_by') final  String? createdBy;

/// Create a copy of Ks2ActModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$Ks2ActModelCopyWith<_Ks2ActModel> get copyWith => __$Ks2ActModelCopyWithImpl<_Ks2ActModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$Ks2ActModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Ks2ActModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.contractId, contractId) || other.contractId == contractId)&&(identical(other.number, number) || other.number == number)&&(identical(other.date, date) || other.date == date)&&(identical(other.periodFrom, periodFrom) || other.periodFrom == periodFrom)&&(identical(other.periodTo, periodTo) || other.periodTo == periodTo)&&(identical(other.status, status) || other.status == status)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,companyId,contractId,number,date,periodFrom,periodTo,status,totalAmount,createdAt,updatedAt,createdBy);

@override
String toString() {
  return 'Ks2ActModel(id: $id, companyId: $companyId, contractId: $contractId, number: $number, date: $date, periodFrom: $periodFrom, periodTo: $periodTo, status: $status, totalAmount: $totalAmount, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class _$Ks2ActModelCopyWith<$Res> implements $Ks2ActModelCopyWith<$Res> {
  factory _$Ks2ActModelCopyWith(_Ks2ActModel value, $Res Function(_Ks2ActModel) _then) = __$Ks2ActModelCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'company_id') String companyId,@JsonKey(name: 'contract_id') String contractId, String number, DateTime date,@JsonKey(name: 'period_from') DateTime periodFrom,@JsonKey(name: 'period_to') DateTime periodTo, Ks2Status status,@JsonKey(name: 'total_amount') double totalAmount,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt,@JsonKey(name: 'created_by') String? createdBy
});




}
/// @nodoc
class __$Ks2ActModelCopyWithImpl<$Res>
    implements _$Ks2ActModelCopyWith<$Res> {
  __$Ks2ActModelCopyWithImpl(this._self, this._then);

  final _Ks2ActModel _self;
  final $Res Function(_Ks2ActModel) _then;

/// Create a copy of Ks2ActModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? contractId = null,Object? number = null,Object? date = null,Object? periodFrom = null,Object? periodTo = null,Object? status = null,Object? totalAmount = null,Object? createdAt = freezed,Object? updatedAt = freezed,Object? createdBy = freezed,}) {
  return _then(_Ks2ActModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,contractId: null == contractId ? _self.contractId : contractId // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,periodFrom: null == periodFrom ? _self.periodFrom : periodFrom // ignore: cast_nullable_to_non_nullable
as DateTime,periodTo: null == periodTo ? _self.periodTo : periodTo // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as Ks2Status,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
