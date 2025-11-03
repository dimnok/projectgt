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

  // Получаем имена сотрудников
  final employeeState = ref.watch(employeeProvider);
  final employeeNames = <String, String>{};

  for (final employee in employeeState.employees) {
    employeeNames[employee.id] =
        '${employee.lastName} ${employee.firstName} ${employee.middleName ?? ''}'
            .trim();
  }

  // Вызываем экспорт
  await service.exportPayrollToExcel(
    payrolls: payrolls,
    payoutsByEmployee: payoutsByEmployee,
    aggregatedBalance: aggregatedBalance,
    employeeNames: employeeNames,
    year: year,
    month: month,
  );
});
