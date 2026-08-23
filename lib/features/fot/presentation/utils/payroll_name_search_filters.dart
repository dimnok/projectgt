import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/presentation/state/employee_state.dart';

import '../../data/models/payroll_payout_model.dart';
import '../../domain/entities/payroll_calculation.dart';
import '../../domain/entities/payroll_transaction.dart';

/// Фильтрует расчёты ФОТ по ФИО сотрудника.
List<PayrollCalculation> filterPayrollsByEmployeeName(
  List<PayrollCalculation> payrolls,
  String query,
  WidgetRef ref,
) {
  final searchQuery = query.trim().toLowerCase();
  final employeeState = ref.watch(employeeProvider);
  final employees = employeeState.employees;

  var filteredPayrolls = payrolls;

  if (searchQuery.isNotEmpty) {
    filteredPayrolls = filteredPayrolls.where((payroll) {
      final employee =
          employees.where((e) => e.id == payroll.employeeId).firstOrNull;

      if (employee == null) return false;

      final fullName = [
        employee.lastName,
        employee.firstName,
        if (employee.middleName != null && employee.middleName!.isNotEmpty)
          employee.middleName,
      ].join(' ').toLowerCase();

      return fullName.contains(searchQuery);
    }).toList();
  }

  return filteredPayrolls;
}

/// Фильтрует транзакции (премии/штрафы) по ФИО.
///
/// Фильтр объектов применяется при загрузке (`bonusesByFilterProvider` /
/// `penaltiesByFilterProvider`), здесь не дублируется.
List<PayrollTransaction> filterTransactionsByEmployeeName(
  List<PayrollTransaction> transactions,
  String query,
  WidgetRef ref,
) {
  final searchQuery = query.trim().toLowerCase();
  final employeeState = ref.watch(employeeProvider);
  final employees = employeeState.employees;

  var filteredTransactions = transactions;

  if (searchQuery.isNotEmpty) {
    filteredTransactions = filteredTransactions.where((transaction) {
      final employee =
          employees.where((e) => e.id == transaction.employeeId).firstOrNull;

      if (employee == null) return false;

      final fullName = [
        employee.lastName,
        employee.firstName,
        if (employee.middleName != null && employee.middleName!.isNotEmpty)
          employee.middleName,
      ].join(' ').toLowerCase();

      return fullName.contains(searchQuery);
    }).toList();
  }

  return filteredTransactions;
}

/// Фильтрует выплаты по ФИО.
List<PayrollPayoutModel> filterPayoutsByEmployeeName(
  List<PayrollPayoutModel> payouts,
  String query,
  WidgetRef ref,
) {
  final searchQuery = query.trim().toLowerCase();
  final employeeState = ref.watch(employeeProvider);
  final employees = employeeState.employees;

  var filteredPayouts = payouts;

  if (searchQuery.isNotEmpty) {
    filteredPayouts = filteredPayouts.where((payout) {
      final employee =
          employees.where((e) => e.id == payout.employeeId).firstOrNull;

      if (employee == null) return false;

      final fullName = [
        employee.lastName,
        employee.firstName,
        if (employee.middleName != null && employee.middleName!.isNotEmpty)
          employee.middleName,
      ].join(' ').toLowerCase();

      return fullName.contains(searchQuery);
    }).toList();
  }

  return filteredPayouts;
}

/// Фильтрует список сотрудников по поисковому запросу.
List<dynamic> filterEmployeesBySearchQuery(
  List<dynamic> employees,
  String query,
) {
  final searchQuery = query.trim().toLowerCase();
  if (searchQuery.isEmpty) return employees;

  return employees.where((employee) {
    final fullName = [
      employee.lastName,
      employee.firstName,
      if (employee.middleName != null && employee.middleName!.isNotEmpty)
        employee.middleName,
    ].join(' ').toLowerCase();

    return fullName.contains(searchQuery);
  }).toList();
}
