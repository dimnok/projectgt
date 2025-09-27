import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:projectgt/domain/entities/employee.dart';

part 'employee_model.freezed.dart';
part 'employee_model.g.dart';

/// Модель данных сотрудника для работы с API и хранения в базе.
///
/// Используется для сериализации/десериализации, преобразования в доменную сущность [Employee].
@freezed
abstract class EmployeeModel with _$EmployeeModel {
  /// Конструктор модели сотрудника.
  ///
  /// [id] — идентификатор, [photoUrl] — фото, [lastName]/[firstName]/[middleName] — ФИО,
  /// [birthDate]/[birthPlace] — дата и место рождения, [citizenship] — гражданство,
  /// [phone] — телефон, [clothingSize]/[shoeSize]/[height] — размеры,
  /// [employmentDate]/[employmentType] — дата и тип трудоустройства, [position] — должность,
  /// [hourlyRate] — ставка, [status] — статус, [objectIds] — объекты,
  /// паспортные и налоговые данные, [createdAt]/[updatedAt] — даты создания/обновления.
  @JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
  const factory EmployeeModel({
    required String id,
    @JsonKey(name: 'photo_url') String? photoUrl,
    @JsonKey(name: 'last_name') required String lastName,
    @JsonKey(name: 'first_name') required String firstName,
    @JsonKey(name: 'middle_name') String? middleName,
    @JsonKey(name: 'birth_date') DateTime? birthDate,
    @JsonKey(name: 'birth_place') String? birthPlace,
    String? citizenship,
    String? phone,
    @JsonKey(name: 'clothing_size') String? clothingSize,
    @JsonKey(name: 'shoe_size') String? shoeSize,
    String? height,
    @JsonKey(name: 'employment_date') DateTime? employmentDate,
    @JsonKey(name: 'employment_type')
    @Default(EmploymentType.official)
    EmploymentType employmentType,
    String? position,
    @JsonKey(name: 'hourly_rate') double? hourlyRate,
    @Default(EmployeeStatus.working) EmployeeStatus status,
    @JsonKey(name: 'object_ids') @Default(<String>[]) List<String> objectIds,
    @JsonKey(name: 'passport_series') String? passportSeries,
    @JsonKey(name: 'passport_number') String? passportNumber,
    @JsonKey(name: 'passport_issued_by') String? passportIssuedBy,
    @JsonKey(name: 'passport_issue_date') DateTime? passportIssueDate,
    @JsonKey(name: 'passport_department_code') String? passportDepartmentCode,
    @JsonKey(name: 'registration_address') String? registrationAddress,
    String? inn,
    String? snils,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _EmployeeModel;

  /// Приватный конструктор для поддержки методов расширения.
  const EmployeeModel._();

  /// Создаёт модель из JSON.
  factory EmployeeModel.fromJson(Map<String, dynamic> json) =>
      _$EmployeeModelFromJson(json);

  /// Создаёт модель из доменной сущности [Employee].
  factory EmployeeModel.fromDomain(Employee employee) => EmployeeModel(
        id: employee.id,
        photoUrl: employee.photoUrl,
        lastName: employee.lastName,
        firstName: employee.firstName,
        middleName: employee.middleName,
        birthDate: employee.birthDate,
        birthPlace: employee.birthPlace,
        citizenship: employee.citizenship,
        phone: employee.phone,
        clothingSize: employee.clothingSize,
        shoeSize: employee.shoeSize,
        height: employee.height,
        employmentDate: employee.employmentDate,
        employmentType: employee.employmentType,
        position: employee.position,
        hourlyRate: employee.hourlyRate,
        status: employee.status,
        objectIds: employee.objectIds,
        passportSeries: employee.passportSeries,
        passportNumber: employee.passportNumber,
        passportIssuedBy: employee.passportIssuedBy,
        passportIssueDate: employee.passportIssueDate,
        passportDepartmentCode: employee.passportDepartmentCode,
        registrationAddress: employee.registrationAddress,
        inn: employee.inn,
        snils: employee.snils,
        createdAt: employee.createdAt,
        updatedAt: employee.updatedAt,
      );

  /// Преобразует модель в доменную сущность [Employee].
  Employee toDomain() => Employee(
        id: id,
        photoUrl: photoUrl,
        lastName: lastName,
        firstName: firstName,
        middleName: middleName,
        birthDate: birthDate,
        birthPlace: birthPlace,
        citizenship: citizenship,
        phone: phone,
        clothingSize: clothingSize,
        shoeSize: shoeSize,
        height: height,
        employmentDate: employmentDate,
        employmentType: employmentType,
        position: position,
        hourlyRate: hourlyRate,
        status: status,
        objectIds: objectIds,
        passportSeries: passportSeries,
        passportNumber: passportNumber,
        passportIssuedBy: passportIssuedBy,
        passportIssueDate: passportIssueDate,
        passportDepartmentCode: passportDepartmentCode,
        registrationAddress: registrationAddress,
        inn: inn,
        snils: snils,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
