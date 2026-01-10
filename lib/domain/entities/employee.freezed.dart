// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'employee.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Employee {

/// Уникальный идентификатор сотрудника.
 String get id;/// ID компании, к которой принадлежит сотрудник.
 String get companyId;/// URL фотографии сотрудника.
 String? get photoUrl;/// Фамилия.
 String get lastName;/// Имя.
 String get firstName;/// Отчество.
 String? get middleName;/// Дата рождения.
 DateTime? get birthDate;/// Место рождения.
 String? get birthPlace;/// Гражданство.
 String? get citizenship;/// Телефон.
 String? get phone;/// Размер одежды.
 String? get clothingSize;/// Размер обуви.
 String? get shoeSize;/// Рост.
 String? get height;/// Дата приёма на работу.
 DateTime? get employmentDate;/// Тип занятости ([EmploymentType]).
 EmploymentType get employmentType;/// Должность.
 String? get position;/// Статус сотрудника ([EmployeeStatus]).
 EmployeeStatus get status;/// Список идентификаторов объектов, к которым привязан сотрудник.
 List<String> get objectIds;/// Серия паспорта.
 String? get passportSeries;/// Номер паспорта.
 String? get passportNumber;/// Кем выдан паспорт.
 String? get passportIssuedBy;/// Дата выдачи паспорта.
 DateTime? get passportIssueDate;/// Код подразделения, выдавшего паспорт.
 String? get passportDepartmentCode;/// Адрес регистрации.
 String? get registrationAddress;/// ИНН.
 String? get inn;/// СНИЛС.
 String? get snils;/// Дата создания записи.
 DateTime? get createdAt;/// Дата последнего обновления записи.
 DateTime? get updatedAt;/// Текущая почасовая ставка сотрудника (из таблицы employee_rates).
 double? get currentHourlyRate;
/// Create a copy of Employee
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmployeeCopyWith<Employee> get copyWith => _$EmployeeCopyWithImpl<Employee>(this as Employee, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Employee&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.middleName, middleName) || other.middleName == middleName)&&(identical(other.birthDate, birthDate) || other.birthDate == birthDate)&&(identical(other.birthPlace, birthPlace) || other.birthPlace == birthPlace)&&(identical(other.citizenship, citizenship) || other.citizenship == citizenship)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.clothingSize, clothingSize) || other.clothingSize == clothingSize)&&(identical(other.shoeSize, shoeSize) || other.shoeSize == shoeSize)&&(identical(other.height, height) || other.height == height)&&(identical(other.employmentDate, employmentDate) || other.employmentDate == employmentDate)&&(identical(other.employmentType, employmentType) || other.employmentType == employmentType)&&(identical(other.position, position) || other.position == position)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.objectIds, objectIds)&&(identical(other.passportSeries, passportSeries) || other.passportSeries == passportSeries)&&(identical(other.passportNumber, passportNumber) || other.passportNumber == passportNumber)&&(identical(other.passportIssuedBy, passportIssuedBy) || other.passportIssuedBy == passportIssuedBy)&&(identical(other.passportIssueDate, passportIssueDate) || other.passportIssueDate == passportIssueDate)&&(identical(other.passportDepartmentCode, passportDepartmentCode) || other.passportDepartmentCode == passportDepartmentCode)&&(identical(other.registrationAddress, registrationAddress) || other.registrationAddress == registrationAddress)&&(identical(other.inn, inn) || other.inn == inn)&&(identical(other.snils, snils) || other.snils == snils)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.currentHourlyRate, currentHourlyRate) || other.currentHourlyRate == currentHourlyRate));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,photoUrl,lastName,firstName,middleName,birthDate,birthPlace,citizenship,phone,clothingSize,shoeSize,height,employmentDate,employmentType,position,status,const DeepCollectionEquality().hash(objectIds),passportSeries,passportNumber,passportIssuedBy,passportIssueDate,passportDepartmentCode,registrationAddress,inn,snils,createdAt,updatedAt,currentHourlyRate]);

@override
String toString() {
  return 'Employee(id: $id, companyId: $companyId, photoUrl: $photoUrl, lastName: $lastName, firstName: $firstName, middleName: $middleName, birthDate: $birthDate, birthPlace: $birthPlace, citizenship: $citizenship, phone: $phone, clothingSize: $clothingSize, shoeSize: $shoeSize, height: $height, employmentDate: $employmentDate, employmentType: $employmentType, position: $position, status: $status, objectIds: $objectIds, passportSeries: $passportSeries, passportNumber: $passportNumber, passportIssuedBy: $passportIssuedBy, passportIssueDate: $passportIssueDate, passportDepartmentCode: $passportDepartmentCode, registrationAddress: $registrationAddress, inn: $inn, snils: $snils, createdAt: $createdAt, updatedAt: $updatedAt, currentHourlyRate: $currentHourlyRate)';
}


}

/// @nodoc
abstract mixin class $EmployeeCopyWith<$Res>  {
  factory $EmployeeCopyWith(Employee value, $Res Function(Employee) _then) = _$EmployeeCopyWithImpl;
@useResult
$Res call({
 String id, String companyId, String? photoUrl, String lastName, String firstName, String? middleName, DateTime? birthDate, String? birthPlace, String? citizenship, String? phone, String? clothingSize, String? shoeSize, String? height, DateTime? employmentDate, EmploymentType employmentType, String? position, EmployeeStatus status, List<String> objectIds, String? passportSeries, String? passportNumber, String? passportIssuedBy, DateTime? passportIssueDate, String? passportDepartmentCode, String? registrationAddress, String? inn, String? snils, DateTime? createdAt, DateTime? updatedAt, double? currentHourlyRate
});




}
/// @nodoc
class _$EmployeeCopyWithImpl<$Res>
    implements $EmployeeCopyWith<$Res> {
  _$EmployeeCopyWithImpl(this._self, this._then);

  final Employee _self;
  final $Res Function(Employee) _then;

/// Create a copy of Employee
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


class _Employee extends Employee {
  const _Employee({required this.id, required this.companyId, this.photoUrl, required this.lastName, required this.firstName, this.middleName, this.birthDate, this.birthPlace, this.citizenship, this.phone, this.clothingSize, this.shoeSize, this.height, this.employmentDate, this.employmentType = EmploymentType.official, this.position, this.status = EmployeeStatus.working, final  List<String> objectIds = const <String>[], this.passportSeries, this.passportNumber, this.passportIssuedBy, this.passportIssueDate, this.passportDepartmentCode, this.registrationAddress, this.inn, this.snils, this.createdAt, this.updatedAt, this.currentHourlyRate}): _objectIds = objectIds,super._();
  

/// Уникальный идентификатор сотрудника.
@override final  String id;
/// ID компании, к которой принадлежит сотрудник.
@override final  String companyId;
/// URL фотографии сотрудника.
@override final  String? photoUrl;
/// Фамилия.
@override final  String lastName;
/// Имя.
@override final  String firstName;
/// Отчество.
@override final  String? middleName;
/// Дата рождения.
@override final  DateTime? birthDate;
/// Место рождения.
@override final  String? birthPlace;
/// Гражданство.
@override final  String? citizenship;
/// Телефон.
@override final  String? phone;
/// Размер одежды.
@override final  String? clothingSize;
/// Размер обуви.
@override final  String? shoeSize;
/// Рост.
@override final  String? height;
/// Дата приёма на работу.
@override final  DateTime? employmentDate;
/// Тип занятости ([EmploymentType]).
@override@JsonKey() final  EmploymentType employmentType;
/// Должность.
@override final  String? position;
/// Статус сотрудника ([EmployeeStatus]).
@override@JsonKey() final  EmployeeStatus status;
/// Список идентификаторов объектов, к которым привязан сотрудник.
 final  List<String> _objectIds;
/// Список идентификаторов объектов, к которым привязан сотрудник.
@override@JsonKey() List<String> get objectIds {
  if (_objectIds is EqualUnmodifiableListView) return _objectIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_objectIds);
}

/// Серия паспорта.
@override final  String? passportSeries;
/// Номер паспорта.
@override final  String? passportNumber;
/// Кем выдан паспорт.
@override final  String? passportIssuedBy;
/// Дата выдачи паспорта.
@override final  DateTime? passportIssueDate;
/// Код подразделения, выдавшего паспорт.
@override final  String? passportDepartmentCode;
/// Адрес регистрации.
@override final  String? registrationAddress;
/// ИНН.
@override final  String? inn;
/// СНИЛС.
@override final  String? snils;
/// Дата создания записи.
@override final  DateTime? createdAt;
/// Дата последнего обновления записи.
@override final  DateTime? updatedAt;
/// Текущая почасовая ставка сотрудника (из таблицы employee_rates).
@override final  double? currentHourlyRate;

/// Create a copy of Employee
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EmployeeCopyWith<_Employee> get copyWith => __$EmployeeCopyWithImpl<_Employee>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Employee&&(identical(other.id, id) || other.id == id)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.middleName, middleName) || other.middleName == middleName)&&(identical(other.birthDate, birthDate) || other.birthDate == birthDate)&&(identical(other.birthPlace, birthPlace) || other.birthPlace == birthPlace)&&(identical(other.citizenship, citizenship) || other.citizenship == citizenship)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.clothingSize, clothingSize) || other.clothingSize == clothingSize)&&(identical(other.shoeSize, shoeSize) || other.shoeSize == shoeSize)&&(identical(other.height, height) || other.height == height)&&(identical(other.employmentDate, employmentDate) || other.employmentDate == employmentDate)&&(identical(other.employmentType, employmentType) || other.employmentType == employmentType)&&(identical(other.position, position) || other.position == position)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._objectIds, _objectIds)&&(identical(other.passportSeries, passportSeries) || other.passportSeries == passportSeries)&&(identical(other.passportNumber, passportNumber) || other.passportNumber == passportNumber)&&(identical(other.passportIssuedBy, passportIssuedBy) || other.passportIssuedBy == passportIssuedBy)&&(identical(other.passportIssueDate, passportIssueDate) || other.passportIssueDate == passportIssueDate)&&(identical(other.passportDepartmentCode, passportDepartmentCode) || other.passportDepartmentCode == passportDepartmentCode)&&(identical(other.registrationAddress, registrationAddress) || other.registrationAddress == registrationAddress)&&(identical(other.inn, inn) || other.inn == inn)&&(identical(other.snils, snils) || other.snils == snils)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.currentHourlyRate, currentHourlyRate) || other.currentHourlyRate == currentHourlyRate));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,companyId,photoUrl,lastName,firstName,middleName,birthDate,birthPlace,citizenship,phone,clothingSize,shoeSize,height,employmentDate,employmentType,position,status,const DeepCollectionEquality().hash(_objectIds),passportSeries,passportNumber,passportIssuedBy,passportIssueDate,passportDepartmentCode,registrationAddress,inn,snils,createdAt,updatedAt,currentHourlyRate]);

@override
String toString() {
  return 'Employee(id: $id, companyId: $companyId, photoUrl: $photoUrl, lastName: $lastName, firstName: $firstName, middleName: $middleName, birthDate: $birthDate, birthPlace: $birthPlace, citizenship: $citizenship, phone: $phone, clothingSize: $clothingSize, shoeSize: $shoeSize, height: $height, employmentDate: $employmentDate, employmentType: $employmentType, position: $position, status: $status, objectIds: $objectIds, passportSeries: $passportSeries, passportNumber: $passportNumber, passportIssuedBy: $passportIssuedBy, passportIssueDate: $passportIssueDate, passportDepartmentCode: $passportDepartmentCode, registrationAddress: $registrationAddress, inn: $inn, snils: $snils, createdAt: $createdAt, updatedAt: $updatedAt, currentHourlyRate: $currentHourlyRate)';
}


}

/// @nodoc
abstract mixin class _$EmployeeCopyWith<$Res> implements $EmployeeCopyWith<$Res> {
  factory _$EmployeeCopyWith(_Employee value, $Res Function(_Employee) _then) = __$EmployeeCopyWithImpl;
@override @useResult
$Res call({
 String id, String companyId, String? photoUrl, String lastName, String firstName, String? middleName, DateTime? birthDate, String? birthPlace, String? citizenship, String? phone, String? clothingSize, String? shoeSize, String? height, DateTime? employmentDate, EmploymentType employmentType, String? position, EmployeeStatus status, List<String> objectIds, String? passportSeries, String? passportNumber, String? passportIssuedBy, DateTime? passportIssueDate, String? passportDepartmentCode, String? registrationAddress, String? inn, String? snils, DateTime? createdAt, DateTime? updatedAt, double? currentHourlyRate
});




}
/// @nodoc
class __$EmployeeCopyWithImpl<$Res>
    implements _$EmployeeCopyWith<$Res> {
  __$EmployeeCopyWithImpl(this._self, this._then);

  final _Employee _self;
  final $Res Function(_Employee) _then;

/// Create a copy of Employee
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? companyId = null,Object? photoUrl = freezed,Object? lastName = null,Object? firstName = null,Object? middleName = freezed,Object? birthDate = freezed,Object? birthPlace = freezed,Object? citizenship = freezed,Object? phone = freezed,Object? clothingSize = freezed,Object? shoeSize = freezed,Object? height = freezed,Object? employmentDate = freezed,Object? employmentType = null,Object? position = freezed,Object? status = null,Object? objectIds = null,Object? passportSeries = freezed,Object? passportNumber = freezed,Object? passportIssuedBy = freezed,Object? passportIssueDate = freezed,Object? passportDepartmentCode = freezed,Object? registrationAddress = freezed,Object? inn = freezed,Object? snils = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? currentHourlyRate = freezed,}) {
  return _then(_Employee(
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
