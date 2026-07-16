import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/payroll_providers.dart';
import '../../../../presentation/state/employee_state.dart';
import 'payroll_payout_table_view.dart';
import '../utils/payroll_name_search_filters.dart';
import '../providers/payroll_filter_providers.dart';

/// Таблица всех выплат по ФОТ.
class PayrollPayoutTableWidget extends ConsumerWidget {
  /// Конструктор [PayrollPayoutTableWidget].
  const PayrollPayoutTableWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final employeeState = ref.watch(employeeProvider);
    final payoutsAsync = ref.watch(filteredPayrollPayoutsProvider);
    final searchQuery = ref.watch(payrollSearchQueryProvider);
    final filterState = ref.watch(payrollFilterProvider);

    final selectedDate =
        DateTime(filterState.selectedYear, filterState.selectedMonth);
    final now = DateTime.now();
    final isPeriodFiltered = filterState.selectedYear != now.year ||
        filterState.selectedMonth != now.month;

    return payoutsAsync.when(
      data: (allPayouts) {
        final payouts = filterPayoutsByEmployeeName(
          allPayouts,
          searchQuery,
          ref,
        );
        if (payouts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.payment_outlined,
                  size: 64,
                  color: theme.colorScheme.outline.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  isPeriodFiltered
                      ? 'Нет выплат за ${DateFormat.yMMMM('ru').format(selectedDate)}'
                      : 'Нет выплат',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'За выбранный период записей не найдено. Попробуйте выбрать другой месяц или добавьте новую операцию.',
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

        return PayrollPayoutTableView(
          payouts: payouts,
          employees: employeeState.employees,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(
        child: Text('Ошибка загрузки выплат: $e'),
      ),
    );
  }
}
