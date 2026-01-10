import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/payroll_excel_service.dart';
import '../../domain/entities/payroll_calculation.dart';
import '../../../../presentation/state/employee_state.dart';

/// Провайдер сервиса экспорта ФОТ
final payrollExcelServiceProvider = Provider((ref) {
  return PayrollExcelService();
});

/// Функция для экспорта ФОТ в Excel
final exportPayrollToExcelProvider =
    FutureProvider.family<void, Map<String, dynamic>>((ref, params) async {
  final service = ref.watch(payrollExcelServiceProvider);

  // Распаковываем параметры
  final payrolls = params['payrolls'] as List<PayrollCalculation>;
  final payoutsByEmployee = params['payoutsByEmployee'] as Map<String, double>;
  final aggregatedBalance = params['aggregatedBalance'] as Map<String, double>;
  final year = params['year'] as int;
  final month = params['month'] as int;

  // 1. Получаем имена сотрудников
  final employeeState = ref.watch(employeeProvider);
  final employeeNames = <String, String>{};

  for (final employee in employeeState.employees) {
    employeeNames[employee.id] =
        '${employee.lastName} ${employee.firstName} ${employee.middleName ?? ''}'
            .trim();
  }

  // 2. Дополняем список начислений сотрудниками с ненулевым балансом
  final Set<String> existingEmployeeIds =
      payrolls.map((p) => p.employeeId).whereType<String>().toSet();

  final List<PayrollCalculation> augmentedPayrolls = List.from(payrolls);
  final periodDate = DateTime(year, month);

  aggregatedBalance.forEach((employeeId, balance) {
    // Если баланс не нулевой и сотрудника еще нет в списке начислений этого месяца
    if (balance.abs() > 0.01 && !existingEmployeeIds.contains(employeeId)) {
      augmentedPayrolls.add(
        PayrollCalculation(
          employeeId: employeeId,
          periodMonth: periodDate,
          hoursWorked: 0,
          hourlyRate: 0,
          baseSalary: 0,
          netSalary: 0,
        ),
      );
    }
  });

  // 3. Сортируем по имени сотрудника (как в UI таблице)
  augmentedPayrolls.sort((a, b) {
    final nameA = employeeNames[a.employeeId] ?? '';
    final nameB = employeeNames[b.employeeId] ?? '';
    return nameA.compareTo(nameB);
  });

  // Вызываем экспорт
  await service.exportPayrollToExcel(
    payrolls: augmentedPayrolls,
    payoutsByEmployee: payoutsByEmployee,
    aggregatedBalance: aggregatedBalance,
    employeeNames: employeeNames,
    year: year,
    month: month,
  );
});
