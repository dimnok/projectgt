// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'purchase_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PurchaseRequest {

 String get id; String get companyId; String get number; String get objectId; String? get objectName; String get createdBy; String? get createdByName; String? get currentAssigneeId; PurchaseRequestStatus get status; String? get comment; double get totalAmount; DateTime? get createdAt; DateTime? get updatedAt; DateTime? get submittedAt; DateTime? get completedAt;
/// Create a copy of PurchaseRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PurchaseRequestCopyWith<PurchaseRequest> get copyWith => _$PurchaseRequestCopyWithImpl<PurchaseRequest>(this as PurchaseRequest, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PurchaseRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.number, number) || other.number == number)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.objectName, objectName) || other.objectName == objectName)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdByName, createdByName) || other.createdByName == createdByName)&&(identical(other.currentAssigneeId, currentAssigneeId) || other.currentAssigneeId == currentAssigneeId)&&(identical(other.status, status) || other.status == status)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,number,objectId,objectName,createdBy,createdByName,currentAssigneeId,status,comment,totalAmount,createdAt,updatedAt,submittedAt,completedAt);

@override
String toString() {
  return 'PurchaseRequest(id: $id, companyId: $companyId, number: $number, objectId: $objectId, objectName: $objectName, createdBy: $createdBy, createdByName: $createdByName, currentAssigneeId: $currentAssigneeId, status: $status, comment: $comment, totalAmount: $totalAmount, createdAt: $createdAt, updatedAt: $updatedAt, submittedAt: $submittedAt, completedAt: $completedAt)';
}


}

/// @nodoc
abstract mixin class $PurchaseRequestCopyWith<$Res>  {
  factory $PurchaseRequestCopyWith(PurchaseRequest value, $Res Function(PurchaseRequest) _then) = _$PurchaseRequestCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String number, String objectId, String? objectName, String createdBy, String? createdByName, String? currentAssigneeId, PurchaseRequestStatus status, String? comment, double totalAmount, DateTime? createdAt, DateTime? updatedAt, DateTime? submittedAt, DateTime? completedAt
});




}
/// @nodoc
class _$PurchaseRequestCopyWithImpl<$Res>
    implements $PurchaseRequestCopyWith<$Res> {
  _$PurchaseRequestCopyWithImpl(this._self, this._then);

  final PurchaseRequest _self;
  final $Res Function(PurchaseRequest) _then;

/// Create a copy of PurchaseRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? number = null,Object? objectId = null,Object? objectName = freezed,Object? createdBy = null,Object? createdByName = freezed,Object? currentAssigneeId = freezed,Object? status = null,Object? comment = freezed,Object? totalAmount = null,Object? createdAt = freezed,Object? updatedAt = freezed,Object? submittedAt = freezed,Object? completedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,objectId: null == objectId ? _self.objectId : objectId // ignore: cast_nullable_to_non_nullable
as String,objectName: freezed == objectName ? _self.objectName : objectName // ignore: cast_nullable_to_non_nullable
as String?,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdByName: freezed == createdByName ? _self.createdByName : createdByName // ignore: cast_nullable_to_non_nullable
as String?,currentAssigneeId: freezed == currentAssigneeId ? _self.currentAssigneeId : currentAssigneeId // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PurchaseRequestStatus,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,submittedAt: freezed == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc


class _PurchaseRequest extends PurchaseRequest {
  const _PurchaseRequest({required this.id, required this.companyId, required this.number, required this.objectId, this.objectName, required this.createdBy, this.createdByName, this.currentAssigneeId, required this.status, this.comment, this.totalAmount = 0, this.createdAt, this.updatedAt, this.submittedAt, this.completedAt}): super._();
  

@override final  String id;
@override final  String companyId;
@override final  String number;
@override final  String objectId;
@override final  String? objectName;
@override final  String createdBy;
@override final  String? createdByName;
@override final  String? currentAssigneeId;
@override final  PurchaseRequestStatus status;
@override final  String? comment;
@override@JsonKey() final  double totalAmount;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;
@override final  DateTime? submittedAt;
@override final  DateTime? completedAt;

/// Create a copy of PurchaseRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PurchaseRequestCopyWith<_PurchaseRequest> get copyWith => __$PurchaseRequestCopyWithImpl<_PurchaseRequest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PurchaseRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.number, number) || other.number == number)&&(identical(other.objectId, objectId) || other.objectId == objectId)&&(identical(other.objectName, objectName) || other.objectName == objectName)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdByName, createdByName) || other.createdByName == createdByName)&&(identical(other.currentAssigneeId, currentAssigneeId) || other.currentAssigneeId == currentAssigneeId)&&(identical(other.status, status) || other.status == status)&&(identical(other.comment, comment) || other.comment == comment)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,companyId,number,objectId,objectName,createdBy,createdByName,currentAssigneeId,status,comment,totalAmount,createdAt,updatedAt,submittedAt,completedAt);

@override
String toString() {
  return 'PurchaseRequest(id: $id, companyId: $companyId, number: $number, objectId: $objectId, objectName: $objectName, createdBy: $createdBy, createdByName: $createdByName, currentAssigneeId: $currentAssigneeId, status: $status, comment: $comment, totalAmount: $totalAmount, createdAt: $createdAt, updatedAt: $updatedAt, submittedAt: $submittedAt, completedAt: $completedAt)';
}


}

/// @nodoc
abstract mixin class _$PurchaseRequestCopyWith<$Res> implements $PurchaseRequestCopyWith<$Res> {
  factory _$PurchaseRequestCopyWith(_PurchaseRequest value, $Res Function(_PurchaseRequest) _then) = __$PurchaseRequestCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String number, String objectId, String? objectName, String createdBy, String? createdByName, String? currentAssigneeId, PurchaseRequestStatus status, String? comment, double totalAmount, DateTime? createdAt, DateTime? updatedAt, DateTime? submittedAt, DateTime? completedAt
});




}
/// @nodoc
class __$PurchaseRequestCopyWithImpl<$Res>
    implements _$PurchaseRequestCopyWith<$Res> {
  __$PurchaseRequestCopyWithImpl(this._self, this._then);

  final _PurchaseRequest _self;
  final $Res Function(_PurchaseRequest) _then;

/// Create a copy of PurchaseRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? number = null,Object? objectId = null,Object? objectName = freezed,Object? createdBy = null,Object? createdByName = freezed,Object? currentAssigneeId = freezed,Object? status = null,Object? comment = freezed,Object? totalAmount = null,Object? createdAt = freezed,Object? updatedAt = freezed,Object? submittedAt = freezed,Object? completedAt = freezed,}) {
  return _then(_PurchaseRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,objectId: null == objectId ? _self.objectId : objectId // ignore: cast_nullable_to_non_nullable
as String,objectName: freezed == objectName ? _self.objectName : objectName // ignore: cast_nullable_to_non_nullable
as String?,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdByName: freezed == createdByName ? _self.createdByName : createdByName // ignore: cast_nullable_to_non_nullable
as String?,currentAssigneeId: freezed == currentAssigneeId ? _self.currentAssigneeId : currentAssigneeId // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PurchaseRequestStatus,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as double,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,submittedAt: freezed == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
