import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/payroll_calculation.dart';
import '../../../../presentation/state/employee_state.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
import '../providers/payroll_providers.dart';
import '../providers/payroll_filter_providers.dart';
import '../providers/balance_providers.dart';
import 'package:projectgt/core/widgets/gt_month_picker.dart';
import 'package:projectgt/core/widgets/gt_object_picker.dart';
import '../utils/payroll_filter_helpers.dart';
import 'payroll_table_view.dart';
import 'payroll_search_action.dart';

/// Виджет для отображения табличных данных расчётов ФОТ.
///
/// Поддерживает группировку по сотрудникам с детальной стилизацией.
/// Оптимизирован для производительности и соответствует Clean Architecture.
class PayrollTableWidget extends ConsumerWidget {
  /// Список расчётов ФОТ.
  final List<PayrollCalculation> payrolls;

  /// Флаг группировки по сотрудникам.
  final bool isGroupedByEmployee;

  /// Создаёт виджет таблицы для отображения данных ФОТ.
  const PayrollTableWidget({
    super.key,
    required this.payrolls,
    this.isGroupedByEmployee = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Используем текущий месяц и год из фильтра
    final filterState = ref.watch(payrollFilterProvider);
    final monthDate = DateTime(
      filterState.selectedYear,
      filterState.selectedMonth,
    );
    final lastDayOfMonth = DateTime(
      filterState.selectedYear,
      filterState.selectedMonth + 1,
      0,
    );

    // Получаем список сотрудников
    final allEmployees = ref.watch(employeeProvider.select((s) => s.employees));
    final searchQuery = ref.watch(payrollSearchQueryProvider);

    // Фильтруем сотрудников по поисковому запросу
    final employees = filterEmployeesBySearchQuery(allEmployees, searchQuery);

    // Получаем выплаты по сотрудникам (FIFO)
    final payoutsMapAsync = ref.watch(
      payoutsByEmployeeAndMonthFIFOProvider(filterState.selectedYear),
    );
    final payoutsMap = payoutsMapAsync.asData?.value ?? {};
    final currentMonth = filterState.selectedMonth; // int (1-12)

    final payoutsByEmployee = <String, double>{};
    for (final empId in payoutsMap.keys) {
      final payoutsForAllMonths = payoutsMap[empId] ?? {};
      payoutsByEmployee[empId] = payoutsForAllMonths[currentMonth] ?? 0;
    }

    // Получаем агрегированный баланс на конец выбранного месяца
    final aggregatedBalanceAsync = ref.watch(
      employeeBalanceAtDateProvider(lastDayOfMonth),
    );
    final aggregatedBalance = aggregatedBalanceAsync.asData?.value ?? {};

    final isDesktop = ResponsiveUtils.isDesktop(context);
    final isMobile = ResponsiveUtils.isMobile(context);

    if (payrolls.isEmpty && employees.isEmpty) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isMobile) ...[
          Row(
            children: [
              Text(
                'ФОТ ${DateFormat.yMMMM('ru').format(monthDate)}',
                style: theme.textTheme.headlineSmall,
              ),
              if (isDesktop) ...[
                const SizedBox(width: 16),
                GTMonthPicker(
                  selectedDate: monthDate,
                  onPrevious: () {
                    final prev = DateTime(monthDate.year, monthDate.month - 1);
                    ref
                        .read(payrollFilterProvider.notifier)
                        .setYearAndMonth(prev.year, prev.month);
                  },
                  onNext: () {
                    final next = DateTime(monthDate.year, monthDate.month + 1);
                    ref
                        .read(payrollFilterProvider.notifier)
                        .setYearAndMonth(next.year, next.month);
                  },
                  onTap: () => PayrollFilterHelpers.showMonthSelection(
                    context,
                    ref,
                    monthDate,
                  ),
                ),
                const SizedBox(width: 8),
                GTObjectPicker(
                  objectName: PayrollFilterHelpers.getObjectName(
                    ref,
                    filterState.selectedObjectIds,
                  ),
                  onPrevious: () => PayrollFilterHelpers.handleObjectSwitch(
                    ref,
                    filterState.selectedObjectIds,
                    -1,
                  ),
                  onNext: () => PayrollFilterHelpers.handleObjectSwitch(
                    ref,
                    filterState.selectedObjectIds,
                    1,
                  ),
                  onTap: () =>
                      PayrollFilterHelpers.showObjectSelection(context, ref),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
        ],
        Expanded(
          child: PayrollTableView(
            payrolls: payrolls,
            employees: employees,
            payoutsByEmployee: payoutsByEmployee,
            aggregatedBalance: aggregatedBalance,
            isMobile: isMobile,
            isTablet: ResponsiveUtils.isTablet(context),
            isDesktop: isDesktop,
          ),
        ),
      ],
    );
  }
}
