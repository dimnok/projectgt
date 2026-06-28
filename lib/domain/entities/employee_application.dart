import 'package:freezed_annotation/freezed_annotation.dart';

part 'employee_application.freezed.dart';

/// Тип заявления сотрудника.
enum EmployeeApplicationType {
  /// Ежегодный оплачиваемый отпуск.
  vacation,

  /// Отпуск без сохранения заработной платы.
  unpaidLeave,

  /// Увольнение по собственному желанию.
  resignation,
}

/// Расширение для сериализации [EmployeeApplicationType] в PostgREST.
extension EmployeeApplicationTypeX on EmployeeApplicationType {
  /// Значение для колонки `application_type` в БД.
  String get dbValue => switch (this) {
        EmployeeApplicationType.vacation => 'vacation',
        EmployeeApplicationType.unpaidLeave => 'unpaid_leave',
        EmployeeApplicationType.resignation => 'resignation',
      };

  /// Человекочитаемое название типа заявления.
  String get title => switch (this) {
        EmployeeApplicationType.vacation => 'Отпуск',
        EmployeeApplicationType.unpaidLeave => 'Отпуск без содержания',
        EmployeeApplicationType.resignation => 'Увольнение',
      };

  /// Парсит значение из БД.
  static EmployeeApplicationType fromDbValue(String value) =>
      switch (value) {
        'vacation' => EmployeeApplicationType.vacation,
        'unpaid_leave' => EmployeeApplicationType.unpaidLeave,
        'resignation' => EmployeeApplicationType.resignation,
        _ => EmployeeApplicationType.vacation,
      };
}

/// Заявление сотрудника с подписанным сканом.
@freezed
abstract class EmployeeApplication with _$EmployeeApplication {
  /// Создаёт сущность заявления.
  const factory EmployeeApplication({
    required String id,
    required String companyId,
    required String employeeId,
    required EmployeeApplicationType applicationType,
    required DateTime startDate,
    DateTime? endDate,
    required int durationDays,
    required String scanName,
    required String scanPath,
    required int scanSize,
    required String scanType,
    required String createdBy,
    String? createdByName,
    required DateTime createdAt,
  }) = _EmployeeApplication;
}
