// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'employee_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EmployeeModel {

 String get id; String get companyId;@JsonKey(name: 'photo_url') String? get photoUrl;@JsonKey(name: 'last_name') String get lastName;@JsonKey(name: 'first_name') String get firstName;@JsonKey(name: 'middle_name') String? get middleName;@JsonKey(name: 'birth_date') DateTime? get birthDate;@JsonKey(name: 'birth_place') String? get birthPlace; String? get citizenship; String? get phone;@JsonKey(name: 'clothing_size') String? get clothingSize;@JsonKey(name: 'shoe_size') String? get shoeSize; String? get height;@JsonKey(name: 'employment_date') DateTime? get employmentDate;@JsonKey(name: 'employment_type') EmploymentType get employmentType; String? get position; EmployeeStatus get status;@JsonKey(name: 'object_ids') List<String> get objectIds;@JsonKey(name: 'passport_series') String? get passportSeries;@JsonKey(name: 'passport_number') String? get passportNumber;@JsonKey(name: 'passport_issued_by') String? get passportIssuedBy;@JsonKey(name: 'passport_issue_date') DateTime? get passportIssueDate;@JsonKey(name: 'passport_department_code') String? get passportDepartmentCode;@JsonKey(name: 'registration_address') String? get registrationAddress; String? get inn; String? get snils;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;@JsonKey(name: 'current_hourly_rate', includeFromJson: false, includeToJson: false) double? get currentHourlyRate;
/// Create a copy of EmployeeModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmployeeModelCopyWith<EmployeeModel> get copyWith => _$EmployeeModelCopyWithImpl<EmployeeModel>(this as EmployeeModel, _$identity);

  /// Serializes this EmployeeModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmployeeModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.middleName, middleName) || other.middleName == middleName)&&(identical(other.birthDate, birthDate) || other.birthDate == birthDate)&&(identical(other.birthPlace, birthPlace) || other.birthPlace == birthPlace)&&(identical(other.citizenship, citizenship) || other.citizenship == citizenship)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.clothingSize, clothingSize) || other.clothingSize == clothingSize)&&(identical(other.shoeSize, shoeSize) || other.shoeSize == shoeSize)&&(identical(other.height, height) || other.height == height)&&(identical(other.employmentDate, employmentDate) || other.employmentDate == employmentDate)&&(identical(other.employmentType, employmentType) || other.employmentType == employmentType)&&(identical(other.position, position) || other.position == position)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.objectIds, objectIds)&&(identical(other.passportSeries, passportSeries) || other.passportSeries == passportSeries)&&(identical(other.passportNumber, passportNumber) || other.passportNumber == passportNumber)&&(identical(other.passportIssuedBy, passportIssuedBy) || other.passportIssuedBy == passportIssuedBy)&&(identical(other.passportIssueDate, passportIssueDate) || other.passportIssueDate == passportIssueDate)&&(identical(other.passportDepartmentCode, passportDepartmentCode) || other.passportDepartmentCode == passportDepartmentCode)&&(identical(other.registrationAddress, registrationAddress) || other.registrationAddress == registrationAddress)&&(identical(other.inn, inn) || other.inn == inn)&&(identical(other.snils, snils) || other.snils == snils)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.currentHourlyRate, currentHourlyRate) || other.currentHourlyRate == currentHourlyRate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,photoUrl,lastName,firstName,middleName,birthDate,birthPlace,citizenship,phone,clothingSize,shoeSize,height,employmentDate,employmentType,position,status,const DeepCollectionEquality().hash(objectIds),passportSeries,passportNumber,passportIssuedBy,passportIssueDate,passportDepartmentCode,registrationAddress,inn,snils,createdAt,updatedAt,currentHourlyRate]);

@override
String toString() {
  return 'EmployeeModel(id: $id, companyId: $companyId, photoUrl: $photoUrl, lastName: $lastName, firstName: $firstName, middleName: $middleName, birthDate: $birthDate, birthPlace: $birthPlace, citizenship: $citizenship, phone: $phone, clothingSize: $clothingSize, shoeSize: $shoeSize, height: $height, employmentDate: $employmentDate, employmentType: $employmentType, position: $position, status: $status, objectIds: $objectIds, passportSeries: $passportSeries, passportNumber: $passportNumber, passportIssuedBy: $passportIssuedBy, passportIssueDate: $passportIssueDate, passportDepartmentCode: $passportDepartmentCode, registrationAddress: $registrationAddress, inn: $inn, snils: $snils, createdAt: $createdAt, updatedAt: $updatedAt, currentHourlyRate: $currentHourlyRate)';
}


}

/// @nodoc
abstract mixin class $EmployeeModelCopyWith<$Res>  {
  factory $EmployeeModelCopyWith(EmployeeModel value, $Res Function(EmployeeModel) _then) = _$EmployeeModelCopyWithImpl;
@useResult
$Res call({
 String id, String companyId,@JsonKey(name: 'photo_url') String? photoUrl,@JsonKey(name: 'last_name') String lastName,@JsonKey(name: 'first_name') String firstName,@JsonKey(name: 'middle_name') String? middleName,@JsonKey(name: 'birth_date') DateTime? birthDate,@JsonKey(name: 'birth_place') String? birthPlace, String? citizenship, String? phone,@JsonKey(name: 'clothing_size') String? clothingSize,@JsonKey(name: 'shoe_size') String? shoeSize, String? height,@JsonKey(name: 'employment_date') DateTime? employmentDate,@JsonKey(name: 'employment_type') EmploymentType employmentType, String? position, EmployeeStatus status,@JsonKey(name: 'object_ids') List<String> objectIds,@JsonKey(name: 'passport_series') String? passportSeries,@JsonKey(name: 'passport_number') String? passportNumber,@JsonKey(name: 'passport_issued_by') String? passportIssuedBy,@JsonKey(name: 'passport_issue_date') DateTime? passportIssueDate,@JsonKey(name: 'passport_department_code') String? passportDepartmentCode,@JsonKey(name: 'registration_address') String? registrationAddress, String? inn, String? snils,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt,@JsonKey(name: 'current_hourly_rate', includeFromJson: false, includeToJson: false) double? currentHourlyRate
});




}
/// @nodoc
class _$EmployeeModelCopyWithImpl<$Res>
    implements $EmployeeModelCopyWith<$Res> {
  _$EmployeeModelCopyWithImpl(this._self, this._then);

  final EmployeeModel _self;
  final $Res Function(EmployeeModel) _then;

/// Create a copy of EmployeeModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? companyId = null,Object? photoUrl = freezed,Object? lastName = null,Object? firstName = null,Object? middleName = freezed,Object? birthDate = freezed,Object? birthPlace = freezed,Object? citizenship = freezed,Object? phone = freezed,Object? clothingSize = freezed,Object? shoeSize = freezed,Object? height = freezed,Object? employmentDate = freezed,Object? employmentType = null,Object? position = freezed,Object? status = null,Object? objectIds = null,Object? passportSeries = freezed,Object? passportNumber = freezed,Object? passportIssuedBy = freezed,Object? passportIssueDate = freezed,Object? passportDepartmentCode = freezed,Object? registrationAddress = freezed,Object? inn = freezed,Object? snils = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? currentHourlyRate = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,middleName: freezed == middleName ? _self.middleName : middleName // ignore: cast_nullable_to_non_nullable
as String?,birthDate: freezed == birthDate ? _self.birthDate : birthDate // ignore: cast_nullable_to_non_nullable
as DateTime?,birthPlace: freezed == birthPlace ? _self.birthPlace : birthPlace // ignore: cast_nullable_to_non_nullable
as String?,citizenship: freezed == citizenship ? _self.citizenship : citizenship // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,clothingSize: freezed == clothingSize ? _self.clothingSize : clothingSize // ignore: cast_nullable_to_non_nullable
as String?,shoeSize: freezed == shoeSize ? _self.shoeSize : shoeSize // ignore: cast_nullable_to_non_nullable
as String?,height: freezed == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as String?,employmentDate: freezed == employmentDate ? _self.employmentDate : employmentDate // ignore: cast_nullable_to_non_nullable
as DateTime?,employmentType: null == employmentType ? _self.employmentType : employmentType // ignore: cast_nullable_to_non_nullable
as EmploymentType,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as EmployeeStatus,objectIds: null == objectIds ? _self.objectIds : objectIds // ignore: cast_nullable_to_non_nullable
as List<String>,passportSeries: freezed == passportSeries ? _self.passportSeries : passportSeries // ignore: cast_nullable_to_non_nullable
as String?,passportNumber: freezed == passportNumber ? _self.passportNumber : passportNumber // ignore: cast_nullable_to_non_nullable
as String?,passportIssuedBy: freezed == passportIssuedBy ? _self.passportIssuedBy : passportIssuedBy // ignore: cast_nullable_to_non_nullable
as String?,passportIssueDate: freezed == passportIssueDate ? _self.passportIssueDate : passportIssueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,passportDepartmentCode: freezed == passportDepartmentCode ? _self.passportDepartmentCode : passportDepartmentCode // ignore: cast_nullable_to_non_nullable
as String?,registrationAddress: freezed == registrationAddress ? _self.registrationAddress : registrationAddress // ignore: cast_nullable_to_non_nullable
as String?,inn: freezed == inn ? _self.inn : inn // ignore: cast_nullable_to_non_nullable
as String?,snils: freezed == snils ? _self.snils : snils // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,currentHourlyRate: freezed == currentHourlyRate ? _self.currentHourlyRate : currentHourlyRate // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// @nodoc

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class _EmployeeModel extends EmployeeModel {
  const _EmployeeModel({required this.id, required this.companyId, @JsonKey(name: 'photo_url') this.photoUrl, @JsonKey(name: 'last_name') required this.lastName, @JsonKey(name: 'first_name') required this.firstName, @JsonKey(name: 'middle_name') this.middleName, @JsonKey(name: 'birth_date') this.birthDate, @JsonKey(name: 'birth_place') this.birthPlace, this.citizenship, this.phone, @JsonKey(name: 'clothing_size') this.clothingSize, @JsonKey(name: 'shoe_size') this.shoeSize, this.height, @JsonKey(name: 'employment_date') this.employmentDate, @JsonKey(name: 'employment_type') this.employmentType = EmploymentType.official, this.position, this.status = EmployeeStatus.working, @JsonKey(name: 'object_ids') final  List<String> objectIds = const <String>[], @JsonKey(name: 'passport_series') this.passportSeries, @JsonKey(name: 'passport_number') this.passportNumber, @JsonKey(name: 'passport_issued_by') this.passportIssuedBy, @JsonKey(name: 'passport_issue_date') this.passportIssueDate, @JsonKey(name: 'passport_department_code') this.passportDepartmentCode, @JsonKey(name: 'registration_address') this.registrationAddress, this.inn, this.snils, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt, @JsonKey(name: 'current_hourly_rate', includeFromJson: false, includeToJson: false) this.currentHourlyRate}): _objectIds = objectIds,super._();
  factory _EmployeeModel.fromJson(Map<String, dynamic> json) => _$EmployeeModelFromJson(json);

@override final  String id;
@override final  String companyId;
@override@JsonKey(name: 'photo_url') final  String? photoUrl;
@override@JsonKey(name: 'last_name') final  String lastName;
@override@JsonKey(name: 'first_name') final  String firstName;
@override@JsonKey(name: 'middle_name') final  String? middleName;
@override@JsonKey(name: 'birth_date') final  DateTime? birthDate;
@override@JsonKey(name: 'birth_place') final  String? birthPlace;
@override final  String? citizenship;
@override final  String? phone;
@override@JsonKey(name: 'clothing_size') final  String? clothingSize;
@override@JsonKey(name: 'shoe_size') final  String? shoeSize;
@override final  String? height;
@override@JsonKey(name: 'employment_date') final  DateTime? employmentDate;
@override@JsonKey(name: 'employment_type') final  EmploymentType employmentType;
@override final  String? position;
@override@JsonKey() final  EmployeeStatus status;
 final  List<String> _objectIds;
@override@JsonKey(name: 'object_ids') List<String> get objectIds {
  if (_objectIds is EqualUnmodifiableListView) return _objectIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_objectIds);
}

@override@JsonKey(name: 'passport_series') final  String? passportSeries;
@override@JsonKey(name: 'passport_number') final  String? passportNumber;
@override@JsonKey(name: 'passport_issued_by') final  String? passportIssuedBy;
@override@JsonKey(name: 'passport_issue_date') final  DateTime? passportIssueDate;
@override@JsonKey(name: 'passport_department_code') final  String? passportDepartmentCode;
@override@JsonKey(name: 'registration_address') final  String? registrationAddress;
@override final  String? inn;
@override final  String? snils;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;
@override@JsonKey(name: 'current_hourly_rate', includeFromJson: false, includeToJson: false) final  double? currentHourlyRate;

/// Create a copy of EmployeeModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EmployeeModelCopyWith<_EmployeeModel> get copyWith => __$EmployeeModelCopyWithImpl<_EmployeeModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EmployeeModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EmployeeModel&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.middleName, middleName) || other.middleName == middleName)&&(identical(other.birthDate, birthDate) || other.birthDate == birthDate)&&(identical(other.birthPlace, birthPlace) || other.birthPlace == birthPlace)&&(identical(other.citizenship, citizenship) || other.citizenship == citizenship)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.clothingSize, clothingSize) || other.clothingSize == clothingSize)&&(identical(other.shoeSize, shoeSize) || other.shoeSize == shoeSize)&&(identical(other.height, height) || other.height == height)&&(identical(other.employmentDate, employmentDate) || other.employmentDate == employmentDate)&&(identical(other.employmentType, employmentType) || other.employmentType == employmentType)&&(identical(other.position, position) || other.position == position)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._objectIds, _objectIds)&&(identical(other.passportSeries, passportSeries) || other.passportSeries == passportSeries)&&(identical(other.passportNumber, passportNumber) || other.passportNumber == passportNumber)&&(identical(other.passportIssuedBy, passportIssuedBy) || other.passportIssuedBy == passportIssuedBy)&&(identical(other.passportIssueDate, passportIssueDate) || other.passportIssueDate == passportIssueDate)&&(identical(other.passportDepartmentCode, passportDepartmentCode) || other.passportDepartmentCode == passportDepartmentCode)&&(identical(other.registrationAddress, registrationAddress) || other.registrationAddress == registrationAddress)&&(identical(other.inn, inn) || other.inn == inn)&&(identical(other.snils, snils) || other.snils == snils)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.currentHourlyRate, currentHourlyRate) || other.currentHourlyRate == currentHourlyRate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,photoUrl,lastName,firstName,middleName,birthDate,birthPlace,citizenship,phone,clothingSize,shoeSize,height,employmentDate,employmentType,position,status,const DeepCollectionEquality().hash(_objectIds),passportSeries,passportNumber,passportIssuedBy,passportIssueDate,passportDepartmentCode,registrationAddress,inn,snils,createdAt,updatedAt,currentHourlyRate]);

@override
String toString() {
  return 'EmployeeModel(id: $id, companyId: $companyId, photoUrl: $photoUrl, lastName: $lastName, firstName: $firstName, middleName: $middleName, birthDate: $birthDate, birthPlace: $birthPlace, citizenship: $citizenship, phone: $phone, clothingSize: $clothingSize, shoeSize: $shoeSize, height: $height, employmentDate: $employmentDate, employmentType: $employmentType, position: $position, status: $status, objectIds: $objectIds, passportSeries: $passportSeries, passportNumber: $passportNumber, passportIssuedBy: $passportIssuedBy, passportIssueDate: $passportIssueDate, passportDepartmentCode: $passportDepartmentCode, registrationAddress: $registrationAddress, inn: $inn, snils: $snils, createdAt: $createdAt, updatedAt: $updatedAt, currentHourlyRate: $currentHourlyRate)';
}


}

/// @nodoc
abstract mixin class _$EmployeeModelCopyWith<$Res> implements $EmployeeModelCopyWith<$Res> {
  factory _$EmployeeModelCopyWith(_EmployeeModel value, $Res Function(_EmployeeModel) _then) = __$EmployeeModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId,@JsonKey(name: 'photo_url') String? photoUrl,@JsonKey(name: 'last_name') String lastName,@JsonKey(name: 'first_name') String firstName,@JsonKey(name: 'middle_name') String? middleName,@JsonKey(name: 'birth_date') DateTime? birthDate,@JsonKey(name: 'birth_place') String? birthPlace, String? citizenship, String? phone,@JsonKey(name: 'clothing_size') String? clothingSize,@JsonKey(name: 'shoe_size') String? shoeSize, String? height,@JsonKey(name: 'employment_date') DateTime? employmentDate,@JsonKey(name: 'employment_type') EmploymentType employmentType, String? position, EmployeeStatus status,@JsonKey(name: 'object_ids') List<String> objectIds,@JsonKey(name: 'passport_series') String? passportSeries,@JsonKey(name: 'passport_number') String? passportNumber,@JsonKey(name: 'passport_issued_by') String? passportIssuedBy,@JsonKey(name: 'passport_issue_date') DateTime? passportIssueDate,@JsonKey(name: 'passport_department_code') String? passportDepartmentCode,@JsonKey(name: 'registration_address') String? registrationAddress, String? inn, String? snils,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt,@JsonKey(name: 'current_hourly_rate', includeFromJson: false, includeToJson: false) double? currentHourlyRate
});




}
/// @nodoc
class __$EmployeeModelCopyWithImpl<$Res>
    implements _$EmployeeModelCopyWith<$Res> {
  __$EmployeeModelCopyWithImpl(this._self, this._then);

  final _EmployeeModel _self;
  final $Res Function(_EmployeeModel) _then;

/// Create a copy of EmployeeModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? photoUrl = freezed,Object? lastName = null,Object? firstName = null,Object? middleName = freezed,Object? birthDate = freezed,Object? birthPlace = freezed,Object? citizenship = freezed,Object? phone = freezed,Object? clothingSize = freezed,Object? shoeSize = freezed,Object? height = freezed,Object? employmentDate = freezed,Object? employmentType = null,Object? position = freezed,Object? status = null,Object? objectIds = null,Object? passportSeries = freezed,Object? passportNumber = freezed,Object? passportIssuedBy = freezed,Object? passportIssueDate = freezed,Object? passportDepartmentCode = freezed,Object? registrationAddress = freezed,Object? inn = freezed,Object? snils = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? currentHourlyRate = freezed,}) {
  return _then(_EmployeeModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,middleName: freezed == middleName ? _self.middleName : middleName // ignore: cast_nullable_to_non_nullable
as String?,birthDate: freezed == birthDate ? _self.birthDate : birthDate // ignore: cast_nullable_to_non_nullable
as DateTime?,birthPlace: freezed == birthPlace ? _self.birthPlace : birthPlace // ignore: cast_nullable_to_non_nullable
as String?,citizenship: freezed == citizenship ? _self.citizenship : citizenship // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,clothingSize: freezed == clothingSize ? _self.clothingSize : clothingSize // ignore: cast_nullable_to_non_nullable
as String?,shoeSize: freezed == shoeSize ? _self.shoeSize : shoeSize // ignore: cast_nullable_to_non_nullable
as String?,height: freezed == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as String?,employmentDate: freezed == employmentDate ? _self.employmentDate : employmentDate // ignore: cast_nullable_to_non_nullable
as DateTime?,employmentType: null == employmentType ? _self.employmentType : employmentType // ignore: cast_nullable_to_non_nullable
as EmploymentType,position: freezed == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as EmployeeStatus,objectIds: null == objectIds ? _self._objectIds : objectIds // ignore: cast_nullable_to_non_nullable
as List<String>,passportSeries: freezed == passportSeries ? _self.passportSeries : passportSeries // ignore: cast_nullable_to_non_nullable
as String?,passportNumber: freezed == passportNumber ? _self.passportNumber : passportNumber // ignore: cast_nullable_to_non_nullable
as String?,passportIssuedBy: freezed == passportIssuedBy ? _self.passportIssuedBy : passportIssuedBy // ignore: cast_nullable_to_non_nullable
as String?,passportIssueDate: freezed == passportIssueDate ? _self.passportIssueDate : passportIssueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,passportDepartmentCode: freezed == passportDepartmentCode ? _self.passportDepartmentCode : passportDepartmentCode // ignore: cast_nullable_to_non_nullable
as String?,registrationAddress: freezed == registrationAddress ? _self.registrationAddress : registrationAddress // ignore: cast_nullable_to_non_nullable
as String?,inn: freezed == inn ? _self.inn : inn // ignore: cast_nullable_to_non_nullable
as String?,snils: freezed == snils ? _self.snils : snils // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,currentHourlyRate: freezed == currentHourlyRate ? _self.currentHourlyRate : currentHourlyRate // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
