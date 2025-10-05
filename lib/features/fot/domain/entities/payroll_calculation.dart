import 'package:freezed_annotation/freezed_annotation.dart';

part 'payroll_calculation.freezed.dart';

/// Сущность "Расчет ФОТ" (доменная модель).
///
/// Используется для хранения динамически рассчитанных данных ФОТ на основе табелей,
/// информации о сотрудниках, бонусах и штрафах.
@freezed
abstract class PayrollCalculation with _$PayrollCalculation {
  /// Основной конструктор [PayrollCalculation].
  ///
  /// Создает расчет ФОТ на основе данных из различных таблиц.
  const factory PayrollCalculation({
    /// Идентификатор сотрудника.
    /// Может быть null в исключительных случаях (например, при ошибках данных).
    String? employeeId,

    /// Месяц расчета (первый день месяца).
    required DateTime periodMonth,

    /// Отработанные часы за период.
    required double hoursWorked,

    /// Часовая ставка сотрудника.
    required double hourlyRate,

    /// Базовая сумма (hoursWorked * hourlyRate).
    required double baseSalary,

    /// Сумма премий.
    @Default(0) double bonusesTotal,

    /// Сумма штрафов.
    @Default(0) double penaltiesTotal,

    /// Сумма суточных выплат.
    @Default(0) double businessTripTotal,

    /// К выплате (baseSalary + bonusesTotal + businessTripTotal - penaltiesTotal).
    required double netSalary,
  }) = _PayrollCalculation;

  /// Приватный конструктор для расширения функциональности.
  const PayrollCalculation._();
}
