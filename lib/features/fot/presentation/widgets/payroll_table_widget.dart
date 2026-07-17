import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/payroll_calculation.dart';
import '../../../../presentation/state/employee_state.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import '../providers/payroll_providers.dart';
import '../providers/payroll_filter_providers.dart';
import 'payroll_employee_status_filter_segment.dart';
import '../utils/payroll_name_search_filters.dart';
import 'payroll_table_view.dart';

/// Виджет для отображения табличных данных расчётов ФОТ.
class PayrollTableWidget extends ConsumerWidget {
  /// Список расчётов ФОТ.
  final List<PayrollCalculation> payrolls;

  /// Идёт фоновый пересчёт начислений за месяц (RPC).
  final bool isPayrollsRefreshing;

  /// Создаёт виджет таблицы для отображения данных ФОТ.
  const PayrollTableWidget({
    super.key,
    required this.payrolls,
    this.isPayrollsRefreshing = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final filterState = ref.watch(payrollFilterProvider);
    final allEmployees = ref.watch(employeeProvider.select((s) => s.employees));
    final searchQuery = ref.watch(payrollSearchQueryProvider);
    final statusFilter = ref.watch(payrollEmployeeStatusFilterProvider);

    final employeesBySearch = filterEmployeesBySearchQuery(
      allEmployees,
      searchQuery,
    );
    final employees = filterEmployeesByPayrollStatus(
      employeesBySearch,
      statusFilter,
    );
    final filteredPayrolls = filterPayrollsByEmployeeStatus(
      payrolls,
      employeesBySearch,
      statusFilter,
    );

    final fifoDataAsync = ref.watch(
      payoutsByEmployeeAndMonthFIFOProvider(filterState.selectedYear),
    );

    final fifoData = fifoDataAsync.valueOrNull ?? {};
    final isFifoRefreshing = fifoDataAsync.isLoading;
    final isSettlementRefreshing = isFifoRefreshing || isPayrollsRefreshing;

    final currentMonth = filterState.selectedMonth;

    final payoutsByEmployee = <String, double>{};
    final aggregatedBalance = <String, double>{};

    for (final empId in fifoData.keys) {
      final employeeFIFO = fifoData[empId]!;
      payoutsByEmployee[empId] = employeeFIFO.payouts[currentMonth] ?? 0;
      aggregatedBalance[empId] = employeeFIFO.balances[currentMonth] ?? 0;
    }

    final isDesktop = ResponsiveUtils.isDesktop(context);
    final isMobile = ResponsiveUtils.isMobile(context);

    if (filteredPayrolls.isEmpty && employees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_late_outlined,
              size: 64,
              color: theme.colorScheme.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Нет данных для отображения',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                searchQuery.isNotEmpty
                    ? 'По запросу "$searchQuery" ничего не найдено. Попробуйте изменить фильтры или выбрать другой период.'
                    : statusFilter == PayrollEmployeeStatusFilter.fired
                    ? 'Нет уволенных сотрудников за выбранный период и фильтры.'
                    : statusFilter == PayrollEmployeeStatusFilter.working
                    ? 'Нет работающих сотрудников за выбранный период и фильтры.'
                    : 'За выбранный период записей не найдено. Попробуйте выбрать другой месяц или добавить новую операцию.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return PayrollTableView(
      payrolls: filteredPayrolls,
      employees: employees,
      payoutsByEmployee: payoutsByEmployee,
      aggregatedBalance: aggregatedBalance,
      isMobile: isMobile,
      isTablet: ResponsiveUtils.isTablet(context),
      isDesktop: isDesktop,
      isPayrollsRefreshing: isPayrollsRefreshing,
      isSettlementRefreshing: isSettlementRefreshing,
    );
  }
}
