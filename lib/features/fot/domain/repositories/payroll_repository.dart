import '../entities/payroll_calculation.dart';

/// Интерфейс репозитория для работы с расчетами ФОТ.
///
/// Предоставляет методы для динамического расчета ФОТ на основе
/// существующих данных из таблиц табеля, сотрудников и других.
abstract class PayrollRepository {
  /// Получает динамически рассчитанные данные ФОТ за указанный месяц.
  ///
  /// [month] - первый день месяца, для которого нужно выполнить расчет.
  Future<List<PayrollCalculation>> getPayrollsByMonth(DateTime month);
  
  /// Получает данные о премиях сотрудника за указанный месяц.
  ///
  /// [employeeId] - идентификатор сотрудника
  /// [month] - первый день месяца
  Future<double> getEmployeeBonusesForMonth(String employeeId, DateTime month);
  
  /// Получает данные о штрафах сотрудника за указанный месяц.
  ///
  /// [employeeId] - идентификатор сотрудника
  /// [month] - первый день месяца
  Future<double> getEmployeePenaltiesForMonth(String employeeId, DateTime month);
  
  /// Получает данные об удержаниях сотрудника за указанный месяц.
  ///
  /// [employeeId] - идентификатор сотрудника
  /// [month] - первый день месяца
  Future<double> getEmployeeDeductionsForMonth(String employeeId, DateTime month);
} 