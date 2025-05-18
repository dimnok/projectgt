// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'employee_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EmployeeModel _$EmployeeModelFromJson(Map<String, dynamic> json) =>
    _EmployeeModel(
      id: json['id'] as String,
      photoUrl: json['photo_url'] as String?,
      lastName: json['last_name'] as String,
      firstName: json['first_name'] as String,
      middleName: json['middle_name'] as String?,
      birthDate: json['birth_date'] == null
          ? null
          : DateTime.parse(json['birth_date'] as String),
      birthPlace: json['birth_place'] as String?,
      citizenship: json['citizenship'] as String?,
      phone: json['phone'] as String?,
      clothingSize: json['clothing_size'] as String?,
      shoeSize: json['shoe_size'] as String?,
      height: json['height'] as String?,
      employmentDate: json['employment_date'] == null
          ? null
          : DateTime.parse(json['employment_date'] as String),
      employmentType: $enumDecodeNullable(
              _$EmploymentTypeEnumMap, json['employment_type']) ??
          EmploymentType.official,
      position: json['position'] as String?,
      hourlyRate: (json['hourly_rate'] as num?)?.toDouble(),
      status: $enumDecodeNullable(_$EmployeeStatusEnumMap, json['status']) ??
          EmployeeStatus.working,
      objectIds: (json['object_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      passportSeries: json['passport_series'] as String?,
      passportNumber: json['passport_number'] as String?,
      passportIssuedBy: json['passport_issued_by'] as String?,
      passportIssueDate: json['passport_issue_date'] == null
          ? null
          : DateTime.parse(json['passport_issue_date'] as String),
      passportDepartmentCode: json['passport_department_code'] as String?,
      registrationAddress: json['registration_address'] as String?,
      inn: json['inn'] as String?,
      snils: json['snils'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$EmployeeModelToJson(_EmployeeModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'photo_url': instance.photoUrl,
      'last_name': instance.lastName,
      'first_name': instance.firstName,
      'middle_name': instance.middleName,
      'birth_date': instance.birthDate?.toIso8601String(),
      'birth_place': instance.birthPlace,
      'citizenship': instance.citizenship,
      'phone': instance.phone,
      'clothing_size': instance.clothingSize,
      'shoe_size': instance.shoeSize,
      'height': instance.height,
      'employment_date': instance.employmentDate?.toIso8601String(),
      'employment_type': _$EmploymentTypeEnumMap[instance.employmentType]!,
      'position': instance.position,
      'hourly_rate': instance.hourlyRate,
      'status': _$EmployeeStatusEnumMap[instance.status]!,
      'object_ids': instance.objectIds,
      'passport_series': instance.passportSeries,
      'passport_number': instance.passportNumber,
      'passport_issued_by': instance.passportIssuedBy,
      'passport_issue_date': instance.passportIssueDate?.toIso8601String(),
      'passport_department_code': instance.passportDepartmentCode,
      'registration_address': instance.registrationAddress,
      'inn': instance.inn,
      'snils': instance.snils,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$EmploymentTypeEnumMap = {
  EmploymentType.official: 'official',
  EmploymentType.unofficial: 'unofficial',
};

const _$EmployeeStatusEnumMap = {
  EmployeeStatus.working: 'working',
  EmployeeStatus.vacation: 'vacation',
  EmployeeStatus.sickLeave: 'sickLeave',
  EmployeeStatus.unpaidLeave: 'unpaidLeave',
  EmployeeStatus.fired: 'fired',
};
