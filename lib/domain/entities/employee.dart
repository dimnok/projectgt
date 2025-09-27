import 'package:freezed_annotation/freezed_annotation.dart';

part 'employee.freezed.dart';

/// Тип занятости сотрудника.
///
/// Используется для различения официального и неофициального трудоустройства.
enum EmploymentType {
  /// Официальное трудоустройство (с записью в трудовой книжке).
  official, // Официально
  /// Неофициальное трудоустройство.
  unofficial, // Неофициально
}

/// Статус сотрудника в компании.
///
/// Используется для отображения текущего состояния сотрудника (работает, в отпуске и т.д.).
enum EmployeeStatus {
  /// Сотрудник работает.
  working, // Работает
  /// Сотрудник в отпуске.
  vacation, // Отпуск
  /// Сотрудник на больничном.
  sickLeave, // Больничный
  /// Сотрудник в отпуске без сохранения зарплаты.
  unpaidLeave, // Без содержания
  /// Сотрудник уволен.
  fired, // Уволен
}

/// Сущность "Сотрудник" (доменная модель).
///
/// Описывает основные данные сотрудника, включая ФИО, контакты, паспортные данные, статус и тип занятости.
/// Используется во всех слоях приложения для передачи информации о сотрудниках.
///
/// Пример создания:
/// ```dart
/// final employee = Employee(
///   id: 'emp1',
///   lastName: 'Иванов',
///   firstName: 'Иван',
///   employmentType: EmploymentType.official,
///   status: EmployeeStatus.working,
/// );
/// ```
@freezed
abstract class Employee with _$Employee {
  /// Основной конструктор [Employee].
  ///
  /// Все параметры соответствуют полям сотрудника в базе данных.
  const factory Employee({
    /// Уникальный идентификатор сотрудника.
    required String id,

    /// URL фотографии сотрудника.
    String? photoUrl,

    /// Фамилия.
    required String lastName,

    /// Имя.
    required String firstName,

    /// Отчество.
    String? middleName,

    /// Дата рождения.
    DateTime? birthDate,

    /// Место рождения.
    String? birthPlace,

    /// Гражданство.
    String? citizenship,

    /// Телефон.
    String? phone,

    /// Размер одежды.
    String? clothingSize,

    /// Размер обуви.
    String? shoeSize,

    /// Рост.
    String? height,

    /// Дата приёма на работу.
    DateTime? employmentDate,

    /// Тип занятости ([EmploymentType]).
    @Default(EmploymentType.official) EmploymentType employmentType,

    /// Должность.
    String? position,

    /// Почасовая ставка.
    double? hourlyRate,

    /// Статус сотрудника ([EmployeeStatus]).
    @Default(EmployeeStatus.working) EmployeeStatus status,

    /// Список идентификаторов объектов, к которым привязан сотрудник.
    @Default(<String>[]) List<String> objectIds,

    /// Серия паспорта.
    String? passportSeries,

    /// Номер паспорта.
    String? passportNumber,

    /// Кем выдан паспорт.
    String? passportIssuedBy,

    /// Дата выдачи паспорта.
    DateTime? passportIssueDate,

    /// Код подразделения, выдавшего паспорт.
    String? passportDepartmentCode,

    /// Адрес регистрации.
    String? registrationAddress,

    /// ИНН.
    String? inn,

    /// СНИЛС.
    String? snils,

    /// Дата создания записи.
    DateTime? createdAt,

    /// Дата последнего обновления записи.
    DateTime? updatedAt,
  }) = _Employee;

  /// Приватный конструктор для расширения функциональности через методы.
  const Employee._();
}
